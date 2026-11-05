local addonName = ...
local startupError
SLASH_CLASSICSWINGTIMER1="/cst"
SLASH_CLASSICSWINGTIMER2="/classicswingtimer"
SlashCmdList.CLASSICSWINGTIMER=function()
 print("Classic Swing Timer could not finish loading: "..tostring(startupError or "startup incomplete"))
end
local function Initialize()
ClassicSwingTimerDB=ClassicSwingTimerDB or {}
local db, preview, melee, ranged = ClassicSwingTimerDB, false, false, false
local defaults = {width=240,height=22,icon=28,gap=6,font=12,scale=1,locked=true,x=0,y=-160}
for k,v in pairs(defaults) do if db[k]==nil then db[k]=v end end
local SwingLib = LibStub and LibStub("LibClassicSwingTimerAPI", true)
assert(SwingLib, "Bundled swing timer library did not load. Reinstall the complete addon folder.")
local handIndex={mainhand=1,offhand=2,ranged=3}
local rangedUntil=0
local root = CreateFrame("Frame", "ClassicSwingTimerFrame", UIParent)
root:SetMovable(true); root:SetClampedToScreen(true); root:RegisterForDrag("LeftButton")
root:SetScript("OnDragStart", function(self) if not db.locked then self:StartMoving() end end)
root:SetScript("OnDragStop", function(self)
 self:StopMovingOrSizing()
 local x,y = self:GetCenter(); local ux,uy = UIParent:GetCenter()
 local ratio=self:GetEffectiveScale()/UIParent:GetEffectiveScale()
 db.x=x*ratio-ux; db.y=y*ratio-uy
 self:ClearAllPoints(); self:SetPoint("CENTER",UIParent,"CENTER",db.x,db.y)
end)
local bars = {}
for i,label in ipairs({"Main hand","Off hand","Ranged"}) do
 local b=CreateFrame("StatusBar",nil,root)
 b:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
 b:SetStatusBarColor(.72,.72,.72,1); b:SetMinMaxValues(0,1)
 b.bg=b:CreateTexture(nil,"BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetColorTexture(.08,.08,.08,.9)
 b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetTexCoord(.07,.93,.07,.93)
 b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b.label:SetPoint("LEFT",6,0); b.label:SetText(label)
 b.time=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b.time:SetPoint("RIGHT",-5,0)
 b.duration=1; b.finish=0; b.slot=({16,17,18})[i]
 bars[i]=b
end
local function RefreshEquipment()
 local itemInfo=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
 for i,b in ipairs(bars) do
  b.equipped=GetInventoryItemTexture("player",b.slot)~=nil
  if i==2 then
   local itemID=GetInventoryItemID("player",b.slot)
   local classID
   if itemID and itemInfo then
    local _,_,_,_,_,itemClassID=itemInfo(itemID)
    classID=itemClassID
   end
   b.equipped=b.equipped and classID==2
  end
  b.icon:SetTexture(GetInventoryItemTexture("player",b.slot) or "Interface\\Icons\\INV_Misc_QuestionMark")
 end
end
local function SyncFromLibrary()
 if not SwingLib.player then return end
 for hand,index in pairs(handIndex) do
  local speed,expiration=SwingLib:SwingTimerInfo(hand)
  bars[index].duration=speed and speed>0 and speed or 1
  bars[index].finish=expiration or 0
  bars[index].pausedLeft=nil
 end
end
local function Layout()
 if not db then return end
 root:SetScale(db.scale); root:SetSize(db.width+db.icon+5,3*(math.max(db.height,db.icon)+db.gap))
 root:ClearAllPoints(); root:SetPoint("CENTER",UIParent,"CENTER",db.x,db.y)
 root:EnableMouse(not db.locked)
 local row=0
 for i,b in ipairs(bars) do
  local visible=preview or (b.equipped and ((i<3 and melee) or (i==3 and ranged)))
  b:SetShown(visible and true or false)
  b:ClearAllPoints(); b:SetPoint("TOPLEFT",root,"TOPLEFT",db.icon+5,-row*(math.max(db.height,db.icon)+db.gap))
  b:SetSize(db.width,db.height)
  b.icon:ClearAllPoints(); b.icon:SetPoint("RIGHT",b,"LEFT",-5,0); b.icon:SetSize(db.icon,db.icon)
  b.label:SetFont(STANDARD_TEXT_FONT,db.font,"OUTLINE"); b.time:SetFont(STANDARD_TEXT_FONT,db.font,"OUTLINE")
  if visible then row=row+1 end
 end
end
local function UpdateMode()
 local player=SwingLib.player
 if not player then return end
 local dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
 local shooting=not dead and (player.isShooting or GetTime()<rangedUntil)
 local attacking=not dead and player.isAttacking and not shooting
 shooting=shooting and true or false; attacking=attacking and true or false
 if melee~=attacking or ranged~=shooting then melee=attacking; ranged=shooting; Layout() end
end
local function SwingEvent(event,unit,...)
 if unit~="player" then return end
 if event=="UNIT_SWING_TIMER_INFO_INITIALIZED" then SyncFromLibrary(); RefreshEquipment(); UpdateMode(); Layout(); return end
 if event=="UNIT_SWING_TIMER_START" or event=="UNIT_SWING_TIMER_UPDATE" then
  local speed,expiration,hand,reason=...
  local index=handIndex[hand]; if not index then return end
  local b=bars[index]; b.duration=math.max(speed or 0,.001); b.finish=expiration or GetTime(); b.pausedLeft=nil
  if index==3 and reason=="swing" and not (SwingLib.player and SwingLib.player.isShooting) then rangedUntil=b.finish end
 elseif event=="UNIT_SWING_TIMER_PAUSED" then
  local hand=...; local index=handIndex[hand]
  if index then bars[index].pausedLeft=math.max(0,bars[index].finish-GetTime()) end
 elseif event=="UNIT_SWING_TIMER_STOP" then
  local hand=...; local index=handIndex[hand]
  if index then bars[index].finish=GetTime(); bars[index].pausedLeft=nil end
 end
 UpdateMode()
end
for _,event in ipairs({"UNIT_SWING_TIMER_INFO_INITIALIZED","UNIT_SWING_TIMER_START","UNIT_SWING_TIMER_UPDATE","UNIT_SWING_TIMER_PAUSED","UNIT_SWING_TIMER_STOP"}) do
 SwingLib.RegisterCallback(root,event,SwingEvent)
end
root:SetScript("OnUpdate",function()
 UpdateMode()
 local now=GetTime()
 for i,b in ipairs(bars) do
  if b:IsShown() then
   local duration=preview and ({2.6,1.8,2.9})[i] or b.duration
   local left
   if preview then left=duration-now%duration
   else left=b.pausedLeft or math.max(0,b.finish-now) end
   b:SetValue(1-math.min(1,left/duration))
   b.time:SetText(not preview and b.pausedLeft and "Paused" or (left>0 and string.format("%.1f",left) or "Ready"))
  end
 end
end)
local panel
local function OpenSettings()
 if panel then panel:SetShown(not panel:IsShown()); return end
 panel=CreateFrame("Frame","ClassicSwingTimerSettings",UIParent,"BackdropTemplate")
 panel:SetSize(380,480); panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG")
 panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
 panel:EnableMouse(true); panel:SetMovable(true); panel:RegisterForDrag("LeftButton")
 panel:SetScript("OnDragStart",panel.StartMoving); panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
 local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOP",0,-22); title:SetText("Classic Swing Timer")
 local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5)
 local specs={{"Bar width","width",100,500,1},{"Bar height","height",10,50,1},{"Weapon icon size","icon",14,64,1},{"Bar spacing","gap",0,24,1},{"Text size","font",8,24,1},{"Overall scale","scale",.5,2,.05}}
 for i,s in ipairs(specs) do
  local slider=CreateFrame("Slider","ClassicSwingTimerSlider"..i,panel,nil)
  slider:SetPoint("TOP",0,-65-(i-1)*51); slider:SetWidth(285); slider:SetMinMaxValues(s[3],s[4]); slider:SetValueStep(s[5]); slider:SetObeyStepOnDrag(true)
  slider:SetOrientation("HORIZONTAL")
  local background=slider:CreateTexture(nil,"BACKGROUND"); background:SetAllPoints(); background:SetColorTexture(.15,.15,.15,1)
  slider:SetHeight(14); slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  local caption=slider:CreateFontString(nil,"OVERLAY","GameFontNormal"); caption:SetPoint("BOTTOM",slider,"TOP",0,4)
  local low=slider:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); low:SetPoint("TOPLEFT",slider,"BOTTOMLEFT",0,-2); low:SetText(s[3])
  local high=slider:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); high:SetPoint("TOPRIGHT",slider,"BOTTOMRIGHT",0,-2); high:SetText(s[4])
  slider:SetScript("OnValueChanged",function(self,value)
   value=math.floor(value/s[5]+.5)*s[5]; db[s[2]]=value
   caption:SetText(s[1]..": "..(s[2]=="scale" and string.format("%.2f",value) or string.format("%d",value)))
   Layout()
  end)
  slider:SetValue(db[s[2]])
 end
 local function Button(text,x,action)
  local b=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); b:SetSize(150,26); b:SetPoint("BOTTOMLEFT",x,35); b:SetText(text); b:SetScript("OnClick",action); return b
 end
 Button("Toggle preview",30,function() preview=not preview; Layout() end)
 local lock
 lock=Button(db.locked and "Unlock frame" or "Lock frame",200,function()
  db.locked=not db.locked; lock:SetText(db.locked and "Unlock frame" or "Lock frame"); preview=not db.locked or preview; Layout()
 end)
 local note=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); note:SetPoint("BOTTOM",0,17); note:SetText("Unlock and enable preview to drag the bars.")
