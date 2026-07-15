extends Node

var damage =  0

var targeted_card = ""
var needs_target_sync = true

func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	damage = randi_range(1, 3)
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	var target_card = duel_manager_ref.opp_cards_on_field.pick_random()
	if target_card:
		target_card.card_slotted_in.get_node("AnimationPlayer").play("jack_o_bomb")
		await duel_manager_ref.wait(1.0)
		target_card.card_slotted_in.get_node("AnimationPlayer").play("explosion")
		target_card.health = max(0, target_card.health - damage)
		target_card.health = max(0, target_card.health - damage)
		target_card.get_node("Health").text = str(target_card.health)
		await duel_manager_ref.wait(0.5)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref.destroy_card(card, "Opponent")
	duel_manager_ref.destroy_card(skill_card, "Player")
	await duel_manager_ref.wait(1.0)
	duel_manager_ref.enable_end_turn_btn(true)
	input_manager_ref.inputs_disabled = false


func trigger_skill_opp(duel_manager_ref, skill_card, input_manager_ref):
	if damage == 0:
		damage = randi_range(1, 3)
	input_manager_ref.inputs_disabled = true
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	var target_card = duel_manager_ref.player_cards_on_field.pick_random()
	if target_card:
		target_card.card_slotted_in.get_node("AnimationPlayer").play("jack_o_bomb")
		await duel_manager_ref.wait(1.0)
		target_card.card_slotted_in.get_node("AnimationPlayer").play("explosion")
		target_card.health = max(0, target_card.health - damage)
		target_card.health = max(0, target_card.health - damage)
		target_card.get_node("Health").text = str(target_card.health)
		await duel_manager_ref.wait(0.5)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref.destroy_card(card, "Player")
	duel_manager_ref.destroy_card(skill_card, "Opponent")
	await duel_manager_ref.wait(1.0)
	input_manager_ref.inputs_disabled = false


func trigger_skill_pvp(duel_manager_ref, skill_card, input_manager_ref, target_card, synced_damage):
	damage = synced_damage
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	if target_card:
		target_card.card_slotted_in.get_node("AnimationPlayer").play("jack_o_bomb")
		await duel_manager_ref.wait(1.0)
		target_card.card_slotted_in.get_node("AnimationPlayer").play("explosion")
		target_card.health = max(0, target_card.health - damage)
		target_card.get_node("Health").text = str(target_card.health)
		await duel_manager_ref.wait(0.5)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref.destroy_card(card, "Opponent")
	duel_manager_ref.destroy_card(skill_card, "Player")
	await duel_manager_ref.wait(1.0)
	duel_manager_ref.enable_end_turn_btn(true)
	input_manager_ref.inputs_disabled = false


func trigger_skill_opp_pvp(duel_manager_ref, skill_card, input_manager_ref, target_card, synced_damage):
	damage = synced_damage
	input_manager_ref.inputs_disabled = true
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	if target_card:
		target_card.card_slotted_in.get_node("AnimationPlayer").play("jack_o_bomb")
		await duel_manager_ref.wait(1.0)
		target_card.card_slotted_in.get_node("AnimationPlayer").play("explosion")
		target_card.health = max(0, target_card.health - damage)
		target_card.get_node("Health").text = str(target_card.health)
		await duel_manager_ref.wait(0.5)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref.destroy_card(card, "Player")
	duel_manager_ref.destroy_card(skill_card, "Opponent")
	await duel_manager_ref.wait(1.0)
	input_manager_ref.inputs_disabled = false
