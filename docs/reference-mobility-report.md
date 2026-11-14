# Reference-directed hero, movement audio and district mobility

Continues the validated ff5e16e working tree in Godot 4.6/Jolt. No reset, migration, force push, removed voices or overwritten previous playable package. The previous living-city-signature build remains preserved. This is a partial production increment, not reference parity or a completed campaign.

## Adrian — PARTIAL

The user-provided references/Adrian_Reference.png was opened and inspected directly. Direction: exposed forehead, swept-back crown, a half-tied dark tail with loose shoulder layers, stronger jaw and athletic silhouette. The image is kept local/ignored, not redistributed as game art and not cloned as an identity. No reference tattoo designs are copied.

A separate adrian_reference.glb and editable .blend derive from the preserved signature source. They add 176 original narrow swept/tail/temple ribbons, a rounded scalp-only underlayer and a small dark tie. The old broad conical shoulder shell is removed from this new variant. Existing bounded long-hair chains deform the loose layers. Small jaw/chin and torso changes are applied consistently to facial morphs and compatible jacket geometry. The dark leather outfit remains. Original signature/base/NPC assets and dialogue WAVs are retained.

Rendered inspection shows a clearer exposed face and half-tied silhouette, but the cap can still read as a helmet, cards can look streaky, and the face, beard, skin, hands and jacket remain coarse. This is not silky strand-level hair, a muscular anatomical rebuild or premium scanned leather. No tank-top variant was delivered. Hair has bounded springs, not full collision against body/seat/headrest. Existing face morph/amplitude dialogue and injury framework remain unchanged.

## Movement sound — implemented system, PARTIAL realism

Forty preloaded 24 kHz PCM foley derivatives provide four variations for nine ground profiles plus quiet cloth: asphalt, concrete, warehouse, metal, dirt, grass, wood, interior and stairs. Ground rays query explicit nonphysical acoustic regions or collider metadata; sounds are not selected from player coordinates. Road/sidewalk, metal manhole, wooden cargo and warehouse apron tags exist in the district. The nine labeled laboratory strips are acoustic inspection pads, not finished art or evidence that nine fully modeled biomes/interiors exist.

Kenney Impact Sounds 1.0 is CC0. The current publisher download session, included license, archive hash, per-source/output hashes and exact EQ/tail processing are retained. Concrete/warehouse/stairs/asphalt intentionally share concrete recordings with different processing; dirt derives from grass; metal and cloth use curated light/soft impact foley. These are not independent boots/jacket recording sessions. Short authored echo tails are not dynamic interior acoustics. The bike loop is original synthesis, not recorded motorcycle audio. Naturalness and final mix still need human listening review.

Footfalls follow actual grounded displacement, speed-adjusted stride and cooldown, rather than repeating on a timer while blocked. Selection prevents immediate repeats. Walk/run/sprint vary impact strength/cadence; real landing and stopping produce restrained contacts; low cloth foley occurs intermittently. A four-voice pool preserves short tails. Movement volume is separately adjustable/saved. Standing, airborne, riding and paused movement do not create repeated steps. An actual engine output-mix WAV is captured by the exported validator; silent video and audio are separate artifacts.

## Car entry/exit — PARTIAL

A new sable_interactive.glb separates actual front-left door geometry, glazing, mirror/handle parts and an inner panel from the preserved Sable mesh. The door pivots around a real hinge; existing six-pane damage and separate lamp/bumper systems remain.

Normal gameplay uses a 2.8-second alignment, opening, seat transition and closing timeline. Driving control activates after entry finishes. Exit reverses the supported root transition and restores on-foot collision/control. Input/look remains available; fire is blocked during transitions. Vehicle speed, standing clearance and a conservative door sweep envelope are checked. Pause freezes the timeline. Save requests wait for completion; loading/new game forcibly cancel transient state. The car is held stationary during the sequence.

