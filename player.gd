extends Area2D

@export var speed = 400 # How fast the player will move (pixels/sec).
@export var base_speed := 400
var speed_boost_active := false
var shield_active: bool = false
@onready var shield_timer: Timer = null
@onready var shield_sprite = $ShieldSprite2D


var screen_size # Size of the game window.

signal hit

func _ready():
	screen_size = get_viewport_rect().size
	speed = base_speed
	add_to_group("player")
	hide()
	
	if not has_node("ShieldTimer"):
		shield_timer = Timer.new()
		shield_timer.one_shot = true
		add_child(shield_timer)
		shield_timer.timeout.connect(Callable(self, "_on_shield_timeout"))
	else:
		shield_timer = $ShieldTimer
	# Asegúrate de agregar al grupo player
	add_to_group("player")


func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
	# See the note below about the following boolean assignment.
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	


func activate_speed_boost(extra_speed: int, duration: float) -> void:
	if speed_boost_active:
		return  # evita bugs si agarras dos seguidos

	speed_boost_active = true
	speed = base_speed + extra_speed

	# feedback visual (opcional pero recomendado)
	$AnimatedSprite2D.modulate = Color(0.6, 1, 0.6)

	await get_tree().create_timer(duration).timeout

	speed = base_speed
	speed_boost_active = false
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

func _on_body_entered(_body):
	# Si el objeto que colisionó es un mob (opcional: comprobar grupo o nombre)
	# y el shield está activo → consumir el escudo y no morir
	if shield_active:
		# consumir escudo inmediatamente
		shield_timer.stop()
		_on_shield_timeout()
		# opcional: feedback (partículas/sfx)
		return

	# si no hay escudo, morir como antes
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)

	# Asegúrate de resetear estado del shield (por si quedó activo)
	shield_active = false
	if shield_sprite:
		shield_sprite.visible = false
	
func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	
	# Reset de poder/escudo
	shield_active = false
	if shield_timer:
		shield_timer.stop()
	if shield_sprite:
		shield_sprite.visible = false

	speed = base_speed

func activate_shield(time: float) -> void:
	shield_active = true

	if shield_sprite:
		shield_sprite.visible = true
		# Blanco con un poco de transparencia
		shield_sprite.modulate = Color(1, 1, 1, 0.8)

	if shield_timer:
		shield_timer.stop()
		shield_timer.wait_time = time
		shield_timer.start()
	else:
		await get_tree().create_timer(time).timeout
		_on_shield_timeout()

func _on_shield_timeout() -> void:
	shield_active = false
	if shield_sprite:
		shield_sprite.visible = false
