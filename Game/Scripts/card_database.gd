extends Node

const CARDS = {
	"animdude" : {
		"attack": 7,
		"health": 6,
		"char_region": Rect2(2, 0, 250, 250),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"balloonBoy" : {
		"attack": 2,
		"health": 2,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"bonnie" : {
		"attack": 4,
		"health": 4,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"chica" : {
		"attack": 3,
		"health": 4,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"cryingChild" : {
		"attack": 1,
		"health": 2,
		"char_region": Rect2(62, 86, 138, 158),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.4, 0.4),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"foxy" : {
		"attack": 5,
		"health": 3,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"fredbear" : {
		"attack": 7,
		"health": 7,
		"char_region": Rect2(48, 39, 165, 254),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"freddy" : {
		"attack": 4,
		"health": 5,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"funtimeFoxy" : {
		"attack": 5,
		"health": 6,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"goldenFreddy" : {
		"attack": 7,
		"health": 7,
		"char_region": Rect2(56, 8, 152, 240),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"mangle" : {
		"attack": 6,
		"health": 3,
		"char_region": Rect2(57, 26, 167, 219),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"marionette" : {
		"attack": 5,
		"health": 6,
		"char_region": Rect2(57, 26, 167, 219),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"nightmare" : {
		"attack": 7,
		"health": 5,
		"char_region": Rect2(23, 5, 205, 286),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"nightmareBB" : {
		"attack": 4,
		"health": 3,
		"char_region": Rect2(41, 9, 192, 237),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"nightmareBonnie" : {
		"attack": 6,
		"health": 5,
		"char_region": Rect2(14, 3, 204, 243),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"nightmareChica" : {
		"attack": 5,
		"health": 6,
		"char_region": Rect2(60, 3, 158, 243),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"nightmareFoxy" : {
		"attack": 6,
		"health": 5,
		"char_region": Rect2(18, 10, 181, 236),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"nightmareFredbear" : {
		"attack": 7,
		"health": 7,
		"char_region": Rect2(27, 4, 201, 287),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"nightmareFreddy" : {
		"attack": 6,
		"health": 4,
		"char_region": Rect2(31, 2, 188, 243),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"nightmarionne" : {
		"attack": 6,
		"health": 6,
		"char_region": Rect2(70, 0, 125, 242),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"phantomBB" : {
		"attack": 2,
		"health": 3,
		"char_region": Rect2(55, 16, 155, 226),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"phantomChica" : {
		"attack": 3,
		"health": 3,
		"char_region": Rect2(55, 16, 155, 226),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"phantomFoxy" : {
		"attack": 5,
		"health": 2,
		"char_region": Rect2(41, 12, 168, 230),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"phantomFreddy" : {
		"attack": 4,
		"health": 4,
		"char_region": Rect2(54, 12, 167, 233),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"phantomMangle" : {
		"attack": 4,
		"health": 3,
		"char_region": Rect2(24, 50, 197, 195),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"phantomMarionette" : {
		"attack": 2,
		"health": 5,
		"char_region": Rect2(64, 15, 141, 230),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"plushtrap" : {
		"attack": 4,
		"health": 2,
		"char_region": Rect2(64, 15, 141, 230),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"purpleguy" : {
		"attack": 7,
		"health": 6,
		"char_region": Rect2(64, 15, 141, 230),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"springtrap" : {
		"attack": 7,
		"health": 7,
		"char_region": Rect2(55, 16, 145, 228),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"toyBonnie" : {
		"attack": 3,
		"health": 5,
		"char_region": Rect2(55, 16, 145, 228),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"toyChica" : {
		"attack": 2,
		"health": 6,
		"char_region": Rect2(55, 16, 145, 228),
		"bg_region": Rect2(14, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "blue",
		"skill": null,
		"skill_script": null
	},
	"toyFreddy" : {
		"attack": 4,
		"health": 5,
		"char_region": Rect2(55, 11, 178, 233),
		"bg_region": Rect2(366, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "green",
		"skill": null,
		"skill_script": null
	},
	"witheredBonnie" : {
		"attack": 6,
		"health": 4,
		"char_region": Rect2(55, 11, 137, 233),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"witheredChica" : {
		"attack": 5,
		"health": 5,
		"char_region": Rect2(55, 11, 152, 233),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"witheredFoxy" : {
		"attack": 7,
		"health": 2,
		"char_region": Rect2(55, 11, 152, 233),
		"bg_region": Rect2(133, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "red",
		"skill": null,
		"skill_script": null
	},
	"witheredFreddy" : {
		"attack": 6,
		"health": 4,
		"char_region": Rect2(55, 11, 175, 233),
		"bg_region": Rect2(481, 4, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type": "entity",
		"color": "yellow",
		"skill": null,
		"skill_script": null
	},
	"pizzaWheel" : {
		"attack": null,
		"health": null,
		"char_region": Rect2(17, 1, 150, 150),
		"bg_region": Rect2(332, 337, 100, 128),
		"scale": Vector2(0.3, 0.3),
		"type" : "skill",
		"color": "purple",
		"skill": "1 damage to all enemies",
		"skill_script": "res://Game/Scripts/Skills/pizza_wheel.gd"
	},
	"pizzaWheel2" : {
		"attack": null,
		"health": null,
		"char_region": Rect2(4, 31, 220, 220),
		"bg_region": Rect2(332, 337, 100, 128),
		"scale": Vector2(0.22, 0.22),
		"type" : "skill",
		"color": "purple",
		"skill": "2 damage to all enemies",
		"skill_script": "res://Game/Scripts/Skills/pizza_wheel_2.gd"
	},
	"4thWall" : {
		"attack": null,
		"health": null,
		"char_region": Rect2(5, 1, 192, 370),
		"bg_region": Rect2(332, 337, 100, 128),
		"scale": Vector2(0.18, 0.18),
		"type" : "skill",
		"color": "purple",
		"skill": "3 damage to all enemies",
		"skill_script": "res://Game/Scripts/Skills/4th_wall.gd"
	},
	"jackOBomb" : {
		"attack": null,
		"health": null,
		"char_region": Rect2(106, 203, 100, 100),
		"bg_region": Rect2(332, 337, 100, 128),
		"scale": Vector2(0.5, 0.5),
		"type" : "skill",
		"color": "purple",
		"skill": "1-3 dmg x2, single target",
		"skill_script": "res://Game/Scripts/Skills/jack_o_bomb.gd"
	},
	"megaBite" : {
		"attack": null,
		"health": null,
		"char_region": Rect2(1214, 13, 300, 300),
		"bg_region": Rect2(332, 337, 100, 128),
		"scale": Vector2(0.2, 0.2),
		"type" : "skill",
		"color": "purple",
		"skill": "3 dmg, single target",
		"skill_script": "res://Game/Scripts/Skills/mega_bite.gd"
	},
	"slasher" : {
		"attack": null,
		"health": null,
		"char_region": Rect2(6, 305, 200, 75),
		"bg_region": Rect2(332, 337, 100, 128),
		"scale": Vector2(0.2, 0.2),
		"type" : "skill",
		"color": "purple",
		"skill": "10% to instakill opponent",
		"skill_script": "res://Game/Scripts/Skills/slasher.gd"
	}
}

func build_shuffled_deck() -> Array:
	var deck: Array = []
	for card_key in CARDS.keys():
		var data = CARDS[card_key]
		if data["type"] == "entity":
			deck.append(card_key)
		elif data["type"] == "skill":
			for i in range(3):
				deck.append(card_key)
	deck.shuffle()
	return deck


func get_total_deck_size() -> int:
	var total := 0
	for card_key in CARDS.keys():
		var data = CARDS[card_key]
		if data["type"] == "entity":
			total += 1
		elif data["type"] == "skill":
			total += 3
	return total