end
local eventFrame=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_EQUIPMENT_CHANGED","PLAYER_ENTER_COMBAT","PLAYER_LEAVE_COMBAT","START_AUTOREPEAT_SPELL","STOP_AUTOREPEAT_SPELL","PLAYER_DEAD"}) do eventFrame:RegisterEvent(event) end
eventFrame:SetScript("OnEvent",function(self,event,...)
 if event=="ADDON_LOADED" then
  if ...~=addonName then return end
  RefreshEquipment(); SyncFromLibrary(); Layout()
  print("|cffccccccClassic Swing Timer 0.2.1 loaded:|r /cst settings, /cst test (LibClassicSwingTimerAPI)")
 elseif event=="PLAYER_ENTERING_WORLD" then
  rangedUntil=0; RefreshEquipment(); SyncFromLibrary(); UpdateMode(); Layout()
 elseif event=="PLAYER_EQUIPMENT_CHANGED" then
  RefreshEquipment(); Layout()
 elseif event=="STOP_AUTOREPEAT_SPELL" or event=="PLAYER_DEAD" then
  rangedUntil=0; UpdateMode()
 else UpdateMode() end
end)
SLASH_CLASSICSWINGTIMER1="/cst"
SLASH_CLASSICSWINGTIMER2="/classicswingtimer"
SlashCmdList.CLASSICSWINGTIMER=function(msg)
 msg=string.lower(strtrim(msg or ""))
 if msg=="debug" then
 print("Classic Swing Timer 0.2.1; engine LibClassicSwingTimerAPI; preview="..tostring(preview))
 for hand,index in pairs(handIndex) do
  local b=bars[index]
  print(hand..": speed="..string.format("%.3f",b.duration).." remaining="..string.format("%.3f",b.pausedLeft or math.max(0,b.finish-GetTime())))
 end
 elseif msg=="test" then preview=not preview; Layout()
 elseif msg=="lock" then db.locked=not db.locked; Layout(); print("Classic Swing Timer: frame "..(db.locked and "locked" or "unlocked. Use /cst test to show it."))
 elseif msg=="reset" then for k,v in pairs(defaults) do db[k]=v end; if panel then panel:Hide(); panel=nil end; Layout()
 else OpenSettings() end
end

end
local ok,err=xpcall(Initialize,function(message) return tostring(message) end)
if not ok then
 startupError=err
 print("|cffff5555Classic Swing Timer startup error:|r "..tostring(err))
end
