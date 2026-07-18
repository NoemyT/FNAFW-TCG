extends Control

func _on_return_pressed() -> void:
	AudioController.play_menu_click()
	$".".visible = false


func _on_rich_text_label_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))
