# Current AI

HarborGuard uses PATROL, SUSPICION, INVESTIGATE, ENGAGE and DEFEATED states. Local movement is CharacterBody3D steering with collision, not NavigationServer pathfinding. Perception uses distance plus raycast LOS; it currently has no authored vision cone. Engagement produces actual damage; defeat changes collision/visual state and persistent records. Faction reputation changes sensing/response thresholds.

The ledger security alert also changes warehouse-side lights to red, and restoration replays this visual state. Dante relationship reward produces a once-only 25-point garage repair on mission completion. These are gameplay-linked authored consequences, not only text. City-wide faction simulation, NPC schedules, police actors/pursuit, traffic and scheduled city repair rules remain absent. Search is still an abstract proximity/visibility heat system.

Dante and the two guards reuse the human model temporarily. Former box pedestrians were removed rather than misrepresented as finished civilians. Next priority: proper navigation and cover routes, distinct security/civilian art, believable routine recovery and budgeted nearby populations.
