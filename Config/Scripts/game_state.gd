extends Node

## Autoload (Singleton) that holds the current game mode across scene changes.
##
## Since the game has two distinct modes (AI and PvP) that share most of their
## scenes and scripts, this node acts as the single source of truth telling the
## rest of the codebase which mode is active and, in PvP, whether this instance
## is hosting or joining.

enum GameMode { NONE, AI, PVP }
enum AIType { NONE, ATTACK }
enum PVPType { NONE, HOST, CLIENT }

## Card ownership tags. Used across the codebase to tell whose side a card,
## slot or field manager belongs to, from the local player's perspective.
## In PvP both instances use these same values: OWNER_PLAYER is always the
## local player, regardless of who is hosting.
const OWNER_PLAYER = "player"
const OWNER_OPPONENT = "opponent"

var current_mode: GameMode = GameMode.NONE
var current_ai_type: AIType = AIType.NONE
var current_pvp_type: PVPType = PVPType.NONE

## Whether it is currently the local player's turn. Read by input handling to
## block actions outside the player's turn.
var is_player_turn := false

## Sets the game to AI mode. Called from the AI mode selection menu.
func set_ai_mode(type: AIType) -> void:
	current_mode = GameMode.AI
	current_ai_type = type
	current_pvp_type = PVPType.NONE


## Sets the game to PvP mode as either host or client.
## Called from the PvP mode selection menu before the connection is attempted.
func set_pvp_mode(type: PVPType) -> void:
	current_mode = GameMode.PVP
	current_pvp_type = type
	current_ai_type = AIType.NONE


## Clears the stored mode. Called when returning to the title screen so a
## previous match does not leak its state into the next one.
func reset() -> void:
	current_mode = GameMode.NONE
	current_ai_type = AIType.NONE
	current_pvp_type = PVPType.NONE
