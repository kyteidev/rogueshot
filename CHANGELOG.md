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
