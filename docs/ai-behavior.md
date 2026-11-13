# AI state

Current pedestrians move along simple fixed sidewalk paths, accelerate during search and wrap at bounds. This is a placeholder, without navigation, schedules, obstacle avoidance or actual NPC memory. Search increases on gunfire/ledger recovery and decays outside warehouse proximity. It is not police AI.

Planned: civilians idle/walk/react/flee/recover; police report/search/pursue/lose-contact; factions patrol/suspicion/investigation/combat/retreat; traffic lane graph/intersections/signals/avoidance. Near actors use navigation and perception budgets, medium actors update less often, distant state remains abstract and persistent. Measure budgets before scaling counts.
