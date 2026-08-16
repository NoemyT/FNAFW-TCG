extends Node

const DAMAGE = 3

func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	duel_manager_ref.enable_attack_btn(false)
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	AudioController.play_4th_wall()
	duel_manager_ref.player_skills_node.get_node("AnimationPlayer").play("4thWall")
	await duel_manager_ref.wait(0.45)
	for card in duel_manager_ref.opp_cards_on_field:
		card.health = max(0, card.health - DAMAGE)
		card.get_node("HpL").text = str(card.health)
		duel_manager_ref.damage_color(card.get_node("HpL"), Color.RED, 0.2)
		if card.health == 0:
			cards_to_destroy.append(card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_OPPONENT)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_PLAYER)
	await duel_manager_ref.wait(1.0)
	duel_manager_ref.enable_end_turn_btn(true)
	duel_manager_ref.refresh_attack_btn_visibility()
	input_manager_ref.inputs_disabled = false


func trigger_skill_opp(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	AudioController.play_4th_wall()
	duel_manager_ref.get_opp_skills_node().get_node("AnimationPlayer").play("4thWall")
	await duel_manager_ref.wait(0.45)
	for card in duel_manager_ref.player_cards_on_field:
		card.health = max(0, card.health - DAMAGE)
		card.get_node("HpL").text = str(card.health)
		duel_manager_ref.damage_color(card.get_node("HpL"), Color.RED, 0.2)
		if card.health == 0:
			cards_to_destroy.append(card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_PLAYER)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_OPPONENT)
	await duel_manager_ref.wait(1.0)
	input_manager_ref.inputs_disabled = false
