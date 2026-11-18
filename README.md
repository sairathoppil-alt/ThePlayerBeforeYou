# THE PLAYER BEFORE YOU

An asynchronous cooperative game about two players in different timelines working together to prevent a disaster. The first scenario is **Disaster Management: Flood Prevention**: one player prepares a town in 2026, while another investigates its future in 2046.

## Technology

- Godot 4 (Compatibility renderer)
- GDScript
- Procedural low-poly 3D assets
- Local JSON-based data storage

## Run the game

1. Install Godot 4.
2. Open `project.godot` from this folder in the Godot Project Manager (or import this folder).
3. Run the project with **F6** for the current scene or **F5** for the main menu.

## Past Timeline controls

- **WASD** or **arrow keys** to move.
- **Mouse** to orbit the third-person camera while captured.
- **Tab** to release or recapture the mouse for HUD controls.
- **E** to inspect a nearby structure.
- **Escape** to open or close the pause menu.

Inspect the Dam, Bridge, Drainage System, Emergency Shelter Site, and Warning Tower Site. Confirm improvements to spend resource points; selected improvements can be undone from the structure panel or decision summary. Submitting decisions saves the past timeline and opens the 2046 placeholder.

Progress is stored as JSON at `user://game_state.json`. Beginning a new mission asks before replacing an existing save.

## Project status

Stage 1 menus remain available. Stage 2 adds an approximately 100-by-100-unit procedural riverside town, third-person exploration, five resource-funded improvements, and save-backed decision submission. The 2046 screen is a placeholder; future investigation and online multiplayer are not implemented.
