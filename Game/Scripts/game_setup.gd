extends Node2D

const STARTING_HEALTH = 20

func host_set_up():
	#MultiplayerManager.game_active = true
	$PlayerHealth.text = str(STARTING_HEALTH)
	#MultiplayerManager.opp_field.get_node("OppHealth").text = str(STARTING_HEALTH)
	$DuelManager.player_health = STARTING_HEALTH
	$DuelManager.opponent_health = STARTING_HEALTH
	await $Deck.draw_first_hand(true)
	$EndTurnButton.visible = true
	$EndTurnButton.disabled = false
	$InputManager.inputs_disabled = false


func client_set_up():
	#MultiplayerManager.game_active = true
	$PlayerHealth.text = str(STARTING_HEALTH)
	#MultiplayerManager.opp_field.get_node("OppHealth").text = str(STARTING_HEALTH)
	$DuelManager.player_health = STARTING_HEALTH
	$DuelManager.opponent_health = STARTING_HEALTH
	$Deck.draw_first_hand(false)
