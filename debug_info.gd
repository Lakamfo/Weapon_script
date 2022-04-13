extends Control

func _process(delta):
	var _text = "Debug info: \n Bullets in magazine: %s \n Bullets in save: %s"
	$Label.text = _text % [str($"../Node/ak47_".current_magazine_size),str($"../Node/ak47_".ammo_size)]
