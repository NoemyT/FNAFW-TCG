extends Control

func _on_close_pressed() -> void:
	AudioController.play_menu_click()
	$".".visible = false


func _on_right_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))
