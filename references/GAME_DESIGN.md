# THE PLAYER BEFORE YOU — DEFINITIVE GAME DEVELOPMENT SPECIFICATION

Act as a senior Godot 4 game developer, creative director, 3D environmental artist, multiplayer engineer, puzzle designer and game UX designer.

PROJECT:
C:\Projects\ThePlayerBeforeYou

VISUAL REFERENCE:
references/game_reference.png

Inspect the existing project and study the reference image before making changes.

Transform the existing game into a premium Roblox-inspired standalone 3D cooperative time-travel adventure.

The existing implementation looks like a technical prototype. The finished experience must feel like an actual professionally designed adventure game.

Do not create another project. Reuse existing working systems wherever appropriate.

# 1. GAME IDENTITY

Title: THE PLAYER BEFORE YOU

Tagline: Your past. Their future. One shared fate.

Chapter 1: The Flood That Never Happened.

Location: Willowbrook.

Genre: Third-person cooperative 3D adventure, mystery, environmental puzzles and time manipulation.

Two real players explore the same town in different timelines:

- Player 1: 2026 — The Past.
- Player 2: 2046 — The Future.

The past player changes history.

The future player investigates consequences.

Both players must contribute meaningfully to solving environmental puzzles.

The game supports simultaneous multiplayer and asynchronous cooperation.

The environment itself becomes a communication tool.

# 2. VISUAL QUALITY REQUIREMENTS

Use the supplied reference image as the primary art direction.

Do not use the reference image as a static background or fake gameplay screenshot.

Recreate its visual characteristics using actual explorable 3D geometry, materials, textures, lighting and animations.

Avoid:

- Primitive-looking buildings.
- Fluorescent green terrain.
- Empty flat environments.
- Basic mannequin characters.
- Oversized dashboard interfaces.
- Generic rectangular interaction panels.
- Repetitive scenery.

Create:

- Detailed stylized architecture.
- Natural terrain.
- Attractive characters.
- Consistent character proportions and clean, cohesive materials.
- Rich environmental detail.
- Professionally balanced lighting.
- Smooth animations.
- Atmospheric environments.
- Premium adventure-game interfaces.

Favor a polished, stylized Roblox-inspired adventure look. Avoid photorealistic AI-generated aesthetics, excessive neon, cyberpunk dashboards, excessive bloom, oversized futuristic borders and inconsistent asset styles.

Use original or properly licensed game-ready assets where beneficial.

Suitable asset sources include Kenney, Quaternius, Poly Haven and ambientCG.

Record asset attribution and licensing.

Do not rely exclusively on primitive cubes and spheres when suitable detailed assets are available.

# 3. WILLOWBROOK WORLD DESIGN

Create one cohesive, explorable mountain town.

Include:

- Town square with a fountain and clock tower.
- Detailed cottages and shops.
- Maintenance workshop.
- Town archives.
- Construction site.
- A monumental explorable dam.
- Flowing river.
- Bridges.
- Electrical control station.
- Maintenance facility.
- Underground drainage tunnels.
- Hidden rooms.
- Abandoned buildings.
- Elevated platforms.
- Mountainous surroundings.
- Forest areas.
- Construction storage yards.
- Collectible tools and audio-recording equipment placed at appropriate locations throughout Willowbrook.
- Accessible interiors.

Use naturally connected roads, stone pathways, stairs, slopes, retaining walls and riverbanks.

Create clear landmarks and navigational routes.

Buildings should have detailed roofs, window frames, wooden beams, doors, chimneys, foundations and exterior lighting.

Add benches, fences, streetlights, signs, crates, pipes, construction materials, rocks and vegetation.

Reuse modular scenes to maintain consistency and performance.

# 4. TWO DISTINCT TIMELINES

2026 — THE PAST:

Create a warm, peaceful and lively Willowbrook.

Include golden sunlight, colorful houses, natural vegetation, clear flowing water, flower beds, clouds, ambient NPCs, working machinery and construction activity.

2046 — THE FUTURE:

Create the exact same geographical town after a catastrophic flood.

Include damaged architecture, flooded streets, abandoned vehicles, overgrown vegetation, broken machinery, cracked roads, dark skies, rain, mist and localized lighting.

Do not create an unrelated second map.

Give corresponding locations and objects stable shared identifiers.

When the past player changes history, dynamically update the corresponding future object or location.

# 5. CHARACTERS AND CAMERA

Create premium stylized adventure characters inspired by the reference image.

Include recognizable facial features, styled hair, detailed jackets, trousers, boots, backpacks and visible equipped tools.

Past character: warm orange, brown or red clothing.

Future character: cool blue, charcoal or navy clothing.

Implement smooth animations for idle, walking, running, jumping, landing, collecting items, carrying objects, operating machinery and using tools.

Implement a smooth third-person camera with:

- Spring-arm collisions.
- Mouse-controlled rotation.
- Adjustable sensitivity.
- Camera smoothing.
- Configurable distance.
- Stable field of view.
- Slight downward viewing angle.

Match the third-person composition shown in the reference.

# 6. PLAYER CONTROLS

WASD or arrows: Movement.

Mouse: Camera rotation.

Space: Jump.

Shift: Sprint.

E: Interact.

1–6: Select an inventory slot without requiring a permanently visible hotbar.

Q: Drop the selected item.

Tab: Open the six-slot inventory popup.

M: Open the map popup.

J: Open the investigation and mission journal.

