extends Node

## Jack-O-Bomb: deals 1 to 3 damage twice to a random enemy card.
##
## Single target skill: damages one random enemy card.
##
## Because the target is rolled at random, PvP needs the result carried over:
## the player who plays the card rolls it and relays it through FieldManager,
## while the other instance waits on skill_result_received rather than rolling
## its own. Rolling on both sides would have each see a different outcome.
 
## Runs the effect when the local player plays this card. Input is locked for
## the duration so nothing else can happen mid animation, and released once the
## skill has fully resolved.
func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	duel_manager_ref.enable_attack_btn(false)
	await duel_manager_ref.wait(1.0)
	var damage_1 = randi_range(1, 3)
	var damage_2 = randi_range(1, 3)
	var target_card = duel_manager_ref.opp_cards_on_field.pick_random()
	if GameState.current_mode == GameState.GameMode.PVP:
		duel_manager_ref.player_side.get_node("FieldManager").rpc("relay_skill_result", skill_card.name, {
			"target": target_card.name if target_card else "",
			"damage_1": damage_1,
			"damage_2": damage_2
		})
	# Cards are collected rather than destroyed inside the loop, so that the
	# damage numbers are all visible before anything leaves the field.
	var cards_to_destroy = []
	if target_card:
		target_card.card_placement.get_node("AnimationPlayer").play("JackObomb")
		await duel_manager_ref.wait(1.0)
		target_card.card_placement.get_node("AnimationPlayer").play("Explosion")
		target_card.health = max(0, target_card.health - damage_1)
		target_card.health = max(0, target_card.health - damage_2)
		target_card.get_node("HpL").text = str(target_card.health)
		duel_manager_ref.damage_color(target_card.get_node("HpL"), Color.RED, 0.2)
		await duel_manager_ref.wait(0.5)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_OPPONENT)
	# The skill card is spent, leaving the field along with whatever it killed.
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_PLAYER)
	await duel_manager_ref.wait(1.0)
	duel_manager_ref.enable_end_turn_btn(true)
	duel_manager_ref.refresh_attack_btn_visibility()
	input_manager_ref.inputs_disabled = false


## Runs the effect when the opponent plays this card, hitting the local
## player's cards instead.
func trigger_skill_opp(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	var target_card
	var damage_1
	var damage_2
	if GameState.current_mode == GameState.GameMode.PVP:
		var data = await skill_card.skill_result_received
		damage_1 = data["damage_1"]
		damage_2 = data["damage_2"]
		for c in duel_manager_ref.player_cards_on_field:
			if c.name == data["target"]:
				target_card = c
				break
	else:
		await duel_manager_ref.wait(1.0)
		damage_1 = randi_range(1, 3)
		damage_2 = randi_range(1, 3)
		target_card = duel_manager_ref.player_cards_on_field.pick_random()
	var cards_to_destroy = []
	if target_card:
		target_card.card_placement.get_node("AnimationPlayer").play("JackObomb")
		await duel_manager_ref.wait(1.0)
		target_card.card_placement.get_node("AnimationPlayer").play("Explosion")
		target_card.health = max(0, target_card.health - damage_1)
		target_card.health = max(0, target_card.health - damage_2)
		target_card.get_node("HpL").text = str(target_card.health)
		duel_manager_ref.damage_color(target_card.get_node("HpL"), Color.RED, 0.2)
		await duel_manager_ref.wait(0.5)
		if target_card.health == 0:
			cards_to_destroy.append(target_card)
	await duel_manager_ref.wait(1.0)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			duel_manager_ref._destroy_card(card, GameState.OWNER_PLAYER)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_OPPONENT)
	await duel_manager_ref.wait(1.0)
	input_manager_ref.inputs_disabled = false
