extends Node2D


onready var animation_player : AnimationPlayer = $AnimationPlayer
onready var label : RichTextLabel = $Label


func _ready() -> void:
	$AnimationPlayer.play("Toast")
