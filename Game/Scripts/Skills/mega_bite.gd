extends Node

const DAMAGE = 3

var targeted_card = ""
var needs_target_sync = true

func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	var target_card = duel_manager_ref.opp_cards_on_field.pick_random()
	if target_card:
		AudioController.play_mega_bite()
		target_card.card_placement.get_node("AnimationPlayer").play("MegaBite")
		target_card.health = max(0, target_card.health - DAMAGE)
		target_card.get_node("HpL").text = str(target_card.health)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_OPPONENT)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_PLAYER)
	await duel_manager_ref.wait(1.0)
	duel_manager_ref.enable_end_turn_btn(true)
	input_manager_ref.inputs_disabled = false


func trigger_skill_opp(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	var target_card = duel_manager_ref.player_cards_on_field.pick_random()
	if target_card:
		AudioController.play_mega_bite()
		target_card.card_placement.get_node("AnimationPlayer").play("MegaBite")
		target_card.health = max(0, target_card.health - DAMAGE)
		target_card.get_node("HpL").text = str(target_card.health)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_PLAYER)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_OPPONENT)
	await duel_manager_ref.wait(1.0)
	input_manager_ref.inputs_disabled = false
