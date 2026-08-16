extends Node

const DAMAGE = 3

func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	duel_manager_ref.enable_attack_btn(false)
	await duel_manager_ref.wait(1.0)
	var target_card = duel_manager_ref.opp_cards_on_field.pick_random()
	if GameState.current_mode == GameState.GameMode.PVP:
		duel_manager_ref.player_side.get_node("FieldManager").rpc("relay_skill_result", skill_card.name, {"target": target_card.name if target_card else ""})
	var cards_to_destroy = []
	if target_card:
		AudioController.play_mega_bite()
		target_card.card_placement.get_node("AnimationPlayer").play("MegaBite")
		target_card.health = max(0, target_card.health - DAMAGE)
		target_card.get_node("HpL").text = str(target_card.health)
		duel_manager_ref.damage_color(target_card.get_node("HpL"), Color.RED, 0.2)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
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
	var target_card
	if GameState.current_mode == GameState.GameMode.PVP:
		var data = await skill_card.skill_result_received
		for c in duel_manager_ref.player_cards_on_field:
			if c.name == data["target"]:
				target_card = c
				break
	else:
		await duel_manager_ref.wait(1.0)
		target_card = duel_manager_ref.player_cards_on_field.pick_random()
	var cards_to_destroy = []
	if target_card:
		AudioController.play_mega_bite()
		target_card.card_placement.get_node("AnimationPlayer").play("MegaBite")
		target_card.health = max(0, target_card.health - DAMAGE)
		target_card.get_node("HpL").text = str(target_card.health)
		duel_manager_ref.damage_color(target_card.get_node("HpL"), Color.RED, 0.2)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_PLAYER)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_OPPONENT)
	await duel_manager_ref.wait(1.0)
	input_manager_ref.inputs_disabled = false