C: Open the Echo Link communication popup.

T: Activate or deactivate Time Echo.

V: Activate Temporal Vision.

F: Activate the temporal flashlight for the future player.

R: Rewind eligible recent actions for the past player.

Escape: Close the current popup, or open the pause menu when no popup is open.

Automatically release the mouse cursor when an interface opens and recapture it when the interface closes.

Prevent accidental movement, item use and camera rotation while navigating popups or interacting with machinery and drawing surfaces.

Provide a respawn option for stuck players.

# 7. REMOVE RESOURCE MANAGEMENT

Remove abstract resource points, purchase buttons and spending-based repairs from active adventure gameplay.

Replace them with:

- Physical exploration.
- Tool collection.
- Object manipulation.
- Machinery operation.
- Environmental puzzles.
- Construction.
- Investigation.
- Communication.
- NPC interactions.

Preserve previous save files safely without silently overwriting them.

# 8. INVENTORY AND PHYSICAL INTERACTIONS

Create a six-slot popup inventory. Number keys 1–6 may select slots without a permanently visible hotbar.

Include usable items such as:

- Wrench.
- Shovel.
- Hammer.
- Screwdriver.
- Maintenance key.
- Mechanical components.
- Electrical cables.
- Wooden planks.
- Metal supports.
- Time capsule.
- Historical documents.
- Flashlight.
- Camera.
- Audio recorder.

Implement picking up, equipping, dropping, carrying, placing and using items.

Large construction objects may use a separate carrying system.

Give every persistent item a unique identifier.

Prevent item duplication.

Implement context-sensitive interactions with proximity checks and raycasts.

Show subtle object highlights and small contextual prompts.

Do not use large repair menus for ordinary physical interactions.

Keep the inventory hidden during ordinary exploration and briefly notify the player when the selected item changes.

# 9. SIGNATURE MECHANIC — TEMPORAL VISION

Time Echo, Temporal Vision and Echo Link are distinct but complementary systems:

- Time Echo reveals the partner's character.
- Temporal Vision reveals the alternate environment.
- Echo Link provides communication.

Both players can access Time Echo and Temporal Vision.

Pressing V activates Temporal Vision.

Create an immersive, animated circular observation window that reveals the corresponding location in the other timeline. It is an observation device, not a teleportation portal; both players remain in their respective timelines.

For example:

A player standing in flooded Willowbrook in 2046 activates Temporal Vision and sees peaceful Willowbrook in 2026 through a glowing circular window.

The surroundings outside the lens remain in the current timeline.

Use the supplied temporal portal reference as visual inspiration, adapted to the game's premium stylized Roblox-inspired art direction rather than photorealism.

The window should include:

- Rotating concentric metallic rings with engraved temporal symbols.
- Glowing cyan energy and subtle swirling particles.
- Smooth materialization and disappearance.
- Correct world-coordinate alignment and camera perspective.
- Actual alternate-timeline 3D rendering inside the circular opening.

Implement:

- Actual alternate-timeline 3D rendering.
- Smooth activation and deactivation.
- Circular perspective-mapped opening.
- Lens distortion where supported.
- Animated transitions.
- Accurate matching of world coordinates.
- Corresponding camera position and orientation.

Use SubViewport rendering and a secondary Camera3D with appropriate timeline scene isolation and perspective mapping, or another technically suitable approach.

Prevent duplicate physics, input processing and audio from the secondary scene.

Use reduced viewport resolution when needed for performance.

The lens must reveal the actual alternate environment, not a predefined image.

Players should be able to:

- Observe corresponding structures.
- Identify missing objects.
- See changed infrastructure.
- Point at objects.
- Send location markers.
- Discover historical clues.

If the partner is online, display their synchronized avatar or temporal representation inside the alternate timeline.

If the partner is offline, clearly indicate that any displayed partner location is last known.

Temporal Vision should remain useful offline by rendering saved alternate-timeline state.

## SHARED TEMPORAL ENERGY

Each player's temporal device has a shared energy pool used by that player's Time Echo and Temporal Vision abilities.

- Maximum capacity: 100 units.
- Minimum energy to activate either ability: 10 units.
- Time Echo: maximum 20 seconds per activation, consuming 2 units per second.
- Temporal Vision: maximum 15 seconds per activation, consuming 3 units per second.
- Recharge rate: 2 units per second.
- Recharge delay: 10 seconds after both abilities are inactive.

Allow early manual deactivation. Automatically deactivate an ability when its duration limit expires or the shared energy is depleted. If both abilities are active at once, consume energy at the combined rate. Make all values configurable.

Recharge without spending resources. Keep communication and essential clues available without consuming temporal energy. Never let an essential puzzle become permanently blocked because energy is depleted.

Show a small circular energy indicator and remaining activation time only while a temporal ability is active. Hide the indicator during ordinary exploration.

When the past player changes an object, the future player should observe its transformation.

Do not pretend that a static overlay is a working Temporal Vision system.


# 10. TIME ECHO — ACTIVATABLE CROSS-TIMELINE PROJECTION

Implement Time Echo as an equippable temporal device that reveals a temporary, ghost-like projection of the actual other player in the opposite timeline.

Time Echo is NOT:
- A physical tent, research headquarters or stationary communication station.
- A floating orb.
- An autonomous companion or pet.
- An NPC or artificial assistant.
- A source of fabricated partner movements.

It is a projection of the other player's character, allowing both players to experience each other's presence despite being separated by twenty years. The projection is visible only while Time Echo is active and must never follow the local player automatically.

