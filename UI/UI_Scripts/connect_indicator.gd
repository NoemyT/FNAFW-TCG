extends Label

## Animated dots shown while a PvP connection attempt is in progress.
##
## Gives the player feedback that the game is still searching, since hosting and
## joining can both take a while with no other visible sign of activity.

const DOT_INTERVAL = 0.4

var dot_count := 0
var timer: Timer

func _ready() -> void:
	visible = false
	timer = Timer.new()
	timer.wait_time = DOT_INTERVAL
	timer.timeout.connect(_on_tick)
	add_child(timer)


## Shows the indicator and begins the animation.
func start():
	dot_count = 0
	text = ""
	visible = true
	timer.start()


## Hides the indicator, called when the attempt succeeds, fails or is cancelled.
func stop():
	visible = false
	timer.stop()


## Cycles between one and three dots.
func _on_tick() -> void:
	dot_count = (dot_count % 3) + 1
	text = ".".repeat(dot_count)
