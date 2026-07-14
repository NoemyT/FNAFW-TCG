extends Control

func hide_menu():
	$".".visible = false


func _on_attack_pressed() -> void:
	GameState.set_ai_mode(GameState.AIType.ATTACK)


func _on_survivability_pressed() -> void:
	GameState.set_ai_mode(GameState.AIType.SURVIVAL)


func _on_back_pressed() -> void:
	hide_menu()