Both players can activate Time Echo with T. Its maximum activation duration, energy consumption, shared pool, recharge delay and minimum activation energy are defined in Section 9. Allow manual deactivation and prevent energy use when neither a live partner nor a recorded historical echo is available.

## A. VISUAL APPEARANCE

Design the equippable device as an ancient circular mechanical artifact with concentric metallic rings, engraved details and a glowing temporal core. On activation, illuminate the core, animate the rings, play a subtle temporal sound and show a subtle ripple.

Create a reusable EchoAvatar 3D scene using the actual partner's character model.

The projection must include:

- A recognizable humanoid silhouette.
- Translucent character materials.
- Soft glowing outlines.
- Subtle temporal particles.
- Smooth fading effects.
- A lightweight spectral movement trail.
- Recognizable clothing, hair and character accessories.

2026 VERSION:

The past player sees a cyan-blue ghost-like projection of the future player.

2046 VERSION:

The future player sees a warm golden-orange ghost-like projection of the past player.

Gradually reveal the projection during activation and fade it during deactivation. During deactivation, dim the device and begin the shared recharge delay. Clearly distinguish a live partner from a recorded historical echo.

Maintain the premium Roblox-inspired character aesthetic.

Avoid excessive neon effects that obstruct the environment.

## B. REAL PLAYER MOVEMENT

The Echo Avatar must represent the actual partner's position and movements.

Synchronize:

- World position.
- Character rotation.
- Walking.
- Running.
- Jumping.
- Crouching, if supported.
- Equipped tools.
- Object interactions.
- Pointing and waving gestures.

When the partner moves in their timeline, their projected character moves through the corresponding geographical coordinates in the local timeline.

Show the projection only while Time Echo is active. The projection must not automatically follow the local player.

Use network interpolation to make movement smooth and natural.

Disable physical collisions between players from different timelines so they can pass through each other.

If the partner enters a location that does not exist or is inaccessible in the local timeline, allow their projection to pass through the corresponding geometry while using subtle fading effects.

## C. INTERACTIVE COOPERATION

Allow both players to cooperate naturally through their Echo Avatars.

Players should be able to:

- Point toward important objects.
- Wave to attract attention.
- Indicate hidden entrances.
- Demonstrate machinery interactions.
- Show construction locations.
- Guide their partner through unfamiliar areas.
- Communicate using short speech bubbles.
- Mark objects and locations.

For example, the future player stands beside a destroyed machine and points toward its missing component.

The past player sees the future player's Echo Avatar pointing toward the corresponding functional machine in 2026.

This allows players to communicate through physical positioning rather than relying entirely on menus.

## D. ECHO COMMUNICATION

Press C to open a compact Echo Link popup.

Provide:

- Two-way text chat.
- Quick messages.
- Objective requests.
- Shared clues.
- Location markers.
- Partner connection status.
- Persistent message history.

Quick messages should include:

- Follow me.
- Look at this.
- I found something.
- Move this object.
- Check this location.
- I need your help.
- Try again.
- Puzzle solved.

Incoming messages may briefly appear above the partner's Echo Avatar as small speech bubbles.

All communication interfaces must close when the player returns to normal exploration.

## E. SHARED INVESTIGATION JOURNAL

Replace the previously planned physical investigation board with an accessible popup journal.

Display:

- Discovered clues.
- Historical photographs.
- Documents.
- Completed investigations.
- Unlocked missions.
- Partner contributions.
- Requested environmental changes.

Allow players to select a clue and share it directly with their partner.

Preserve all journal information between sessions.

## F. TEMPORAL MAP

Implement a functional popup map accessible using M.

Show:

- Willowbrook's geographical layout.
- The local player's position.
- The partner's position.
- Important landmarks.
- Mission locations.
- Shared markers.
- Requested construction locations.
- Discovered temporal anomalies.

Allow players to place markers and annotate corresponding locations across timelines.

Clearly distinguish live partner positions from last-known positions.

## G. BLUEPRINT SHARING

Allow the future player to create and send construction requests through Echo Link.

Provide a compact blueprint editor supporting:

- Construction location selection.
- Snap-point placement.
- Required components.
- Platform and staircase layouts.
- Orientation markers.
- Preview of the requested structure.

The past player receives the blueprint and can view a translucent construction outline directly in the 3D environment.

The partner's Echo Avatar can physically point toward the required construction location.

The past player must collect and assemble actual materials rather than pressing a build confirmation button.

## H. PHOTOGRAPH SHARING

Allow players to discover, inspect and share historical photographs through the investigation journal.

Historical photographs must dynamically update according to relevant past environmental changes.

Provide a before-and-after comparison popup.

The future player can share a photograph with the past player and mark specific objects that need to be moved or modified.

## I. AUDIO MESSAGES

Allow players to create, preserve and retrieve musical sequences or audio messages through designated recording equipment.

Shared recordings can be accessed through Echo Link or the investigation journal.

Support:

- Musical puzzle sequences.
- Playback controls.
- Persistent recording history.
- Short voice messages if microphone permissions and recording infrastructure are available.

Never simulate a recorded voice message and present it as actual player audio.

## J. EQUIPMENT AND INVENTORY

Remove the previously planned centralized equipment station.

Players must physically discover tools and equipment throughout Willowbrook.

Press Tab to open a compact inventory popup.

Allow players to equip tools, inspect items and access unlocked temporal devices.

