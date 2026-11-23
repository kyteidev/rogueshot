v0.1.0-dev.7:
- added recoil system
- added item slot preview when dragging inventory item
- added reactive crosshair
- added first shot spread multiplier
- added walking spread multiplier
- added durability stats to tooltip
- added durability bar to inventory item
- added a global rng manager for possible set seed saves
- added fast reloading
- added durability to magazines
- added ability to aim down sights
- added a red dot to reticle when ADS
- added a separate max spread for ADS
- added ADS movement speed multiplier
- added setting for ADS keybind
- added setting to disable particles
- added effective and maximum range for weapons
- added indicators for when aiming out of effective or maximum range
- added player status label that shows when magazine is broken
- added save and load for settings
- added apply button to options menu
- added basic sfx
- added enemy reload animations
- added audio settings
- added damage vignette
- added ability to replace equipped item by dragging another compatible item on top
- added 5.56 ammo texture
- added new 9x19mm ammo texture
- added foundations for weapon attachments
- added basic suppressor (NOT FUNCTIONAL, JUST AN ITEM)
- added ability to equip attachments (CANNOT UNEQUIP ATTACHMENTS YET)
- added a more legible font for tooltip description
- added modify button to context menu to open weapon info panel
- added foundations for weapon info panel (CANNOT HIDE WEAPON INFO PANEL WHEN OPENED, HAS TO RESTART GAME TO HIDE IT)
- fixed walk particles disappearing abruptly
- fixed crash when showing magazine type tooltip
- fixed crash when player dies the same frame a shot is fired
- fixed player status label sometimes not showing
- fixed inventory item icon size incorrect after rotation
- fixed mag count incorrect after dropping or picking up magazine
- fixed item stacking when unloading from container item
- fixed weapon jam chance calculations
- fixed inventory not properly reset in reset inventory function
- fixed player status label having incorrect position set
- fixed item durability going below zero
- fixed enemy dropping empty ammo item when out of ammo
- fixed unload animation playing when no mag is attached
- fixed item sometimes not being able to be dropped
- fixed being able to drag inventory item when inventory is hidden
- fixed crash when switching away weapon on last frame of reload
- fixed internal mag_attached state not applied immediately after reload
- fixed weapon magazine reloading system having inconsistent state across different methods of reloading
- made weapon apply spread on first shot
- made player status label hide after cancelling a reload
- made reticle hide while in inventory or pause menu
- made mag loading times shorter
- made enemy magazine drops randomize durability
- made magazine durability affect weapon jamming
- made player speed less when moving backwards
- made split button in context menu disabled when there is only one item in stack
- made durability wear be affected by weapon heat
- made weapon barrel glow red proportional to its heat
- made weapon heat affect weapon jam chance
- made broken mags prevent shooting
- made walk particles change color based on ground color
- made enemy weapon use real weapon stats
- made weapon shoot and eject correct ammo type
- made 9x19mm ammo icon smaller
- made damage round to one decimal place accuracy
- removed max weapon heat cap
- tweaked walk particle amounts
- tweaked walk particle gravity
- tweaked tooltip description font and font size
- tweaked GL18 and OZ-2 weapon spread and heating rate


v0.1.0-dev.6:
Reloading has been fixed!!!!!
- added magazine-based reloading :D (huge feature!!!!!)
- added item stack splitting
- added 5.56 caliber ammo
- added item loading and unloading delay to container items
- added ability to combine item stacks
- added weapon loaded and unloaded textures
- added item descriptions
- added weapon names
- added item weight
- added overweight status effect
- added magazine reload animation
- added item durability
- added weapon jamming and unjamming
- added walk particles
- added player status label
- fixed container item overflow
- fixed item being stuck in drag state when moving cursor very fast
- fixed crash when using context menu without hovering over item
- fixed item ghosting when unloading from container
- fixed crash when unloading empty container
- fixed being able to pick up item while in inventory
- fixed enemy not dealing correct damage
- fixed inventory overflow stuff
- fixed enemy status icon and label clipping
- fixed being able to drag item to container when it's full
- fixed inventory not reset when reloading game scene
- made inventory item dragging better
- made item go to existing stack when unloaded
- made player weapon and world item weapon show/hide mag when necessary
- made debug labels hidden
- made enemy drop weapon with correct properties

v0.1.0-dev.5:
Reloading is still broken :(
- added item equipping using context menus
- added item name, count, container items count labels to inventory items
- added 9x19 bullet, pistol magazine, rifle magazine items
- added wall to make it harder for player to fall out of map
- added container items (items that can hold other items, like guns can hold magazines, etc.)
- added tooltips
- fixed weapon cycling keybind
- fixed equipped item having stale state when dropped directly from equipment slot
- fixed items being incorrectly highlighted when dragging other items
- fixed player falling forever when falling out of map
- made ammo and magazine counter on HUD reflect inventory


v0.1.0-dev.4:
I broke reloading and the cycle weapon keybind when I switched to the inventory based weapons system :( will be fixed next update
- added pickable items
- added a context menu for the inventory
- added ability to drop items from inventory
- added ability to equip items in inventory (currently primary and secondary weapons)
- fixed player able to rotate item when hovered but not dragged
- fixed the buggy inventory item dragging system
- fixed player able to equip same weapon repeatedly
- made enemies drop their weapon on death
- made player inventory reset after death


v0.1.0-dev.3:
- added outline to weapon display
- added partial damage (crosshair over enemy for full damage)
- added bullet impact particles
- added heart icon to health bar
- added weapon muzzle flash and sparks
- added icons to ammo and mag display
- added a "facing lock" system (if moving direction != facing direction, press key to turn towards moving direction)
- added enemy status text
- added basic inventory system (drag and drop, rotation works. equipping still not implemented)
- added items (that can be picked up in the future, still not implemented)
- added options menu (working but incomplete)
- fixed bullet casing always having same rotation
- made player point towards movement direction instead of cursor
- made sprinting require looking in same direction as movement
- made player stamina bar fade when player dies
- made equipped weapons on HUD show keybind correctly instead of a static 1 and 2
- tweaked health bar label
- removed extra keybinds, might be added back later


v0.1.0-dev.2:
- added proper reload
- added weapon-specific reload times
- added sprinting
- added health
- added stamina
- added smooth camera movement
- added enemies
- added camera shake
- added bullet casing ejection
- added muzzle smoke
- added custom reticle
- added basic death screen
- added equipped weapon display
- fixed numerous bugs
- made player movement better


v0.1.0-dev.1:
- release!
