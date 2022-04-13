extends CSGBox3D

func get_hit(dmg):
	prints("hit")
	$AnimationPlayer.stop()
	$AnimationPlayer.play("hit_geten")
