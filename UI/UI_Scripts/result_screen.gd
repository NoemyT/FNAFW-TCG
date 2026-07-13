extends Control

func _ready() -> void:
	$AnimationPlayer.play("Result")


func hide_menu():
	$".".visible = false


func _on_menu_button_pressed() -> void:
	hide_menu()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
