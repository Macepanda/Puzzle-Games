extends TileMap

# Grid Variables
const ROWS : int = 14
const COLS : int = 15
const CELL_SIZE : int = 50

# Tilemap Variables
const TILE_ID : int = 0

# Layer Variables
const MINE_LAYER : int = 0
const NUMBER_LAYER : int = 1
const GRASS_LAYER : int = 2
const FLAG_LAYER : int = 3
const HOVER_LAYER : int = 4

# Atlas Coordinates
const MINE_ATLAS := Vector2i(4,0)
const FLAG_ATLAS := Vector2i(5,0)
const HOVER_ATLAS := Vector2i(6,0)
var numbers_atlas : Array = generate_number_atlas()

# Array to store mine coordinates
var mine_coords := []

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	highlight_cell()
	
func generate_number_atlas():
	var array := []
	for number in range(8):
		array.append(Vector2i(number, 1))
	return array
	
func new_game():
	clear()
	mine_coords.clear()
	generate_mines()
	generate_numbers()
	#generate_grass()
	
func generate_mines():
	for mines in range(get_parent().TOTAL_MINES):
		var mine_position = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		while mine_coords.has(mine_position):
			mine_position = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		mine_coords.append(mine_position)
		# Add mine to tilemap
		set_cell(MINE_LAYER, mine_position, TILE_ID, MINE_ATLAS)
		
func generate_numbers():
	for empty_cell in get_empty_cells():
		var mine_count : int = 0
		for cell in get_all_surrounding_cells(empty_cell):
			# Check if there is a mine in the cell
			if is_mine(cell):
				mine_count += 1
		# Once counted, add the number cell to the tilemap
		if mine_count > 0:
			set_cell(NUMBER_LAYER, empty_cell, TILE_ID, numbers_atlas[mine_count - 1])

func generate_grass():
	for row in range(ROWS):
		for col in range (COLS):
			var toggle = ((row + col) % 2)
			set_cell(GRASS_LAYER, Vector2i(col, row), TILE_ID, Vector2i(3 - toggle,0))
	
func get_empty_cells():
	var empty_cells := []
	# Iterate over grid
	for row_num in range(ROWS):
		for col_num in range(COLS):
			# Check if the cell is empty and add it to the array 
			if not is_mine(Vector2i(col_num, row_num)):
				empty_cells.append(Vector2i(col_num, row_num))
	return empty_cells

func get_all_surrounding_cells(middle_cell):
	var surrounding_cells := []
	var target_cell
	for row in range(3):
		for col in range(3):
			target_cell = middle_cell + Vector2i(col - 1, row - 1)
			# Skip cell if it is the middle one
			if target_cell != middle_cell:
				# Check that the cell is on the grid
				if (target_cell.x >= 0 and target_cell.x <= COLS - 1
					and target_cell.y >= 0 and target_cell.y <= ROWS - 1):
					surrounding_cells.append(target_cell)
	return surrounding_cells

func highlight_cell():
	var mouse_position := local_to_map(get_local_mouse_position())
	# Clear hover tiles and add a new one under the mouse
	clear_layer(HOVER_LAYER)
	# Hover over grass cells
	if is_grass(mouse_position):
		set_cell(HOVER_LAYER, mouse_position, TILE_ID, HOVER_ATLAS)
		
	
# Helper Functions
func is_mine(cell_position):
	return get_cell_source_id(MINE_LAYER, cell_position) != -1
	
func is_grass(cell_position):
	return get_cell_source_id(GRASS_LAYER, cell_position) != -1
	
	
	
	
	
	
	
	
