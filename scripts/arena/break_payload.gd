## Data passed into staged wall destruction (avoids nested-class parser issues).
class_name BreakPayload
extends RefCounted

var parent: Node = null
var wall_node: Node3D = null
var wall_name: String = ""
var wall_transform: Transform3D = Transform3D.IDENTITY
var piece_size: Vector3 = Vector3.ONE
## DestructibleWall.WallKind stored as int to avoid circular class_name dependency.
var kind: int = 0
var material: StandardMaterial3D = null
var hit_world: Vector3 = Vector3.ZERO
var hit_direction: Vector3 = Vector3.ZERO
var damage_source: String = ""
