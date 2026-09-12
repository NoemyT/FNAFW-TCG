extends Control

## Credits and attributions screen, listing the sources of every asset used.

func _on_return_pressed() -> void:
	AudioController.play_menu_click()
	$".".visible = false


## Opens attribution links in the system browser. RichTextLabel only emits the
## clicked URL, leaving it to the script to decide what to do with it.
func _on_rich_text_label_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))
