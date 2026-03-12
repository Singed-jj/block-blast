extends Node

const GRID_SIZE := 8
const CELL_SIZE := 40

# Color Palette (from spec)
const BG_PRIMARY := Color("#4A5785")
const BG_GRID := Color("#1F2A5A")
const GRID_LINE := Color("#445599")
const SCORE_TEXT := Color("#F2F5FA")
const BEST_SCORE := Color("#F3B72B")

const BLOCK_COLORS: Array[Color] = [
	Color("#E74A4A"),  # Red
	Color("#51C95A"),  # Green
	Color("#4A7BFF"),  # Blue
	Color("#F3C93A"),  # Yellow/Orange
	Color("#7A5CE6"),  # Purple
	Color("#59C7F0"),  # Cyan
	Color("#F0A030"),  # Deep Orange
]

# Block Shapes - each is Array of Vector2i (col, row offsets)
const BLOCK_SHAPES := {
	"single": [Vector2i(0, 0)],
	"h_bar_2": [Vector2i(0, 0), Vector2i(1, 0)],
	"h_bar_3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	"h_bar_4": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	"h_bar_5": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
	"v_bar_2": [Vector2i(0, 0), Vector2i(0, 1)],
	"v_bar_3": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	"v_bar_4": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
	"v_bar_5": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)],
	"square_2x2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"square_3x3": [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	],
	"l_shape": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	"j_shape": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
	"l_shape_r": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
	"j_shape_r": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)],
	"t_shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	"t_shape_u": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"t_shape_l": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
	"t_shape_r": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	"s_shape": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"z_shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	"corner_tl": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	"corner_tr": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	"corner_bl": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"corner_br": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
}

const SHAPE_WEIGHTS := {
	"single": 5,
	"h_bar_2": 8, "v_bar_2": 8,
	"h_bar_3": 10, "v_bar_3": 10,
	"h_bar_4": 6, "v_bar_4": 6,
	"h_bar_5": 3, "v_bar_5": 3,
	"square_2x2": 8, "square_3x3": 3,
	"l_shape": 5, "j_shape": 5, "l_shape_r": 5, "j_shape_r": 5,
	"t_shape": 4, "t_shape_u": 4, "t_shape_l": 4, "t_shape_r": 4,
	"s_shape": 5, "z_shape": 5,
	"corner_tl": 6, "corner_tr": 6, "corner_bl": 6, "corner_br": 6,
}

static func get_random_shape_name() -> String:
	var total_weight := 0
	for w in SHAPE_WEIGHTS.values():
		total_weight += w
	var roll := randi() % total_weight
	var cumulative := 0
	for shape_name in SHAPE_WEIGHTS:
		cumulative += SHAPE_WEIGHTS[shape_name]
		if roll < cumulative:
			return shape_name
	return SHAPE_WEIGHTS.keys()[0]

static func get_random_color() -> Color:
	return BLOCK_COLORS[randi() % BLOCK_COLORS.size()]
