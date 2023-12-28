extends TextureRect

# Scene Variables
@onready var hud = %HUD
@onready var game_over = %GameOver
@onready var tile_map = %TileMap

# Game Variables
const TOTAL_MINES : int = 40
var time_elapsed: float
var remaining_mines : int
var first_click : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_elapsed += delta
	hud.get_node("Panel/StopWatch").text = str(int(time_elapsed))
	hud.get_node("Panel/RemainingMines").text = str(remaining_mines)
	
func new_game():
	first_click = true
	time_elapsed = 0
	remaining_mines = TOTAL_MINES
	tile_map.new_game()
	game_over.hide()
	get_tree().paused = false

func end_game(game_won):
	get_tree().paused = true
	game_over.show()
	if game_won:
		game_over.get_node('Panel/Label').text = "YOU WIN!"
	else:
		game_over.get_node('Panel/Label').text = "BOOM!"
	

func _on_tile_map_flag_placed():
	remaining_mines -= 1

func _on_tile_map_flag_removed():
	remaining_mines += 1

func _on_tile_map_end_game():
	end_game(false)

func _on_tile_map_game_won():
	end_game(true)

func _on_game_over_restart():
	new_game()

