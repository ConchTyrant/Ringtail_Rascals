extends CharacterBody2D




# --- PHYSICS LOOP ---
func _physics_process(delta: float) -> void:
	
	# Form
	formStabilizer()
	formSwap()
	# Actions
	walk()
	jump()
	crawl()
	reach()
	climb()
	grab()
	# External Forces
	gravity(delta)
	# Central function for velocity
	move_and_slide()




# --- FUNCTIONS ---

## - FORM SWAP -

## Player's collision
@onready var player_collision = $"Player Collision"

## Animation Player
@onready var animation_player = $"Player Sprite/Animation Player"
### Creates an array of each player form sprite
@onready var player_sprites_group_members = get_tree().get_nodes_in_group("Player Sprites")

## Measurements for forms' collisions: [radius, height, position.y]
@onready var mocha_collision = player_collision.get_meta("Mocha_Collision_Measures")
@onready var pieface_collision = player_collision.get_meta("Pieface_Collision_Measures")

## Player Form Sprites
@onready var mocha_sprite = $"Player Sprite/Mocha Sprite"
@onready var pieface_sprite = $"Player Sprite/Pieface Sprite"

### Measurements for forms' traits: [speed, jump_force]
@onready var mocha_traits = get_meta("Mocha_Traits_Measures")
@onready var pieface_traits = get_meta("Pieface_Traits_Measures")

## Define trait variables
var speed : float
var jump_force : float

# Starter-Variable for stabilizer
var stabilize_form = true
# Holds current form's collison measures
var form_collision_measures : Array
# Holds current form's sprite
var form_sprite
# Holds current form's traits measures
var form_traits_measures : Array


func formStabilizer():
	
	## -- FORM STABILIZER --
	# Reset the player form (collision, sprite, traits)
	if stabilize_form:
		
		# - IDENTIFY -
		# Identify form and grab measures
		if player_form == 'Mocha':
			form_collision_measures = mocha_collision
			form_sprite = mocha_sprite
			form_traits_measures = mocha_traits
			# Set the crawl upper-check high
			crawl_upper_check.get_child(0).position.y = -7
		elif player_form == 'Pieface':
			form_collision_measures = pieface_collision
			form_sprite = pieface_sprite
			form_traits_measures = pieface_traits
			# Set the crawl upper-check low (to only crawl when needed)
			crawl_upper_check.get_child(0).position.y = -3
		
		
		# - SET -
		# Set collision
		player_collision.shape.radius = form_collision_measures[0]
		player_collision.shape.height = form_collision_measures[1]
		player_collision.position.y = form_collision_measures[2]
		
		
		# Set sprite
		## Turn off visibility for all player sprites
		for sprite in player_sprites_group_members:
			sprite.visible = false
		## Turn on the current player sprite
		form_sprite.visible = true
		
		# Set traits
		speed = form_traits_measures[0]
		jump_force = form_traits_measures[1]
		
		# - FINISH -
		# Reset starter-variable
		stabilize_form = false




# - SWAP FORM -
@onready var swap_check = $"Checks/Swap Check"
@onready var swap_signifier = $"Swap Signifier"
# Player's current form
var player_form : String = 'Mocha'

# If able to swap
var can_swap : bool
# Activates swapping of form
var is_swap : bool 

func formSwap():
	
	# Checks if able to swap
	## If swap_check overlaps with Swap layer (4)
	if swap_check.has_overlapping_areas():
		can_swap = true
	else:
		can_swap = false
	
	# Determines swap-signifier's visibility
	if can_swap:
		swap_signifier.visible = true
	else:
		swap_signifier.visible = false
	
	
	## Swap player's Form on action
	if Input.is_action_just_pressed("SWAP") and can_swap:
		# From Mocha to Pieface
		if player_form == 'Mocha':
			player_form = 'Pieface'
		# From Pieface to Mocha
		elif player_form == 'Pieface':
			player_form = 'Mocha'
		
		# - FINISH -
		# Undo force swap




## -- MOVEMENT --

