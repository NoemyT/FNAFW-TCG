extends Control

func hide_disc_menu():
	$".".visible = false
	$Panel/MenuButton.disabled = true
	$Panel/ExitButton.disabled = true


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")
	hide_disc_menu()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
