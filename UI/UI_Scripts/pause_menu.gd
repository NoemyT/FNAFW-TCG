extends Control

func _ready() -> void:
	hide() 


func _on_resume_pressed() -> void:
	pass


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_audio_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
