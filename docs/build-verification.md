# Windows blockout build — 14 November 2026

PASS: exported Windows x86_64 release using official Godot 4.6 stable templates. Artifacts: `D:/OutlawSyndicate/builds/windows/OutlawSyndicate.exe` (104,578,048 bytes) and adjacent `OutlawSyndicate.pck` (22,688 bytes). Local build artifacts are excluded from Git. This is an early development build, not the complete game.

PASS: packaged executable launched headless for 180 frames. PASS: packaged executable launched with OpenGL renderer for 180 frames, exited 0, log showed NVIDIA RTX 3050 and no runtime errors. No manual playthrough or performance measurement.

Export emitted an editor-settings safe-save warning in this restricted environment; it still completed and the resulting package launched successfully. Initial export attempt preceded completion of template download and failed; final export succeeded after extraction.

SHA256 executable: F9CB815A32A1AE3A73AD8699ED2B068CB76FE01636D7E8538243056FAC05F37B

SHA256 PCK: E67661F34D18D570580E75C8D29C0DDBB135C508F64856D7563D0B1C31612E2E

Installation: keep EXE/PCK and GODOT-LICENSE.txt/GODOT-COPYRIGHT.txt together in a writable Windows folder, then run the EXE. Saves normally use Windows Roaming/Godot/app_userdata/OUTLAW SYNDICATE; source test scripts redirect APPDATA to isolated workspace data. No code signature or installer.

Known issues: geometric visuals; no collision-aware pedestrian paths; no combat enemies or player damage; search has no police; crouch slows movement without changing capsule; incomplete controller menu navigation; no audio/cinematics; limited save schema validation; only one mission; no city streaming or remaining districts. World is finite; avoid its boundaries. See development-progress.md for the full continuation list.