The body uses existing Enter/Exit/Drive actions with root interpolation, not newly authored full contact animation. Exact handle grip, independent leg withdrawal, closing-hand contact, continuous moving-obstacle clearance and hand-to-wheel IK remain unfinished. Alignment can slide and limbs may clip. This is a functional animated prototype, not the requested polished ten-step performance.

Legacy headless/--script functional routes retain immediate occupancy fallback so they can exercise objective logic; the dedicated mobility validator explicitly forces the real animated path, including blocked entry, pause, close/settle and cancellation. Normal menu gameplay uses animation. Forced checkpoint recovery also uses a documented immediate reset. No animation quality claim is based solely on the fallback tests.

## Harrier motorcycle — PARTIAL playable prototype

An original unbranded modeled motorcycle includes tubular frame, shaped tank, saddle, fork, engine fins, exhaust, lamps, bars, mirrors and two separate wheels. It is usable from the initial district parking position near (-5,10). Approach and press E/Y to mount; normal move/steer/brake and mouse camera controls apply. Stop before dismounting. Timed mount/dismount, follow camera, a separate Ride pose, distinct synthetic engine loop, actual wheel-driven acceleration/braking/steering and world collisions are implemented. Confirmed character contacts can notify the shared NPC reaction system.

This uses Jolt VehicleBody3D with two raycast wheels and assisted upright angular locks. Lean is bounded visual roll; it is not free motorcycle balance, countersteering simulation or crash/ejection dynamics. Mounting is a simple root/pose transition, not a fully authored leg-over animation. Rider hands/feet are approximate and no handlebar IK is claimed. Bike damage, rider ejection, helmet/costume variants and advanced tire behavior remain unfinished. Mounted saves restore the bike parked and the player safely on foot; old saves without bike fields remain accepted. The opening mission still requires the Sable; the bike is currently free-roam traversal, not a substitute for mission vehicle objectives.

## District — PARTIAL expansion

Original central street/mission coordinates remain. Ground footprint expands from 150x245 m to a 260x340 m secondary base. Two parallel service roads, north/south cross streets and two narrow warehouse-gap connectors create a loop and alternate routes. Five additional existing authored warehouse variants, twelve containers, two forklifts, fencing, two parked cars, signage and distance-faded lights populate the expansion. Twelve ambient actors (four additional industrial routes) plus fixed Dante use the enlarged collision-sampled navigation grid. This is modular reuse; there are no new photogrammetric buildings, real interiors, full docks/waterfront, traffic or a living metropolis. Ground areas can still feel sparse and need art/content work.

Connected pedestrian paths to west freight and east quay are checked. The normal opening mission, NPC incidents, damage, voices, labs and checkpoints are preserved. Parked side-road cars are not selectable player vehicles or checkpoint-persistent garage entries.

## Campaign — NOT STARTED runtime expansion

Mission 01 remains the short opening mission. Broken Trust's prepared five voice lines are retained; no additional finished mission is claimed. The new west freight supervisor route, north warehouse connector and east delivery route give concrete spaces for its investigation and optional bike traversal. Runtime objectives, arbitrary dialogue-partner binding, encounters/chases, checkpoints and end-to-end validation are still required. See mission-manifest.md for proposed coordinates, clearly labeled as design.

## Exact continuation

First manually listen to the engine movement mix and play the exported doors/bike with keyboard and gamepad. Refine the actual groom/skin/beard/hand/garment art and Ride/door contact clips; add continuous transition sweeps, handle/wheel/peg IK and better bike balance/damage. Build the Broken Trust investigation/objective/checkpoint runtime in the new loop, bind supervisor/driver dialogue and validate all routes. Full articulated ragdolls and terrain foot IK remain outstanding from the previous milestone. No background continuation is promised.

Known prior Vulkan shutdown Texture RID warnings and editor-settings safe-save diagnostics are reported in the validation document. Source checks alone are not visual or audio quality acceptance.
