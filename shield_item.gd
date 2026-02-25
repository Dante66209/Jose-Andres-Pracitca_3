extends Area2D

@export var duration := 5.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("powerups")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.activate_shield(duration)
		queue_free()
