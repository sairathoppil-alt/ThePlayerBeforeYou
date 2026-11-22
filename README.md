# THE PLAYER BEFORE YOU

THE PLAYER BEFORE YOU is a cooperative 3D adventure about two players exploring the same town in different timelines. One player investigates Willowbrook in 2026; the other explores the flooded consequences in 2046. Players communicate, share discoveries and change persistent world conditions.

## Technology

- Godot 4 Standard, GDScript and the Compatibility renderer
- Procedural low-poly 3D environment and characters
- Local JSON persistence
- A direct-IP ENet foundation for two-player LAN tests

## Run the game

1. Open this folder's `project.godot` in Godot 4.
2. Press **F5** to launch the main menu.
3. Choose **Local Demonstration** to explore and switch between timelines, or use **Play with a Friend** to create/join a direct-IP LAN room.

The current room implementation uses UDP port **24680**. Both players need network reachability to the host; Internet matchmaking, NAT traversal and backend authentication are not included.

## Gameplay controls

- **WASD / arrow keys:** Move
- **Mouse:** Rotate the third-person camera
- **Space:** Jump
- **Shift:** Sprint
- **E:** Interact with nearby objects
- **1–6:** Equip an inventory slot
- **Q:** Drop the selected item
- **Tab:** Inventory
- **M:** Town map and location markers
- **J:** Investigation journal
- **C:** Echo Link chat
- **T:** Toggle Time Echo when a live or previously recorded partner echo is available
- **V:** Toggle Temporal Vision
- **F:** Toggle the future player's Temporal Flashlight
- **F4:** Switch local timelines in Local Demonstration
- **Escape:** Close a popup or open the pause menu

Movement and camera input are disabled while a popup is open. Communication does not consume temporal energy.

## Temporal systems

- **Time Echo** is a procedural wrist-mounted device. It reveals a real synchronized partner during a LAN session or explicitly identified, previously recorded partner movement while offline. It does not create an autonomous companion.
- **Temporal Vision** uses a second Camera3D and SubViewport to render the alternate timeline through an animated circular observation window. It does not transport either player.
- **Echo Link** provides communication independently of temporal energy.
- The default shared energy settings are 100 maximum, 10 minimum activation, Time Echo at 2 units/second for up to 20 seconds, Temporal Vision at 3 units/second for up to 15 seconds, and recharge at 2 units/second after a 10-second delay. Values are configurable in the `TemporalEnergy` autoload.

## Saves and legacy prototype

The cooperative adventure uses `user://adventure_state.json`. The original resource-preparation prototype retains its separate `user://game_state.json` save and scenes; its legacy systems have not been migrated into the adventure save.

## Prototype status

The current project includes playable procedural 2026 and flooded 2046 environments, local timeline switching, inventory/interactions, persistence, popup communication, temporal ability foundations and direct-IP ENet code. **Two-client networking and GUI behavior still require manual verification**; this prototype does not yet provide Internet matchmaking or an authenticated authoritative backend. Shared item ownership and the complete puzzle/mission chain are also outstanding.

Run headless validation with:

```powershell
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 180
```

See `DEVELOPMENT_PLAN.md` for current validation status and remaining work, and `references/GAME_DESIGN.md` for the full design specification.