The partner's Echo Avatar should visibly display their currently equipped tool where practical.

Keep the inventory hidden during ordinary exploration.

Briefly display the selected item when the player changes inventory slots.

## K. MISSION TRACKING

Provide a compact mission journal containing:

- Current objectives.
- Partner objectives.
- Completed tasks.
- Required cooperation.
- Discovered evidence.
- Overall chapter progress.

Do not permanently display a large mission dashboard.

Show brief objective notifications when progress changes.

## L. TEMPORAL VISION INTEGRATION

Echo Avatar and Temporal Vision must work together but remain distinct mechanics.

Echo Avatar reveals the partner's character within the local timeline.

Temporal Vision reveals the partner's actual surrounding environment.

Press V to activate a circular temporal lens.

The lens must display the corresponding alternate-timeline environment through actual secondary 3D rendering.

Players can observe their partner moving inside the alternate world, identify environmental differences and watch historical changes occur.

Outside the lens, the local timeline remains visible.

Do not use static images or prerecorded footage to simulate this feature.

## M. ASYNCHRONOUS PLAYER ECHOES

When the partner is offline, preserve significant actions from their previous session.

Record selected interaction events and short movement sequences associated with important discoveries or changes.

Examples:

- The past player moving construction equipment.
- The future player discovering a hidden entrance.
- A player inspecting a damaged machine.
- A player pointing toward an important valve.
- A player completing a construction request.

Allow the returning player to activate and replay these recorded Echo Avatars.

The replay should show the partner's stored movements and actions at the corresponding location.

Clearly label recorded projections as historical echoes rather than live players.

Do not generate fake partner movements or pretend an offline player is connected.

Recorded echoes must not modify the world or repeat completed gameplay actions.

## N. TEMPORAL CHANGE FEEDBACK

When the past player performs an action that changes the future, display:

- A brief temporal ripple.
- Subtle glowing particles.
- Smooth environmental transformation.
- A small notification.
- Appropriate temporal sound effects.

For example:

- A blocked wall disappears.
- A staircase becomes accessible.
- Water drains from a tunnel.
- Electricity returns to a building.
- A historical photograph changes.

Allow the future player to observe these transformations while standing in the affected location.

## O. INTRODUCTORY TUTORIAL — ECHO AWAKENING

Teach Time Echo and Temporal Vision through an interactive introduction in Willowbrook.

Both players begin at corresponding locations in their respective timelines.

Teach players how to:

1. Move and control the camera.
2. Activate Time Echo with T and observe the partner's EchoAvatar.
3. Wave and point at objects.
4. Send an Echo Link message.
5. Activate Temporal Vision with V and inspect the corresponding environment.
6. Place a shared location marker.
7. Perform a small environmental interaction.
8. Observe its consequence in the other timeline.

For asynchronous sessions, use a clearly labeled recorded tutorial echo when a live partner is unavailable.

## P. CLEAN GAMEPLAY PRESENTATION

During ordinary exploration, the screen must primarily display:

- The 3D town.
- The player's character.
- The partner's Echo Avatar when available.
- Minimal contextual interaction prompts.

Allow only a subtle timeline indicator and temporary objective or selected-item notifications beyond these elements.

Do not permanently display inventory hotbars, minimaps, large mission trackers, communication panels, resource points, control guides or excessive icons.

Inventory, maps, investigation journals, communication, blueprints and mission details must appear as temporary popups when requested.

Avoid permanent hotbars, oversized HUD panels, futuristic dashboards and excessive icons.

Show temporal energy and remaining activation time only while Time Echo or Temporal Vision is active. Hide the circular energy indicator while both are inactive.

Release the mouse cursor while a popup is open, recapture it when the popup closes and suppress movement, item-use and camera inputs while navigating the interface.

The game must feel like a premium Roblox-style cooperative adventure.

## Q. TECHNICAL REQUIREMENTS

Use Godot 4 and GDScript.

Implement:

- Reusable EchoAvatar scene.
- Time Echo activation and shared temporal-energy integration.
- Partner presence manager.
- Network movement synchronization.
- Animation synchronization.
- Movement interpolation.
- Shared world coordinate mapping.
- Gesture and interaction synchronization.
- Persistent communication.
- Recorded interaction history.
- Historical echo playback.
- Connection and disconnection handling.

Maintain Compatibility renderer support.

Keep ghost rendering lightweight.

Do not run duplicate gameplay physics or input processing on projected characters.

Separate temporary movement synchronization from persistent gameplay events.

Validate player identities and room membership.

Do not report multiplayer synchronization as complete without testing separate client sessions.

## FINAL REQUIREMENT

Time Echo must make players feel like they are exploring Willowbrook together, even though they exist twenty years apart.

It must represent the real partner's presence, movements and contributions.

Do not construct a physical Time Echo location, research headquarters, stationary communication station or floating companion creature.

Preserve communication and investigation functionality through Echo Link, popup interfaces, physical exploration and shared investigation systems.

All implemented features must be functional. Clearly disable unfinished features rather than simulating their functionality.

# 11. THE PHOTOGRAPH THAT CHANGES

Implement a dynamic historical photograph puzzle.

The future player discovers a photograph of construction workers near the dam.

The photograph contains environmental objects that conceal important information.

The past player visits the original location and physically rearranges designated objects.

For example:

- Move a crate.
- Reposition construction equipment.
- Change a wooden barrier.
- Reveal a maintenance sign.

