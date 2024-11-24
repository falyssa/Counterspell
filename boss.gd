extends CharacterBody2D

# Attack settings
const ATTACK_DURATION = 1.0  # Duration of attack animation in seconds
const ATTACK_SPEED = 500     # Speed during attack movement
const DAMAGE_AMOUNT = 20     # Damage dealt to player per hit
const DAMAGE_COOLDOWN = 1.0  # Cooldown between damage hits in seconds

# Position settings
const LEFT_BOUNDARY = Vector2(-1200.424, 834.4903)
const RIGHT_BOUNDARY = Vector2(1000.925, 834.4252)
const POSITION_THRESHOLD = 10.0  # Distance threshold for reaching target

# Direction control
var current_direction = -1  # Start moving left
var target_position = LEFT_BOUNDARY  # Initial target

# Health settings
var max_health = 100
var current_health = max_health

# Damage control
var can_deal_damage = true  # Flag to control damage cooldown

# Node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

func _ready():
	# Setup hitbox
	if !hitbox:
		hitbox = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(100, 150)  # Adjust size as needed
		collision_shape.shape = shape
		hitbox.add_child(collision_shape)
		add_child(hitbox)
		hitbox.name = "Hitbox"
		
		# Connect hitbox signal for dealing damage
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		
	# Setup hurtbox
	if !hurtbox:
		hurtbox = Area2D.new()
		var hurt_collision = CollisionShape2D.new()
		var hurt_shape = RectangleShape2D.new()
		hurt_shape.size = Vector2(100, 150)  # Adjust size as needed
		hurt_collision.shape = hurt_shape
		hurtbox.add_child(hurt_collision)
		add_child(hurtbox)
		hurtbox.name = "Hurtbox"
		
	# Connect hurtbox signal
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# Set initial position
	global_position = RIGHT_BOUNDARY
	target_position = LEFT_BOUNDARY
	
	# Start attacking animation immediately
	sprite.play("attack")

func _physics_process(delta):
	# Always move and attack
	handle_constant_attack(delta)
	
	# Check if reached target position to switch direction
	if has_reached_target():
		switch_direction()

func has_reached_target() -> bool:
	return global_position.distance_to(target_position) < POSITION_THRESHOLD

func handle_constant_attack(delta):
	# Calculate direction to target
	var direction_to_target = (target_position - global_position).normalized()
	
	# Update position while attacking
	global_position += direction_to_target * ATTACK_SPEED * delta
	
	# Update sprite direction
	sprite.flip_h = direction_to_target.x > 0
	current_direction = 1 if direction_to_target.x > 0 else -1

func switch_direction():
	# Switch target position while maintaining attack
	target_position = RIGHT_BOUNDARY if target_position == LEFT_BOUNDARY else LEFT_BOUNDARY
	
	# Ensure attack animation keeps playing
	if !sprite.is_playing():
		sprite.play("attack")

func _on_hitbox_area_entered(area):
	# Check if the area belongs to the player and we can deal damage
	if area.name == "playerhurtbox" and can_deal_damage:
		deal_damage_to_player(area)

func deal_damage_to_player(player_area):
	# Get the player node (assuming the hurtbox is a child of the player)
	var player = player_area.get_parent()
	
	# Check if the player has a take_damage method
	if player.has_method("take_damage"):
		player.take_damage(DAMAGE_AMOUNT)
		
		# Start damage cooldown
		can_deal_damage = false
		await get_tree().create_timer(DAMAGE_COOLDOWN).timeout
		can_deal_damage = true

func _on_hurtbox_area_entered(area):
	if area.name == "swordhitbox":
		take_damage(10)  # 10 damage per hit

func take_damage(amount):
	current_health -= amount
	print("Boss hit! Health: ", current_health)
	
	# Visual feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	# Check if boss is defeated
	if current_health <= 0:
		die()

func die():
	print("Boss defeated!")
	queue_free()  # Removes the boss from the scene
	get_tree().change_scene_to_file("res://Counterspell/scenes/game.tscn")
