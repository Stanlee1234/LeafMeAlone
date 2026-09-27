class_name HUD
extends Control

@export var LeafAmount: Label

func _ready() -> void:
	# Initialize the display with current balance
	update_leaf_amount_label(Global.leaves)
	
	# Listen for any currency changes from anywhere in the game
	Global.leaves_changed.connect(update_leaf_amount_label)

func update_leaf_amount_label(number: int) -> void:
	if LeafAmount:
		LeafAmount.text = "x " + str(number)