When the past player's actions change the scene, update the historical photograph in 2046.

Generate photographs using an actual in-game camera capture from a fixed historical viewpoint.

Store photograph metadata and the relevant environmental state.

Render updated photographs based on actual persistent object changes.

Do not use unrelated predefined images pretending to update.

The modified photograph reveals a clue, access code or hidden entrance.

Make before-and-after comparisons available as a popup from the investigation journal.

# 12. THE TOWN THAT REMEMBERS

Create a small set of interactive NPCs in 2026.

Include:

- Shopkeeper.
- Construction worker.
- Dam engineer.
- Archivist.

Implement short branching dialogue interactions.

NPC decisions must produce real persistent consequences.

Example:

The past player convinces a shopkeeper to relocate important supplies to higher ground.

The future player discovers the preserved shop or supply storage instead of a destroyed location.

Implement selected dialogue outcomes as explicit world-state events.

Create at least one complete NPC-based cooperative puzzle.

Do not populate the world with meaningless decorative dialogue only.

# 13. REVERSE ENGINEERING

Create two corresponding machines.

The machine in 2026 is complete and functional.

The machine in 2046 is damaged and has missing components.

The future player examines surviving components.

The past player investigates the original machine.

Both players compare:

- Component placement.
- Mechanical configurations.
- Labels.
- Wire colors.
- Valve positions.
- Operating sequences.

Allow players to share observations using Echo Link and Temporal Vision.

The future player must reconstruct or restore the machine using correctly identified components.

Require meaningful information from both timelines.

Use simplified fictional machinery rather than complex real engineering.

# 14. THE DISAPPEARING ROOM

Create a building that is under construction in 2026.

In 2046, a hidden room is inaccessible because a wall blocks its entrance.

The future player discovers evidence of the hidden room.

The past player examines the original construction layout.

Allow the past player to physically move designated wall modules, alter a doorway or modify the construction plan.

The corresponding future wall layout must update.

The future player can then physically enter the newly accessible room.

Update actual geometry and collision shapes.

Ensure geometry changes cannot trap the player.

The hidden room contains a meaningful puzzle component, code or historical record.

# 15. WATER-LEVEL PUZZLES

Create an explorable underground drainage network.

The past player operates water gates and control valves.

The future player explores flooded tunnels.

Assign separate controllable water levels to designated tunnel sections.

When the past player changes valve configurations:

- Adjust corresponding future water levels.
- Reveal submerged pathways.
- Expose hidden objects.
- Open access to machinery.
- Block or unblock selected routes.

Animate water movement smoothly.

Use a deterministic puzzle-state system for the water simulation.

A realistic computational fluid simulation is not required.

The future player must communicate which routes are flooded and guide the past player toward the correct configuration.

Include safe navigation, reversible mistakes and protection against trapping players.

# 16. MESSAGES THROUGH SOUND

Create a functional recording station.

Place actual audio-recording equipment and collectible tools at appropriate locations throughout Willowbrook.

Allow the past player to create a musical sequence using interactable buttons, bells or notes.

Persist the exact sequence.

The future player can retrieve and replay it using the corresponding historical recording machine.

Use musical sequences for passwords or puzzle combinations.

If microphone recording is supported and permission is explicitly granted, additionally support short recorded voice messages.

Voice recordings require appropriate storage, size limits, playback controls and clear user consent.

If microphone recording cannot be completed, provide the functional musical-sequence system instead.

Do not present simulated voice messages as actual recorded audio.

# 17. BLUEPRINT BUILDING

Replace the sapling and tree-growth puzzle with a physical construction system.

The future player discovers an inaccessible rooftop, collapsed staircase or unreachable control platform.

The future player creates and sends a blueprint request through Echo Link.

The request specifies the required construction location and arrangement.

The past player obtains construction materials such as:

- Wooden planks.
- Support beams.
- Metal brackets.
- Ladders.
- Platform sections.

Allow the past player to physically carry and place materials.

Use snap points, placement previews and orientation controls.

Validate the construction using predefined structural requirements.

Do not implement advanced structural engineering simulation.

When the structure is completed correctly, create its aged but functional counterpart in 2046.

The future player must physically use the resulting staircase, platform or pathway.

Incorrect configurations should be reversible.

Persist all placed construction components.

Include visible construction progress and satisfying placement feedback.

# 18. ELECTRICITY PUZZLE

Create an electrical distribution facility.

The future player discovers emergency lights flashing in a specific pattern.

The pattern reveals the proper connection order or electrical configuration.

The past player accesses a functioning electrical panel.

Allow interaction with:

- Cable connections.
- Switches.
- Circuit modules.
- Power-routing controls.

Create a simple visual connection puzzle with clearly distinguishable inputs and outputs.

When the correct configuration is completed:

- Restore electricity in the corresponding future building.
- Activate lights.
- Unlock doors.
- Enable machinery.
- Reveal previously inaccessible clues.

Use fictional safe puzzle logic rather than real electrical instructions.

# 19. BUTTERFLY EFFECT SYSTEM

Create a collection of meaningful persistent environmental consequences.

Examples:

Move a large rock in 2026:
Change a designated future water pathway.

Preserve an old newspaper:
Reveal historical evidence in 2046.

Redirect a road:
Create a future evacuation or exploration route.

Install a streetlight:
Illuminate a hidden future entrance.

Close an unsafe tunnel:
Prevent a future collapse.

