# Implemented encounter

Recovering the ledger spawns two security guards. Guards patrol locally, accumulate suspicion with clear raycast visibility, investigate the last seen position after losing contact, engage at short range, damage player/vehicle, react to hits and can be defeated. Defeat records persist, preventing respawn of those guards after checkpoint restoration. Poor faction reputation expands their detection range and accelerates suspicion.

Player sidearm: camera raycast, 12-round magazine, 72 reserve rounds, cooldown, R/X reload transfer, synthesized gun/reload audio, muzzle/impact light feedback and optional slight camera recoil. Health depletion opens retry/load. Both guards can be fought or escaped during the mission search stage; the original five-stage mission is retained.

Tests exercise LOS engagement, player damage, hitscan enemy damage, ammo transfer, defeat event and checkpoint retry. This is a small encounter, not a finished combat system. Aim/hand poses, impact visuals, bullet traces, cover navigation, enemy muzzle effects, difficulty/aim assistance, additional weapons and balancing need work. No real-world training accuracy claim.