# - Walk and Turn -
func walk():
	var direction := Input.get_axis("LEFT","RIGHT")
	if direction:
		velocity.x = direction * speed
		# Only play walk animation if not moving vertically
		if not velocity.y:
			animation_player.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		# Only play idle animation if not moving
		if not velocity:
			animation_player.play("idle")


# Turn Animation
## Turn each player sprite when direction goes to the left, and vice versa
	# Detects when moving right
	if direction > 0:
		get_tree().set_group("Player Sprites","flip_h", false)
	
	# Detects when moving left
	elif direction < 0:
		get_tree().set_group("Player Sprites","flip_h", true)




# - Jump -
func jump():
	# -- Jump Conditions --
	## If true, allows the player to jump
	var can_jump : bool
	## Has to be on the floor
	if not is_on_floor():
		can_jump = false
	## Cannot be crawling
	elif crawling:
		can_jump = false
	else:
		can_jump = true
	
	# -- Jump Action --
	if Input.is_action_just_pressed("JUMP") and can_jump:
		velocity.y = jump_force
		animation_player.play("jump")




# - Crawl -
## Crawl Check
@onready var crawl_upper_check = $"Checks/Crawl Upper-Check"
@onready var crawl_lower_check = $"Checks/Crawl Lower-Check"

## Determines if player is crawling or not
var crawling : bool

func crawl():
	# If true, the crawl action can be performed
	var can_crawl : bool
	if not is_on_floor():
		can_crawl = false
	elif reaching:
		can_crawl = false
	else:
		can_crawl = true
	
	# -- Crawl Check --
	## Enter crawl action
	if crawl_upper_check.has_overlapping_bodies() and not crawl_lower_check.has_overlapping_bodies() and can_crawl:
		crawling = true
	## Stays in crawl action until space is available
	elif crawl_upper_check.has_overlapping_bodies() and crawling:
		crawling = true
	## Exit crawl action
	else:
		crawling = false
	
	
	# -- Crawl Collision --
	var crawl_collision_radius = form_collision_measures[0] / 2
	var crawl_collision_height = form_collision_measures[1] / 2
	var crawl_collision_y_position = form_collision_measures[2] / 2
	
	if crawling:
		# Set collision as crawl collision
		player_collision.shape.radius = crawl_collision_radius
		player_collision.shape.height = crawl_collision_height
		player_collision.position.y = crawl_collision_y_position
		# Play crawl animation
		animation_player.play("crawl")
		
		# Slow the player's speed
		var crawl_speed = form_traits_measures[0] * 0.7
		speed = crawl_speed
	else:
		stabilize_form = true



## - Reach --
var can_reach : bool
var reaching : bool

func reach():
	
	# CAN REACH FUNC
	if not is_on_floor():
		can_reach = false
	else:
		can_reach = true
	
	
	# REACH TOGGLE
	if Input.is_action_pressed("UP") and can_reach:
		reaching = true
	elif reaching and not is_on_floor():
		reaching = true
	else:
		reaching = false
	
	
	# REACH FUNC
	if reaching:
		animation_player.play("reach")
		
		# Add collision mask 3 to the player body
		set_collision_mask_value(3,true)
		
	else:
		if not is_on_floor():
			set_collision_mask_value(3,true)
		else:
			set_collision_mask_value(3,false)

# - Climb -
@onready var ladder_check = $"Checks/Ladder Check"

var can_climb : bool
var climbing : bool

func climb():
	
	if not reaching:
		can_climb = false
	else:
		can_climb = true
	
	
	
	
	
	
	
	# - CLIMB FUNC -
	if ladder_check.has_overlapping_areas() and can_climb:
		climbing = true
	elif ladder_check.has_overlapping_areas() and not is_on_floor() and climbing:
		climbing = true
	else:
		climbing = false
		
	if climbing:
		animation_player.play("climb")
		
		
		# - CLIMB MOVEMENT -
		# Slow lateral movement
		velocity.x = velocity.x / 4
		
		# Y-Axis movement
		if Input.is_action_pressed("UP"):
			velocity.y = -50
		elif Input.is_action_pressed("DOWN"):
			velocity.y = 50
		else:
			velocity.y = 0




func grab():
	pass




## -- EXTERNAL FORCES --
# - Gravity -
func gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
