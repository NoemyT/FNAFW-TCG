extends Node

## Autoload (Singleton) that builds card instances from database entries.
##
## Every card in the game is the same scene, so this is the single place where a
## database entry is turned into a working card: attributes are assigned, the
## artwork is cropped out of the spritesheets, and the fields that do not apply
## to that card type are hidden.

const CARD_SCENE = preload("res://Game/Card.tscn")

## Builds a card from its database key and assigns it to a side.
## Returns the instance, which still needs to be added to the tree by the caller.
func create_card(card_name, owner_id):
	var card_data = CardDatabase.CARDS[card_name]
	var new_card = CARD_SCENE.instantiate()
	new_card.card_owner = owner_id

	# Character artwork is cropped from a per-character spritesheet, so the
	# region, scale and position all come from the database entry.
	var sprite = new_card.get_node("Art/Image")
	sprite.texture = load("res://Assets/Characters/%s.png" % card_name)
	sprite.region_enabled = true
	sprite.region_rect = card_data["char_region"]
	sprite.scale = card_data["scale"]
	sprite.position = card_data["char_position"]

	# The color indicator comes from a shared card assets sheet, where each
	# color group has its own region.
	var color = new_card.get_node("Art/Color")
	color.texture = load("res://Assets/Cards/pixelCardAssest_V01.png")
	color.region_enabled = true
	color.region_rect = card_data["color_region"]

	new_card.card_type = card_data["type"]
	new_card.card_color = card_data["color"]
	new_card.card_name = card_data["card_name"]

	new_card.get_node("Name").text = card_data["card_name"]

	# Entity and skill cards share the same scene, so the fields that do not
	# apply are hidden rather than removed.
	if new_card.card_type == "entity":
		new_card.get_node("Skill").visible = false
		new_card.attack = card_data["attack"]
		new_card.get_node("AttackL").text = str(new_card.attack)
		new_card.health = card_data["health"]
		new_card.get_node("HpL").text = str(new_card.health)
	else:
		new_card.get_node("Art/Attack").visible = false
		new_card.get_node("AttackL").visible = false
		new_card.get_node("Art/Hp").visible = false
		new_card.get_node("HpL").visible = false
		new_card.skill = card_data["skill"]
		new_card.get_node("Skill").text = new_card.skill
		# Each skill has its own script, instanced here so the card carries its
		# own behaviour when played.
		var skill_path = card_data["skill_script"]
		if skill_path:
			new_card.skill_script = load(skill_path).new()

	return new_card
