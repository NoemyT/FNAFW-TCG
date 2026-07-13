extends Control

func _ready() -> void:
	$AnimationPlayer.play("Boot")


func hide_menu():
	$".".mouse_filter = MOUSE_FILTER_IGNORE
	$Art.visible = false
	$Panel.visible = false
	$Panel/AiButton.disabled = true
	$Panel/PvpButton.disabled = true
	$Panel/ExitButton.disabled = true


func _on_ai_button_pressed() -> void:
	$AiModeSelection.visible = true


func _on_pvp_button_pressed() -> void:
	$PvpModeSelection.visible = true


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_sound_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_tutorial_button_pressed() -> void:
	pass # Replace with function body.


func _on_info_button_pressed() -> void:
	$InfoScreen.visible = true
