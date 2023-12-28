extends TileMap

signal flag_placed
signal flag_removed
signal end_game
signal game_won

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

# Toggle Variable to scan nearby mines
var scanning := false

# Array to store mine coordinates
var mine_coords := []

var in_game = false

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	highlight_cell()
	# scan mines
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and 
	Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		var scan_position := local_to_map(get_local_mouse_position())
		if not is_grass(scan_position):
			if not scanning:
				scan_mines(scan_position)
				scanning = true
	else:
		scanning = false

func _input(event):
	if event is InputEventMouseButton:
		var map_position := local_to_map(get_local_mouse_position())
		# Check if mouse is on game board
		if map_position.x <= COLS and map_position.y <= ROWS:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#check that there isno flag
				if not is_flag(map_position):
					# Check if it is a mine
					if is_mine(map_position):
						#  Check if it is the first click 
						if get_parent().first_click: 
							move_mine(map_position)
							generate_numbers()
							process_left_click(map_position)
						else:
							show_mines()
							end_game.emit()
					else:
						process_left_click(map_position)
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				process_right_click(map_position)

func process_left_click(cell_position):
	var revealed_cells := []
	var cells_to_reveal := [cell_position]
	get_parent().first_click = false
	while not cells_to_reveal.is_empty():
		#clear cell and markit cleared
		erase_cell(GRASS_LAYER, cells_to_reveal[0])
		revealed_cells.append(cells_to_reveal[0])
		# if the cell had a flag, then remove it
		if is_flag(cells_to_reveal[0]):
			erase_cell(FLAG_LAYER, cells_to_reveal[0])
			flag_removed.emit()
		if not is_number(cells_to_reveal[0]):
			cells_to_reveal = reveal_surrounding_cells(cells_to_reveal, revealed_cells)
		# removed processed cell from array
		cells_to_reveal.erase(cells_to_reveal[0])
	# Checked if all the number cells are revealed
	var all_cleared := true
	for cell in get_used_cells(NUMBER_LAYER):
		if is_grass(cell):
			all_cleared	= false
	if all_cleared:
		game_won.emit()

func process_right_click(cell_position):
	# Check if it is a grass cell
	if is_grass(cell_position):
		if is_flag(cell_position):
			erase_cell(FLAG_LAYER, cell_position)
			flag_removed.emit()
		else:
			set_cell(FLAG_LAYER, cell_position, TILE_ID, FLAG_ATLAS)
			flag_placed.emit()

func new_game():
	clear()
	mine_coords.clear()
	generate_mines()
	generate_numbers()
	generate_grass()

func generate_number_atlas():
	var array := []
	for number in range(8):
		array.append(Vector2i(number, 1))
	return array
	
func generate_mines():
	for mines in range(get_parent().TOTAL_MINES):
		var mine_position = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		while mine_coords.has(mine_position):
			mine_position = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		mine_coords.append(mine_position)
		# Add mine to tilemap
		set_cell(MINE_LAYER, mine_position, TILE_ID, MINE_ATLAS)
		
func generate_numbers():
	# Clear previous numbers in case the mine was moved
	clear_layer(NUMBER_LAYER)
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

func reveal_surrounding_cells(cells_to_reveal, revealed_cells):
	for cell in get_all_surrounding_cells(cells_to_reveal[0]):
		# check the cell is not already revealed
		if not revealed_cells.has(cell):
			if not cells_to_reveal.has(cell):
				cells_to_reveal.append(cell)
	return cells_to_reveal

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
	else:
		# If the cell is cleared, only hover over number cells
		if is_number(mouse_position):
			set_cell(HOVER_LAYER, mouse_position, TILE_ID, HOVER_ATLAS)

func scan_mines(cell_position):
	var unflagged_mines : int = 0
	for cell in get_all_surrounding_cells(cell_position):
		if is_flag(cell) and not is_mine(cell):
			end_game.emit()
			show_mines()
		if is_mine(cell) and not is_flag(cell):
			unflagged_mines += 1
	if unflagged_mines == 0:
		for cell in reveal_surrounding_cells([cell_position], []):
			if not is_mine(cell):
				process_left_click(cell)
			

func show_mines():
	for mine in mine_coords:
		if is_mine(mine):
			erase_cell(GRASS_LAYER, mine)

func move_mine(old_cell_position):
	while get_parent().first_click == true:
		var mine_position = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		if not is_mine(mine_position):
			mine_coords[mine_coords.find(old_cell_position)] = mine_position
			# Remove old mine
			erase_cell(MINE_LAYER, old_cell_position)
			# Add new mine
			set_cell(MINE_LAYER, mine_position, TILE_ID, MINE_ATLAS)
			get_parent().first_click = false

# Helper Functions
func is_mine(cell_position):
	return get_cell_source_id(MINE_LAYER, cell_position) != -1
	
func is_number(cell_position):
	return get_cell_source_id(NUMBER_LAYER, cell_position) != -1
	
func is_grass(cell_position):
	return get_cell_source_id(GRASS_LAYER, cell_position) != -1
	
func is_flag(cell_position):
	return get_cell_source_id(FLAG_LAYER, cell_position) != -1
