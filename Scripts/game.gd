extends Node2D



# --- PROCESS LOOP ---
func _process(_delta):
	cameraSwap()


# --- FUNCTIONS ---
## Player Variable
@onready var player_body = $"Player Body"



# -- Camera Swap --
# Array of each camera node
## Used to move nodes after start. To keep tidy when structuring levels.
@onready var camera_list = $"Environment/Camera List".get_children()
# Array of cameras
var camera_bank : Array
# Player-Body's Camera-Check
@onready var player_camera_check = $"Player Body/Checks/Camera Check"
# Stores current camera
var current_camera : Camera2D

func cameraSwap():
	# Move all cameras as children of the Player Body
	for camera in camera_list:
		camera.reparent(player_body)
		camera_bank.append(camera)
	
	# Identifies current camera
	for camera in camera_bank:
		if camera.is_current:
			current_camera = camera
	
	# Swap camera
	if Input.is_action_just_pressed("SWAP"):
		for camera in camera_bank:
			if camera == current_camera:
				camera.enabled = true
			else:
				camera.enabled = false
	
