extends Node2D

## The deck a player draws from, plus the drawing rules.
##
## The deck itself is an array of card names, shuffled at the start of every
## match, working as a stack that is always drawn from the top. Drawing is
## capped both per turn and by hand size.
##
## The same script is used by all four decks in the game, with owner_id and the
## current game mode deciding how it behaves:
##   - AI mode: both decks draw locally, with no synchronization involved.
##   - PvP mode: the local deck draws and broadcasts the result, while the
##     opponent's deck only receives cards and tracks how many are left.

@export_enum("player", "opponent") var owner_id: String = GameState.OWNER_PLAYER
@export var hand_path: NodePath
@export var field_manager_path: NodePath
## Prompt telling the player they still have draws available this turn.
@export var draw_label: RichTextLabel

const CARD_DRAW_SPEED = 0.4
const STARTING_HAND_SIZE = 7
const MAX_DRAWS_PER_TURN = 3
const MAX_HAND_SIZE = 7

var deck = []
## Starts at the cap so no draws are possible until reset_draw() is first
## called, which is what keeps the first turn draw free.
var draws_this_turn := MAX_DRAWS_PER_TURN
var deck_timer: Timer
## Only used by the opponent's deck in PvP, where the real deck lives on the
## other machine and cannot be counted directly. Stays at -1 otherwise.
var remote_deck_count := -1

func _ready() -> void:
	deck_timer = Timer.new()
	deck_timer.one_shot = true
	deck_timer.wait_time = 1.0
	add_child(deck_timer)

	_build_deck()

	draws_this_turn = 0

	if GameState.current_mode == GameState.GameMode.AI:
		_draw_starting_hand_local()
	elif GameState.current_mode == GameState.GameMode.PVP and owner_id == GameState.OWNER_OPPONENT:
		# In PvP the starting hand is dealt by PvpSetup instead, and this deck
		# only mirrors the opponent's, so it just tracks the remaining count.
		remote_deck_count = CardDatabase.get_total_deck_size()


## Shows the draw prompt only while a draw is actually possible.
func _process(_delta) -> void:
	if not draw_label:
		return
	if owner_id == GameState.OWNER_PLAYER and GameState.is_player_turn and draws_this_turn < MAX_DRAWS_PER_TURN and get_node(hand_path).hand.size() < MAX_HAND_SIZE:
		draw_label.visible = true
	else:
		draw_label.visible = false


func _build_deck() -> void:
	deck = CardDatabase.build_shuffled_deck()


# ---------- AI mode: local draws ----------

## Deals the starting hand. Bypasses the per turn cap, since the seven opening
## cards are not counted as draws.
func _draw_starting_hand_local() -> void:
	for i in range(STARTING_HAND_SIZE):
		var card_name = deck[0]
		deck.erase(card_name)
		_spawn_card(card_name)


## Draws a single card, if both the turn cap and the hand size allow it.
func draw_card_local():
	if draws_this_turn >= MAX_DRAWS_PER_TURN:
		return
	if get_node(hand_path).hand.size() >= MAX_HAND_SIZE:
		return
	draws_this_turn += 1
	var card_name = deck[0]
	deck.erase(card_name)
	_spawn_card(card_name)


## Whether any draws are left this turn. Read by the AI, which draws in a loop
## at the start of its turn.
func can_draw():
	return draws_this_turn < MAX_DRAWS_PER_TURN


# ---------- PVP mode: networked draws ----------

## Deals the starting hand one card at a time, broadcasting each draw so the
## opponent sees the cards arriving instead of appearing all at once. Both sides
## deal their own hand and announce it to the other, keeping the two instances
## in sync.
## The initial delay gives the other instance time to finish loading its scene
## before the first RPC arrives.
func draw_first_hand_networked():
	deck_timer.start()
	await deck_timer.timeout
	deck_timer.wait_time = 0.1
	var player_id = multiplayer.get_unique_id()
	for i in range(STARTING_HAND_SIZE):
		var card_name = deck[0]
		_draw_for_all(player_id, card_name)
		rpc("_draw_for_all", player_id, card_name)
		deck_timer.start()
		await deck_timer.timeout


## Draws a card in PvP, applying the same caps as the AI mode before
## broadcasting the result.
func deck_clicked_networked():
	if draws_this_turn >= MAX_DRAWS_PER_TURN:
		return
	if get_node(hand_path).hand.size() >= MAX_HAND_SIZE:
		return
	draws_this_turn += 1
	var card_name = deck[0]
	var player_id = multiplayer.get_unique_id()
	_draw_for_all(player_id, card_name)
	rpc("_draw_for_all", player_id, card_name)


## Runs on both machines for every draw, with the sender id deciding which side
## of the branch each one takes: whoever drew removes the card from their own
## deck, while the other instance shows it on the opponent's side.
@rpc("any_peer")
func _draw_for_all(player_id, card_name) -> void:
	if multiplayer.get_unique_id() == player_id:
		draw_card_networked(card_name)
	else:
		MultiplayerManager.opp_field.get_node("Deckpile").receive_card(card_name)


## Shows a card drawn by the opponent. The card is not removed from this deck,
## since the real one lives on the other machine, so only the mirrored count is
## decremented to know when to hide the pile.
func receive_card(card_name):
	_spawn_card(card_name)
	if remote_deck_count >= 0:
		remote_deck_count -= 1
		if remote_deck_count <= 0:
			_hide_deck_visual()


func draw_card_networked(card_name):
	deck.erase(card_name)
	_spawn_card(card_name)


# ---------- Shared ----------

## Builds a card and sends it to the hand. Shared by every draw path, in both
## modes and on both sides.
func _spawn_card(card_name) -> void:
	var new_card = CardFactory.create_card(card_name, owner_id)
	# Cards start on top of the deck and are animated to the hand from there.
	new_card.position = self.position
	get_node(field_manager_path).add_child(new_card)
	new_card.name = "Card"

	get_node(hand_path).add_card_to_hand(new_card, CARD_DRAW_SPEED)

	# Opponent cards are flipped face down, since their contents must stay
	# hidden until they are played.
	if owner_id == GameState.OWNER_OPPONENT:
		new_card.get_node("AnimationPlayer").play("card_flip_opponent")
	elif new_card.card_type == "entity":
		new_card.get_node("AnimationPlayer").play("card_play_entity")
	else:
		new_card.get_node("AnimationPlayer").play("card_play_skill")

	if deck.size() == 0:
		_hide_deck_visual()


## Hides the pile and makes it unclickable once the deck runs out.
func _hide_deck_visual() -> void:
	if has_node("Area2D/CollisionShape2D"):
		$Area2D/CollisionShape2D.disabled = true
	if has_node("Sprite2D"):
		$Sprite2D.visible = false


## Clears the draw counter at the start of a turn. Called by the duel managers.
func reset_draw():
	draws_this_turn = 0
