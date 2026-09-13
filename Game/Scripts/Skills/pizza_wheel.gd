extends Node

## Pizza Wheel: deals 1 damage to every enemy card on the field.
##
## Area skill: damages every enemy card on the field at once.
##
## Both entry points run the same effect, mirrored: trigger_skill() is called
## when the local player plays the card, and trigger_skill_opp() when the
## opponent does, each hitting the other side's cards. Being fully
## deterministic, this skill needs no synchronization in PvP: both instances
## reach the same result on their own.

const DAMAGE = 1

## Runs the effect when the local player plays this card. Input is locked for
## the duration so nothing else can happen mid animation, and released once the
## skill has fully resolved.
func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	duel_manager_ref.enable_attack_btn(false)
	await duel_manager_ref.wait(1.0)
	# Cards are collected rather than destroyed inside the loop, so that the
	# damage numbers are all visible before anything leaves the field.
	var cards_to_destroy = []
	duel_manager_ref.player_skills_node.get_node("AnimationPlayer").play("PizzaWheel")
	await duel_manager_ref.wait(0.5)
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
	await duel_manager_ref.wait(1.0)
	var cards_to_destroy = []
	duel_manager_ref.get_opp_skills_node().get_node("AnimationPlayer").play("PizzaWheel")
	await duel_manager_ref.wait(0.5)
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