Implement these as explicit cause-and-effect relationships.

Each event must have:

- Stable event ID.
- Required conditions.
- Past action.
- Future consequence.
- Visual update.
- Persistent state.
- Optional mission relevance.
- Rewind eligibility.

Include optional discoveries that reward experimentation without making the main objectives unnecessarily confusing.

# 20. TEMPORAL FLASHLIGHT

Give the future player a special temporal flashlight.

Unlike Temporal Vision, which reveals a broader alternate world, the flashlight reveals historical information on a selected object.

Press F to activate it.

When shining the flashlight at a designated damaged object:

- Reveal its original appearance.
- Highlight missing components.
- Display historical markings.
- Reveal hidden clues.
- Show original construction outlines.

Use mesh overlays, material masks or alternate-state rendering.

Examples:

A broken machine temporarily displays its complete original components.

A ruined wall reveals an older doorway.

A damaged sign reveals its original writing.

The flashlight must uncover actual puzzle information.

Do not implement it as an ordinary cosmetic light only.

# 21. TIMELINE REWIND

Allow the past player to reverse selected recent environmental actions.

Examples:

- Undo a gate configuration.
- Reverse a recent object placement.
- Restore a wall module.
- Reposition an incorrectly placed construction component.

Use an event history with validated reversible actions.

Rewind must update the future timeline consistently.

Prevent item duplication, invalid mission states and repeated rewards.

Do not rewind ordinary player chat, irreversible story events or actions with unsafe dependencies.

If a future player has already used an affected structure, validate whether reversal is safe.

Explain why an action cannot be rewound when necessary.

Use a brief temporal rewind animation and sound.

# 22. WET CEMENT WRITING

Preserve the original functional cement-message mechanic.

Allow the past player to draw freely on designated wet cement surfaces.

Provide clear, undo, finish and cancel controls.

Save normalized stroke coordinates.

Render the exact same strokes on the aged future surface.

Do not substitute predefined text.

Allow players to preserve passwords, diagrams, arrows or personal messages.

# 23. TIME CAPSULES

Preserve the original time capsule mechanic.

The past player places a unique item or message inside a waterproof capsule and buries it at a valid location.

The future player discovers the location, retrieves the capsule and collects its contents.

Persist item ownership, capsule position, contents and retrieval state.

Prevent duplicated items or repeated retrieval.

Integrate capsules into the missing-component mission.

# 24. ECHO LINK

Give both players a portable communication device.

Implement:

- Two-way text chat.
- Quick messages.
- Location markers.
- Objective requests.
- Clue sharing.
- Persistent history.
- Partner online/offline status.
- Drawing-based messages where feasible.

Allow players to place a marker on an object in Temporal Vision and send its corresponding world location to their partner.

Synchronize relevant messages with the shared investigation journal.

Communication must work without requiring both players to be present simultaneously.

# 25. TIME ECHO PROJECTIONS AND TEMPORAL RIPPLE EFFECTS

Reuse the EchoAvatar system defined in Section 10 for all Time Echo partner projections. Do not implement a separate, duplicate ghost system.

Use cyan-blue for a future player's projection in 2026 and warm gold for a past player's projection in 2046.

Clearly distinguish live partner projections from recorded historical echoes and last-known positions.

Do not introduce cross-timeline physical collisions.

Whenever a historical change affects the future, display:

- Expanding temporal energy ripple.
- Glowing particles.
- Subtle camera feedback.
- Animated geometry transformation.
- Temporal sound.
- Small explanatory notification.

Examples:

A wall disappears.

A wooden platform becomes accessible.

Water drains from a tunnel.

Electricity returns to a building.

A historical photograph changes.

Make these transformations visually satisfying and technically safe.

# 26. REVISED COOPERATIVE STORYLINE

CHAPTER 1 — THE FLOOD THAT NEVER HAPPENED

Mission 0: Echo Awakening.

Both players begin at corresponding locations in Willowbrook and discover their partner's temporal projection by activating Time Echo with T. Teach movement, interaction, pointing and waving gestures, Echo Link, shared markers and Temporal Vision with V. Do not require either player to discover or enter a physical headquarters.

Mission 1: The Photograph That Changes.

The future player finds a historical photograph.

The past player rearranges construction equipment.

The photograph updates and reveals the dam's hidden maintenance access.

Mission 2: The Lost Room.

The future player identifies a blocked entrance.

The past player changes the original construction layout.

The future player accesses the hidden room and retrieves a historical document.

Mission 3: The Broken Machine.

Both players compare different versions of a damaged machine.

The past player transfers the required missing component through a time capsule.

The future player repairs the machine.

Mission 4: The Town That Remembers.

The past player convinces an NPC to preserve essential supplies or relocate them to higher ground.

The future player retrieves the preserved equipment.

Mission 5: The Unreachable Platform.

The future player sends a construction blueprint.

The past player physically assembles a durable platform or staircase.

The future player reaches an elevated electrical control station.

Mission 6: The Silent Power Station.

The future player investigates emergency light patterns.

The past player solves the electrical connection puzzle.

Electricity returns to the future facility.

Mission 7: Beneath Willowbrook.

The future player explores flooded tunnels.

The past player operates drainage valves.

Both players cooperate to reveal the final control room.

Mission 8: The Flood That Never Happened.

The future player discovers the correct floodgate configuration.

The past player operates the floodgate machinery.

Both players complete their required objectives and determine the town's fate.

