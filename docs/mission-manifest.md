# Opening mission manifest

ACT1_01 — The Last Address. Implemented as one short playable opening mission, early production quality. Canonical definition: data/homecoming.json. No later story missions exist.

Five stages are preserved: meet Dante, drive to bonded storage, recover Mara's ledger on foot, escape the search, return to Dante on foot. Ledger recovery spawns two guards and changes district alert lighting. Guards can be fought or escaped. Magazine/reserve ammo, health, damage, checkpoint failure/retry and skippable presentation are integrated. The ending rewards $500 once and Dante repairs 25 integrity once.

Automatic checkpoint after each stage; manual F5/F9 and pause save/load. Defeated guard events and selected district/faction/vehicle state restore. File replacement keeps a backup. Actual interrupted-write and full malformed-schema recovery remain untested.

Presentation: simple skippable opening/closing camera move with text subtitles and a shared human stand-in for cast. No voice, facial performance or production cinematic animation. Main mission can be completed in automated movement/driving/combat tests; no manual human duration measured. Playtest result: 14 automated physical-route checkpoints PASS, manual quality/playtime NOT RUN.

Remaining work: artist-reviewed action/cinematic animation, distinct Dante/security identity, navigation/cover, authored investigation prop/interior, richer dialogue choice, polished sound/encounter balance, additional missions only after this route passes human QA.
