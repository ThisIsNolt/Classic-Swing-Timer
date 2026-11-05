Classic Swing Timer 0.2.1 - WoW Classic Era and WoW: Forever

INSTALL
Close WoW. Replace your existing ClassicSwingTimer addon folder with the folder in this archive.
Keep the complete Libs subfolder. No separate library addon or WeakAuras installation is required.
Classic Era installation: World of Warcraft\_classic_era_\Interface\AddOns\ClassicSwingTimer\ClassicSwingTimer.toc
Forever installation: copy the same ClassicSwingTimer folder into the Forever client installation's Interface\AddOns directory.
Enable the addon on character selection. If necessary, enable Load out of date AddOns.
Existing saved size and position settings are preserved.

COMMANDS
/cst - Settings
/cst test - Toggle animated preview (turn OFF for real timing tests)
/cst lock - Toggle frame dragging
/cst reset - Restore default layout
/cst debug - Print engine and current timer values
/classicswingtimer - Alternate settings command

TIMING CHANGES
The previous custom combat-log engine has been removed.
Bars now consume LibClassicSwingTimerAPI start, update, pause and stop events.
The library reconstructs independent main hand, off hand and ranged swing times, with Classic Era spell handling, haste rescaling, defensive parry haste, first off hand swing handling and ranged movement corrections.
Weapon textures, neutral gray bars, configuration sliders and automatic hiding remain.
A full bar marked Ready means the predicted swing time has elapsed. The attack can still be delayed by facing, distance or other game conditions.

TEST IN GAME
1. Confirm the chat message says Classic Swing Timer 0.2.1 loaded.
2. Leave preview OFF. Attack with ordinary auto attacks and compare bar resets with your attacks.
3. Compare with Heroic Strike/Cleave, and with haste buffs applied or removed.
4. Stop attacking: melee bars hide. Auto Shot/wand Shoot shows the ranged bar; stopping it hides the bar.
5. Use /cst to confirm saved appearance and position.
If an error appears, run /console scriptErrors 1, then /reload, and capture the error.
For timing reports, include your class, weapons, abilities used and /cst debug output.

VALIDATION
All bundled Lua sources pass Lua 5.1 syntax parsing.
Simulated integration tests ran the actual LibStub, CallbackHandler and swing library with mocked WoW APIs.
Passing cases: startup, font initialization, settings, sliders, preview, independent MH/OH, misses, haste rescaling, defensive parry haste, Heroic Strike, Classic Era Slam, Auto Shot, wand shots, ranged movement correction, pause/resume rendering, weapon visibility, death and reset.
Actual game-client verification has NOT been performed. Simulated tests validate integration, not every server timing mechanic.

LICENSE
Classic Swing Timer is distributed under GNU GPL v3; see LICENSE.txt.
Bundled swing library source and license are included.
See THIRD-PARTY.txt and Libs/ACE3-LICENSE.txt for dependency sources and notices.

DUAL CLIENT RELEASE 0.2.1
Forever interface: 16001. Shared package with Classic Era.
Off hand detection uses item class instead of combat-restricted attack speed.
Simulated tests pass in both client modes; native Forever main hand, off hand and ranged events were tested with secret weapon-speed values. Live in-game timing still requires testing.