Integrate cement messages, audio clues, Temporal Vision, the temporal flashlight and butterfly effects throughout the storyline.

The full mission list is the long-term chapter design.

Prioritize a smaller complete mission chain for the three-day playable release.

# 27. FINAL DISASTER COUNTDOWN

Create an optional live cooperative countdown during the final floodgate mission.

During the countdown:

- Dark clouds gather.
- Rain intensifies.
- Water rises.
- Warning sirens activate.
- Players receive urgent objectives.

The past player operates machinery.

The future player guides them using discovered historical information and completes separate control-room tasks.

Keep all normal missions untimed.

For asynchronous sessions, provide an untimed finale or a countdown that starts only when the necessary players explicitly agree.

Do not let real-world offline time cause unavoidable mission failure.

# 28. REAL MULTIPLAYER

Implement genuine two-player room-based multiplayer using a supported backend such as Supabase after confirming feasibility.

Support:

- Room creation.
- Room code joining.
- Two-player limit.
- Authenticated identities.
- Separate timeline roles.
- Ready states.
- Reconnection.
- Continue Adventure.
- Online/offline presence.
- Shared persistent state.
- Real-time or near-real-time environmental updates.

Persist:

- Environmental objects.
- Item ownership.
- Photographs.
- NPC decisions.
- Machine states.
- Wall layouts.
- Water configurations.
- Audio sequences.
- Blueprint components.
- Electrical connections.
- Cement drawings.
- Time capsules.
- Messages.
- Rewind history.
- Mission progress.
- Final outcomes.

Validate room membership and state-changing actions.

Prevent duplicated inventory, contradictory updates and unauthorized room access.

Use versioned events and authoritative validation for important gameplay state.

Never embed private service-role credentials inside the game.

Use a clearly labeled local demonstration mode for development and testing both roles on one computer.

Do not claim local role switching is genuine online multiplayer.

If backend configuration is required, provide exact setup steps and request the necessary user configuration.

# 29. PREMIUM UI

Follow the supplied reference image.

Main menu:

- Live cinematic 3D Willowbrook background.
- Strong game logo.
- Animated timeline transitions.
- Play with a Friend.
- Create Room.
- Join Room.
- Continue Adventure.
- Local Demonstration.
- How to Play.
- Settings.

Multiplayer lobby:

- Both player avatars.
- Timeline selection.
- Room code.
- Copy invite code.
- Connection status.
- Ready controls.
- Start Adventure.

Gameplay HUD:

- Small contextual interaction prompt.
- Subtle timeline indicator.
- Temporary objective notifications.
- Temporary selected-item notifications.

During ordinary exploration, keep the town, player and partner's Echo Avatar visually dominant. Do not permanently display a minimap, inventory hotbar, large mission tracker, communication panel, resource points or control guide.

Make the six-slot inventory, map, investigation journal, Echo Link, blueprint editor, Temporal Vision and other major interfaces available as temporary popups.

Use readable typography, restrained colors and consistent icons. Release the mouse cursor for popups and prevent gameplay inputs from firing while navigating them.

Do not cover most of the gameplay screen with panels.

Use proper anchors and container sizing.

Test at 1280×720, 1920×1080 and smaller window sizes.

# 30. SOUND AND ATMOSPHERE

Create distinct soundscapes for both timelines.

Past:

- Peaceful music.
- Birds.
- Flowing water.
- Town activity.
- Construction sounds.

Future:

- Mysterious ambience.
- Rain.
- Thunder.
- Wind.
- Floodwater.
- Damaged machinery.

Add interaction sounds, footsteps, device feedback, recording playback, electrical activation, temporal ripples, construction placement and mission completion.

Use original or appropriately licensed assets.

Include separate volume controls.

# 31. CINEMATIC ENDING

Determine the ending from actual completed cooperative puzzle states.

Possible results:

- Catastrophic flood prevented.
- Partial damage with protected residents.
- Major flood damage.

For successful players, gradually transform the damaged future town into a restored and hopeful Willowbrook.

Show the physical structures, preserved messages, repaired machinery and rescued historical objects that resulted from cooperation.

Allow the future player to walk through the changed town.

Display a shared contribution history explaining how each player's actions helped their partner.

End with:

"You never lived in the same time. But you changed the same future."

# 32. TECHNICAL ARCHITECTURE

Use Godot 4 Standard and GDScript.

Preserve Compatibility renderer support as the baseline.

Use reusable scenes and modular scripts.

Create systems for:

- Shared world state.
- Timeline management.
- Persistent object identity.
- Event history.
- Inventory.
- Interaction.
- Time Echo activation and shared temporal energy.
- Temporal Vision observation-window rendering and perspective alignment.
- EchoAvatar rendering.
- Partner presence.
- Live movement and animation synchronization.
- Historical echo recording and playback.
- Communication.
- Multiplayer.
- Missions.
- Photographs.
- Construction.
- Water puzzles.
- Electrical puzzles.
- Audio.
- Saving.

Keep gameplay rules independent of storage.

Support local and remote state repositories through a common interface.

Use stable IDs for corresponding objects across timelines.

Ensure repeated events are idempotent.

Do not allow asynchronous changes to produce invalid inventory or contradictory mission states.

Keep rendering optimized for student laptops.

# 33. THREE-DAY DEVELOPMENT PRIORITIES

This complete specification defines the final game vision.

Do not attempt to implement every feature simultaneously.

MILESTONE A — VISUAL FOUNDATION

