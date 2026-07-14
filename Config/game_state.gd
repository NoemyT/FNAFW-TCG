extends Node

enum GameMode { NONE, AI, PVP }
enum AIType { NONE, ATTACK, SURVIVAL }
enum PVPType { NONE, HOST, CLIENT }

var current_mode: GameMode = GameMode.NONE
var current_ai_type: AIType = AIType.NONE
var current_pvp_type: PVPType = PVPType.NONE

func set_ai_mode(type: AIType) -> void:
	current_mode = GameMode.AI
	current_ai_type = type
	current_pvp_type = PVPType.NONE

func set_pvp_mode(type: PVPType) -> void:
	current_mode = GameMode.PVP
	current_pvp_type = type
	current_ai_type = AIType.NONE

func reset() -> void:
	current_mode = GameMode.NONE
	current_ai_type = AIType.NONE
	current_pvp_type = PVPType.NONE

func get_mode_description() -> String:
	match current_mode:
		GameMode.AI:
			return "AI - " + AIType.keys()[current_ai_type]
		GameMode.PVP:
			return "PVP - " + PVPType.keys()[current_pvp_type]
		_:
			return "No game mode selected"
