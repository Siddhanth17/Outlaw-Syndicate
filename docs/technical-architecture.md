# Architecture

Godot 4.6 stable with built-in Jolt Physics, typed GDScript, compatibility renderer for initial hardware coverage. Jolt became the default new-project 3D backend in 4.6: https://godotengine.org/article/godot-4-6-all-about-your-flow/ . No external physics extension is required.

main.tscn/main.gd composes the initial world, UI and mission coordinator. ValePlayer owns movement and collision-aware camera. VeyraCar owns built-in wheel handling. CityMemory owns deterministic idempotent event records and versioned snapshots. homecoming.json contains objective locations, dialogue and reward. Smoke tests run inside Godot SceneTree.

Current composition is intentionally small, not the final city architecture. Before a second mission, extract MissionDirector, SaveService, InteractionService and district scenes; use objective IDs and Resources, not an expanding central script. Plan chunk residency budgets, navigation regions and tiered actor simulation before world expansion.

Save data lives under user://; test launcher redirects APPDATA into ignored workspace data. Main and backup saves exist. Position/schema validation, migration beyond v1 and fault injection remain required.
