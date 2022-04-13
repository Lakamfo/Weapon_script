extends Camera3D

func _process(delta):
	$"../../Node".rotation.x = lerp_angle($"../../Node".rotation.x,get_parent().rotation.x,0.2)
	$"../../Node".rotation.y = lerp_angle($"../../Node".rotation.y,get_parent().rotation.y,0.2)
