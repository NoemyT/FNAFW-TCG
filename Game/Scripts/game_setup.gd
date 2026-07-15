extends Node2D

const STARTING_HEALTH = 20

func host_set_up():
	#MultiplayerManager.game_active = true
	$Hp/PlayerHp.text = str(STARTING_HEALTH)
	#MultiplayerManager.opp_field.get_node("OppHealth").text = str(STARTING_HEALTH)
	$DuelManager.player_health = STARTING_HEALTH
	$DuelManager.opponent_health = STARTING_HEALTH
	await $Deckpile.draw_first_hand_networked(true)
	$EndTurnButton.visible = true
	$EndTurnButton.disabled = false
	$InputManager.inputs_disabled = false


func client_set_up():
	#MultiplayerManager.game_active = true
	$Hp/PlayerHp.text = str(STARTING_HEALTH)
	#MultiplayerManager.opp_field.get_node("OppHealth").text = str(STARTING_HEALTH)
	$DuelManager.player_health = STARTING_HEALTH
	$DuelManager.opponent_health = STARTING_HEALTH
	$Deckpile.draw_first_hand_networked(false)
