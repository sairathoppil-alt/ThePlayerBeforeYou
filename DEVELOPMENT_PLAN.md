# Development Plan

This plan tracks the cooperative adventure foundation in `references/GAME_DESIGN.md`.
The original resource-preparation prototype remains available in its own scenes and save file.

## Completed foundation

- [x] **A1 — 2026 Willowbrook:** Procedural town landmarks, terrain, roads, river, lighting and stable shared coordinates.
- [x] **A2 — 2046 Willowbrook:** Playable flooded/damaged variation using the same location IDs, coordinates and structures; includes rain, debris, floodwater and changed lighting.
- [x] **A3 — Character and camera:** Reusable procedural player, third-person movement/camera, role-specific colors, walk animation and remote-proxy mode.
- [x] **A4 — Temporal visuals:** Procedural wrist-mounted Time Echo device and a separate SubViewport/Camera3D temporal observation window.
- [x] **A5 — Timeline test setup:** Main-menu timeline selection, F4 local switching and fixed Past/Future roles when in a LAN room.
- [x] **Adventure menu/UI:** Local demonstration, LAN room create/join, continue adventure, settings, help, pause, inventory, map, journal and Echo Link popups.
- [x] **Local gameplay state:** Versioned `adventure_state.json` storage for checkpoints, inventory, dropped items, world flags, journal, messages, markers, temporal energy and recorded movement. Legacy `game_state.json` remains separate.
- [x] Added a schema v1-to-v2 migration for existing adventure saves, preserving held/dropped item state while adding missing temporal data.
- [x] **Inventory/interactions:** Six persistent item slots, collection, equipment display, dropping, contextual proximity checks and two tool-gated machinery toggles.
- [x] **Temporal abilities:** Configurable shared energy pool; Time Echo and Temporal Vision activation/deactivation, limits, combined drain, recharge delay and depleted-energy shutdown.
- [x] **LAN foundation:** ENet host/join, Past/Future roles, movement/animation/equipment selection relay, chat, location markers, selected world flags, journal relay and initial shared-state snapshot.
- [x] **Temporal Flashlight foundation:** Future-only light and historical-appearance outlines for damaged modular facilities.
- [x] **Playable chapter foundation:** Nine persistent missions, role-specific objectives, the changing-photo comparison, blueprint assembly, drainage, power routing and floodgate outcome.
- [x] **Water-level puzzle:** Future flood marks reveal an ordered three-valve sequence in the past; each step persists, syncs in LAN rooms and changes future flood geometry.
- [x] Added smoke coverage for out-of-order valve rejection, all three persistent valve steps, and validation of shared world-flag snapshots.
- [x] **Runtime fixes:** Restore the saved camera yaw at spawn and avoid creating an orphan collision shape for the tunnel facility.
- [x] Made Temporal Vision viewport setup safe to call again when refreshing the town after a world-state change.
- [x] Added headless smoke coverage for both timeline camera spawns and the mission/photo comparison.

## Validation completed

- [x] Godot 4.7.2 Compatibility renderer.
- [x] Headless editor import.
- [x] Headless `adventure_world.tscn` startup.
- [x] Headless main-menu startup.

## Current limitations and remaining work

- [x] Visually inspected the 2026 and 2046 spawn framing in the GUI at 1280×720; both initial views are unobstructed.
- [x] Opened Temporal Vision in the GUI and confirmed the circular alternate-timeline view and active-only energy/time readout.
- [x] Confirmed Time Echo reports unavailable without a live partner or recorded echo; no fabricated projection was shown.
- [ ] Save persistent gameplay screenshots; the GUI inspection was visual only and no screenshot files were created.
- [ ] Reopen/reload the Godot editor before GUI testing. The already-open editor had stale project settings after external autoload additions; fresh headless Godot instances loaded the scenes without errors.
- [ ] Test movement, interactions, save/reload, inventory, energy limits and recharge manually; headless startup is not a substitute for these behavior tests.
- [ ] Test two independent Godot clients on separate processes/devices, including disconnects and role assignment. LAN networking has not yet been verified end-to-end.
- [ ] LAN is direct-IP/UDP ENet only. There is no Internet matchmaking, authentication, room access control, NAT traversal, reconnection or authoritative backend.
- [ ] Shared inventory/item ownership and dropped-item replication are not implemented. Shared-state snapshots are initial/partial; concurrent offline edits can conflict.
- [ ] The nine-mission chain is playable as a foundation, but several objectives still use proximity points or flags rather than authored physical puzzle interactions. The three-valve water sequence is now persistent and visibly changes the future.
- [ ] Character gestures, facial animation, full tool-use animation, and partner animation synchronization are not implemented.
- [ ] Temporal Vision rendering and the Temporal Flashlight need visual/interaction review. The flashlight currently reveals procedural facility outlines, not a complete historical reconstruction of every object.
- [ ] Offline historical echo playback requires previously recorded real partner movement on that device; the prototype never fabricates a partner.
- [ ] No external third-party assets are used. See `ASSET_CREDITS.md`.

## Next tasks

1. GUI-test the water-level sequence, Temporal Vision and the ending; capture gameplay screenshots.
2. Play the mission chain end-to-end and verify item consumption, persistent flags, flood-state changes and ending conditions across reloads.
3. Run two independent Godot clients and verify room roles, movement, chat, world flags, mission progression, disconnects and reconnects.
4. Implement a coordinated room/reconnection/backend strategy before claiming authenticated Internet multiplayer; direct-IP ENet remains unverified.
5. Continue the missing physical puzzles: disappearing room, rewind, electrical sequence, cement messages, physical capsules, musical playback and butterfly effects.

Headless scene and smoke-test passes do not prove GUI quality or separate-client multiplayer. Do not claim online multiplayer is complete without those tests.
