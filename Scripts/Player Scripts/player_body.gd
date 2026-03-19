extends CharacterBody2D

# --- VARIABLES ---
# -- Sprite Variables --
## Animation Player
@onready var animation_player = $"Animation Player"
### Creates an array of each player form sprite
@onready var player_sprites_group_members = get_tree().get_nodes_in_group("Player Sprites")

# -- Collision Variables -- 
## Player's collision
@onready var player_collision = $"Player Collision"




# Movement
## Define trait variables
var speed : float
var jump_force : float

# --- PHYSICS LOOP ---
func _physics_process(delta: float) -> void:
	
	# Form
	formController()
	# Actions
	walk()
	jump()
	crawl()
	reach()
	climb()
	# External Forces
	gravity(delta)
	# Central function for velocity
	move_and_slide()




# --- FUNCTIONS ---

## -- FORM --
## Measurements for forms' collisions: [radius, height, position.y]
@onready var mocha_collision = player_collision.get_meta("Mocha_Collision_Measures")
@onready var pieface_collision = player_collision.get_meta("Pieface_Collision_Measures")

## Player Form Sprites
@onready var mocha_sprite = $"Mocha Sprite"
@onready var pieface_sprite = $"Pieface Sprite"

### Measurements for forms' traits: [speed, jump_force]
@onready var mocha_traits = get_meta("Mocha_Traits_Measures")
@onready var pieface_traits = get_meta("Pieface_Traits_Measures")

# Starter-Variable for stabilizer
var stabilize_form = true
# Holds current form's collison measures
var form_collision_measures : Array
# Holds current form's sprite
var form_sprite
# Holds current form's traits measures
var form_traits_measures : Array

## Player Form
var player_form = 'Mocha'
### Foribly swap player form
var force_swap : bool = false


func formController():
	
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
	
	
	# -- SWAP FORM --
	## Swap player's Form: on action or forced
	if Input.is_action_just_pressed("SWAP") or force_swap:
		# From Mocha to Pieface
		if player_form == 'Mocha':
			player_form = 'Pieface'
		# From Pieface to Mocha
		elif player_form == 'Pieface':
			player_form = 'Mocha'
		
		# - FINISH -
		# Undo force swap
		force_swap = false




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
@onready var crawl_upper_check = $"Crawl Upper-Check"
@onready var crawl_lower_check = $"Crawl Lower-Check"

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
	
	# If able to reach
	## If would be in collision, do not reach. Unless, already reaching (allowing one-way collision)
	#if climb_check.has_overlapping_bodies() and not can_reach:
		#can_reach = false
	#else:
	can_reach = true
	
	
	if Input.is_action_pressed("REACH") and can_reach:
		reaching = true
		animation_player.play("reach")
	else:
		reaching = false
	
	if reaching:
		# Add collision mask 3 to the player body
		set_collision_mask_value(3,true)
		
	else:
		stabilize_form = true
		set_collision_mask_value(3,false)

# - Climb -
@onready var climb_check = $"Climb Check"

var can_climb : bool
var climbing : bool
func climb():
	
	can_climb = true
	
	if climb_check.has_overlapping_bodies() and reaching and can_climb:
		climbing = true
	elif climb_check.has_overlapping_bodies() and not is_on_floor():
		climbing = true
	else:
		climbing = false
		
	if climbing:
		if reaching:
			velocity.y += 50
		set_collision_mask_value(4,true)
	else:
		set_collision_mask_value(4,false)



## -- EXTERNAL FORCES --
# - Gravity -
func gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
