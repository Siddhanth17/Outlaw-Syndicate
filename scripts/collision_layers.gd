class_name CollisionLayers
extends RefCounted

const STATIC: int = 1
const PLAYER: int = 2
const VEHICLE: int = 4
const NPC: int = 8
const PROP: int = 16
const PROJECTILE: int = 32
const INTERACTION: int = 64
const TRIGGER: int = 128
const RAGDOLL: int = 512
const SOLIDS: int = STATIC | PLAYER | VEHICLE | NPC | PROP | RAGDOLL