- Upgrade Willowbrook in both timelines using the supplied visual reference.
- Improve terrain, architecture, vegetation, lighting, characters, movement, animations and third-person camera.
- Implement a minimal gameplay HUD.
- Establish matching world coordinates and stable location identifiers.
- Implement local timeline selection for visual testing.
- Prepare visual assets and architecture for the Time Echo device, Temporal Vision window and shared energy system without activating either ability.
- Prepare reusable character scenes for EchoAvatar rendering.
- Remove resource-purchase UI from the new adventure mode while preserving legacy saves.
- Do not implement the complete Time Echo or Temporal Vision abilities yet.

MILESTONE B — SHARED GAMEPLAY FOUNDATION

- Implement inventory and interaction.
- Implement versioned persistence.
- Establish local role switching.
- Implement the shared investigation journal and Echo Link communication.
- Implement location markers.
- Establish the multiplayer backend interface.
- Begin early multiplayer feasibility testing.

MILESTONE C — SIGNATURE TEMPORAL MECHANICS

- Time Echo activation, shared temporal energy and spectral rendering.
- Temporal Vision activation and animated alternate-environment rendering.
- EchoAvatar visual rendering and recorded historical echo playback.
- Dynamic temporal changes.
- Temporal flashlight.
- Echo Link.
- Shared location markers.
- Time ripple effects.

MILESTONE D — COMPLETE COOPERATIVE PLAYABLE CHAPTER

Prioritize:

- One changing photograph puzzle.
- One physical blueprint construction puzzle.
- One water-level puzzle.
- One meaningful future investigation.
- Functional communication.
- Final floodgate interaction.
- Complete ending.

Reuse cement writing and time capsules where they strengthen the playable chapter.

MILESTONE E — ONLINE COOPERATION

- Real room creation and joining.
- Separate timeline roles.
- Persistent player identity.
- Live EchoAvatar movement and animation synchronization.
- Genuine Time Echo partner synchronization across separate clients.
- Shared environmental updates.
- Reconnection.
- Actual two-client testing.

Validate backend feasibility early rather than leaving the first connection test until the final day.

MILESTONE F — ADVANCED EXPANSION

Implement remaining features after the core playable chapter works:

- NPC decisions.
- Reverse engineering.
- Disappearing rooms.
- Electrical puzzles.
- Recorded audio.
- Expanded butterfly effects.
- Timeline rewind.
- Expanded storyline.

Do not sacrifice stable working gameplay for a large collection of incomplete mechanics.

# 34. VISUAL ACCEPTANCE CRITERIA

The actual game must demonstrate:

- Recognizable detailed architecture.
- Natural textured environments.
- Premium stylized character quality and consistent proportions.
- Consistent geography across both timelines.
- Reusable character models suitable for temporal projections.
- Distinctive Time Echo device and animated Temporal Vision window.
- Immersive third-person camera.
- Rich environmental detail.
- Distinct past and future atmospheres.
- Uncluttered gameplay presentation.
- Visually satisfying timeline effects.

Capture real screenshots from the running game at viewpoints comparable to the reference image.

Do not use generated concept art as proof of implementation.

Do not report visual completion based on headless validation alone.

# 35. TESTING AND REPORTING

Create or update DEVELOPMENT_PLAN.md during Milestone A implementation with all milestones, dependencies and acceptance criteria.

Run Godot headless validation after each milestone.

Perform GUI testing wherever supported.

Test only systems implemented in the current milestone:

- Camera and character movement.
- Inventory.
- Interaction and collision.
- Both timeline states.
- Time Echo activation, duration, energy drain and manual deactivation.
- Time Echo active-only projection visibility and visual feedback.
- Temporal Vision duration, energy drain and correct alternate-world rendering.
- Temporal Vision ring animation, camera perspective alignment and non-teleporting behavior.
- Shared-energy depletion, recharge delay and recharge rate.
- Minimum activation energy and combined drain when both abilities are active.
- No energy consumption when Time Echo has no live or recorded partner echo.
- Echo Link and essential clues remaining available without temporal energy.
- Essential puzzles remaining solvable after energy depletion.
- Temporal abilities deactivating at duration or energy limits.
- Persistent environmental changes.
- EchoAvatar rendering.
- Partner movement synchronization.
- Recorded historical echo playback.
- Identification of live versus recorded presence.
- Gesture synchronization.
- Cross-timeline coordinate accuracy.
- Popup interface functionality.
- Puzzle completion.
- Save recovery.
- Room isolation.
- Multiplayer synchronization.
- Reconnection.
- Performance.
- UI scaling.

Do not mark online multiplayer complete without genuine separate client testing.

Do not automatically commit or push changes.

Clearly report implemented, tested, partially implemented and unimplemented features.

# FINAL INSTRUCTION

Implement Milestone A only in the existing project.

Inspect the existing project and the visual reference.

Upgrade both playable Willowbrook timelines, characters, movement, animations, camera and minimal gameplay HUD.

Establish matching world coordinates, stable location identifiers, local timeline selection for visual testing and reusable character scenes for EchoAvatar rendering.

Prepare visual assets and architecture for Time Echo, Temporal Vision and their shared energy system, but do not implement ability functionality or begin later milestone gameplay systems.

Preserve legacy saves while removing resource-purchase UI from the new adventure mode.

Run Godot validation and capture actual screenshots from the running game.

Stop after Milestone A for visual approval.

Do not automatically commit or push changes.