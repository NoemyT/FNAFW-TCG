extends Node

## Slasher: a 10% chance to end the match outright.
##
## The only skill that ignores the field entirely and goes straight for life
## points. Its damage equals the starting health, so a successful roll always
## wins on the spot, and nothing the opponent has on the field can block it.
##
## Because the roll is random, PvP needs the result carried over: the player who
## plays the card rolls it and relays it through FieldManager, while the other
## instance waits on skill_result_received rather than rolling its own.

const INSTAKILL_CHANCE = 0.1
## Matches the starting health, so a hit always ends the match.
const INSTAKILL_DAMAGE = 20

## Runs the effect when the local player plays this card. The animation plays
## either way, with only the stab sound and the damage itself depending on the
## roll, so the opponent cannot tell a miss from a hit before it resolves.
func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
	duel_manager_ref.enable_attack_btn(false)
	await duel_manager_ref.wait(duel_manager_ref.TURN_TIME)
	var hit = randf() < INSTAKILL_CHANCE
	if GameState.current_mode == GameState.GameMode.PVP:
		duel_manager_ref.player_side.get_node("FieldManager").rpc("relay_skill_result", skill_card.name, {"hit": hit})
	duel_manager_ref.player_skills_node.get_node("AnimationPlayer").play("Slasher")
	if hit:
		AudioController.play_stab()
	await duel_manager_ref.wait(0.75)
	if hit:
		duel_manager_ref.opponent_health = max(0, duel_manager_ref.opponent_health - INSTAKILL_DAMAGE)
		duel_manager_ref.opp_side.get_node("Hp/OppHp").text = str(duel_manager_ref.opponent_health)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_PLAYER)
	# Unlike every other skill, this one can end the match, so the outcome has
	# to be checked here: combat is where that check normally happens, and this
	# damage never goes through it.
	if duel_manager_ref.opponent_health == 0:
		duel_manager_ref.end_game()
		return
	await duel_manager_ref.wait(duel_manager_ref.TURN_TIME)
	duel_manager_ref.enable_end_turn_btn(true)
	duel_manager_ref.refresh_attack_btn_visibility()
	input_manager_ref.inputs_disabled = false


## Runs the effect when the opponent plays this card, putting the local
## player's life on the line instead.
func trigger_skill_opp(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	var hit
	if GameState.current_mode == GameState.GameMode.PVP:
		var data = await skill_card.skill_result_received
		hit = data["hit"]
	else:
		await duel_manager_ref.wait(duel_manager_ref.TURN_TIME)
		hit = randf() < INSTAKILL_CHANCE
	duel_manager_ref.get_opp_skills_node().get_node("AnimationPlayer").play("Slasher")
	if hit:
		AudioController.play_stab()
	await duel_manager_ref.wait(0.75)
	if hit:
		duel_manager_ref.player_health = max(0, duel_manager_ref.player_health - INSTAKILL_DAMAGE)
		duel_manager_ref.player_side.get_node("Hp/PlayerHp").text = str(duel_manager_ref.player_health)
	duel_manager_ref._destroy_card(skill_card, GameState.OWNER_OPPONENT)
	if duel_manager_ref.player_health == 0:
		duel_manager_ref.end_game()
		return
	await duel_manager_ref.wait(duel_manager_ref.TURN_TIME)
	input_manager_ref.inputs_disabled = false
