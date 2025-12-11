# **WoWBnB** 
*a simple addon to create shareable links to your house both in-game and out!*
**NEW UI!** - whare expanded the initial idea and the addon now lets you neatly organize and save your favorite houses by neighborhoods!.

--- 
## Commands:
`/wowbnbc`:
- Opens a interface to save your favorite plots
- Members of same neighborhoods are grouped and collapseable
**KNOWN ISSUE:** Currently, Import/Export is not working as intended.

`/wowbnb`:
- Copy to clipboard displayed in a small text-box highlighted and ready to copy.
- encodes as a raw macro string so sharing does NOT require addon for visitors.
- alias `/wbnb`

![/wowbnb Example - displays addon menu appearing in game.](https://media.forgecdn.net/attachments/1419/701/wowbnb-ingame-png.png)

## Known Bugs:
- Import/Export not working as intended.
- teleporting to some plots (mostly public plots) seems to yeild 'Permission Denied'
- Please report any issues on Github or [Curse](https://www.curseforge.com/wow/addons/wowbnb)

## Share House Example:
- *player logs into account and goes to a plot that they own.*
- In chat type the slash command: `/wowbnb`
- *Notice the popup in center of screen with a formatted /run macro highlighted*
- Press Control+C (Copy) and the window closes. **note** Clicking the small [x] in the corner or [Okay] button
- Paste the macro to a friend, reddit, discord etc.. since we use native UI api __when sharing with others, they will **NOT** need to have the addon installed.__
