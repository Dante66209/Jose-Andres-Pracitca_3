extends Node

@export var mob_scene: PackedScene
@onready var powerup_timer = $PowerUpTimer
@onready var player = $Player
@export var shield_scene: PackedScene
@export var spawn_interval: float = 10.0  # cada cuánto intentar spawnear
@export var powerup_scenes: Array[PackedScene]

var score = 0

func _on_score_timer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
	
func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()
	$PowerUpTimer.stop()
	clear_powerups() 
	

func clear_powerups() -> void:
	for p in get_tree().get_nodes_in_group("powerups"):
		p.queue_free()


func new_game():
	score = 0
	get_tree().call_group("mobs", "queue_free") 
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$Music.play()
	$PowerUpTimer.start() 
	
	
	
func _ready():
	pass
	randomize()
	$PowerUpTimer.timeout.connect(spawn_powerup)
	$LifetimeTimer.timeout.connect(spawn_powerup)
	


#powerup Shield Item-----------------------------------------------------------

func spawn_powerup() -> void:
	if powerup_scenes.is_empty():
		print("⚠ powerup_scenes vacío")
		return

	var idx := randi() % powerup_scenes.size()
	var pu := powerup_scenes[idx].instantiate()

	const GAME_WIDTH := 480
	const GAME_HEIGHT := 720
	var margin := 32

	pu.global_position = Vector2(
		randf_range(margin, GAME_WIDTH - margin),
		randf_range(margin, GAME_HEIGHT - margin)
	)

	add_child(pu)
