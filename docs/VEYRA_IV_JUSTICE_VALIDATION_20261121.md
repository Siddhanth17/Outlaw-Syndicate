# Veyra IV recovery and justice validation — 2026-11-21

Bounded connected justice prototype validated in Godot4.6/Jolt. Full advanced-police and open-world production remains PARTIAL. No project restart, Git reset, history rewrite or previous-build overwrite.

| Requested item | Status and observed result |
| --- | --- |
| 1. Recovered local work | COMPLETE. Preserved uncommitted law, station, phone, injury and test work. Published combat5cfc9a5 remains in history. Obsolete tools/stage_veyra3_foundation.py remains untracked and untouched. |
| 2. Save/load fixes | COMPLETE. JSON integer-valued float schema versions; actual mutated-state restoration tests; processing timer; pause/phone-close custody locks; grounded custody reload. |
| 3. Witness-phone animation | COMPLETE for prototype. Actual original handset, procedural hand-to-ear pose, unit world scale, eligibility/pose-gated call completion; native images inspected. |
| 4. Dispatch | COMPLETE for one-unit scope. Persistent Rowan Hale patrol uses shared reservations and actual vehicle forces, travels over100m in the connected lab, exits physically. No police arrival teleport. |
| 5. Investigation | PARTIAL production scope. Range/LOS, unidentified officer hearing, observed outfit and vehicle-type description. No general plate/face recognition, evidence collection or coordinated multi-unit search. |
| 6. Pursuit | PARTIAL production scope. Actual return/boarding/driving, observed vehicle acquisition, last-seen search and saved assignment. One unit; persistent blockage rerouting remains incomplete. |
| 7. Arrest | PARTIAL presentation. Functional proximity/compliance gate and hands-behind-back IK, input lock, duplicate prevention. Entry/restraint acting is prototype; station transfer is an authored scene transition. |
| 8. Fines | COMPLETE prototype. Configured citation charge, exact ledger debit, no duplicate payment or invented arrest. Lab uses controlled crash-event injection; it is not a complete human traffic-stop playtest. |
| 9. Bail and detention | COMPLETE prototype. Combined cash/bank affordability, exact withdrawal/payment, retained arrest history; holding area, saved custody timer and fictional clock advancement once. No full court simulation. |
| 10. Custody spawn | COMPLETE in tested station locations. Actual floor ray gap under1cm at processing/holding after load, movement lock and native screenshot inspection. |
| 11. Persistent cases/transactions | COMPLETE for tested branches. Exact balances, report/arrest/payment counts and resolved detention survive JSON load; regional movement penalty restores within floating-point tolerance. |
| 12. Exported evidence | COMPLETE automated evidence. Continuous justice~65s and pursuit~74s actual engine recordings plus native phone/patrol/restraint/processing/holding images. Offline720p30FPS, not performance samples or human playtesting. Pursuit camera does not continuously frame both cars. |
| 13. Regressions | COMPLETE recorded scope. Source20 suites529 checks; native15 routes485 checks, zero failures/script errors. Affected final custody36, awareness15 and regional persistence4 passed separately. Command follow-up: source40/0, native justice42/0,pursuit24/0,awareness15/0. Headless physical audio pause/resume NOT RUN; actual Windows stream checks passed. Opening mission physically completes and rewards once. |
| 14. Performance | PARTIAL acceptance. Exact clean justice build:65.446536s,6378frames,97.9257 average FPS,18.6897 FPS1%low, frame p9516.755ms/p9921.288ms/max338.246ms at1080p. Stable60FPS NOT MET. Includes checkpoint/transition stalls. Audio DSP and isolated ragdoll CPU NOT MEASURED. Command follow-up performance NOT RUN. |
| 15. Windows builds | COMPLETE. Core: builds/veyra4-justice-release-clean-20261121/OutlawSyndicate.exe. Command follow-up: builds/veyra4-officer-commands-validated-20261121/OutlawSyndicate.exe. Keep each adjacent PCK. |
| 16. Commits | COMPLETE core:42e96a1e2a1e5b4f914c9debcb190b21027b6f92. Subsequent command publication hash is recorded in its build publication metadata and Git history. |
| 17. Push | COMPLETE core: origin/main independently matched42e96a1 after normal push. Command follow-up also passed native validation; its publication metadata and final report record the normal push and verified remote hash. |
| 18. Defects/limits | PARTIAL. One patrol, prototype art/acting, authored station transfer, limited identification/review, arbitrary blockage recovery, checkpoint stalls. Normal exits warn about7texture RIDs; MovieWriter additionally logs ObjectDB/resource-in-use cleanup errors. Subjective listening and extended human playtesting NOT RUN. |
| 19. Next production milestone | PARTIAL. Began spatial officer commands after core publication using the three existing authored stock-preset lines. Next: coordinated units, search/obstruction recovery, better acting and transition-stall optimization, then broader justice/economy/factions/Broken Trust. No later campaign completion claim. |

Core archive: builds/OutlawSyndicate-Veyra-IV-Justice-Windows-x64-20261121.zip,310072698bytes; CRC tested. SHA256:e66c47d8d34fbac1d19ffc40658eb8b66d4c5f980bc33f52158a20a177c2821e. It intentionally remains the immutable42e96a1 core build; the command follow-up is a separate folder.

Private-reference export audit: the earlier all-resources preset included the local Adrian reference PNG. Added references/* exclusion. The clean PCK directory contains661entries and neither private import nor image texture resource. Cached UID metadata may retain a filename string. Earlier preserved QA/legacy packages are not certified reference-free and must not be used as the new distribution. No reference photograph was added to Git.

Exact source/gameplay hashes, executable/PCK hashes, logs, reports, screenshots and MP4s accompany the clean build. Pursuit MP4 and its114.4632 average/37.6849 FPS1%low performance sample come from the preceding identical runtime candidate; its only difference is private-reference packaging. Neither video's offline recording rate is a measured gameplay frame rate.

Licenses: original project-authored station/handset/synthesized cues; existing credited CC0 Poly Haven maps; existing Kokoro Apache-2.0/kokoro-onnx MIT generic preset for original fictional command text. No cloned voice, new third-party download or regeneration of previous assets/audio. See assets/licenses/veyra4-*provenance.json and docs/asset-licenses.md.
