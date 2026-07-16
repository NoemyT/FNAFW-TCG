extends Node

const INSTAKILL_CHANCE = 0.1
const INSTAKILL_DAMAGE = 20

var needs_target_sync = true

func trigger_skill(duel_manager_ref, skill_card, input_manager_ref):
	input_manager_ref.inputs_disabled = true
	duel_manager_ref.enable_end_turn_btn(false)
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
	if duel_manager_ref.opponent_health == 0:
		duel_manager_ref.end_game()
		return
	await duel_manager_ref.wait(duel_manager_ref.TURN_TIME)
	duel_manager_ref.enable_end_turn_btn(true)
	input_manager_ref.inputs_disabled = false


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
