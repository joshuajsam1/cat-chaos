extends Node

# ---------------------------------------------------------------------------
# ChaosInteractable — base "interface" for all destructible objects.
# Attach to the root node of any object that cats can interact with.
# Subclasses override the on_interact / on_hold_start / on_hold_tick methods.
# ---------------------------------------------------------------------------

# Which player has claimed this object (−1 = unclaimed)
var claimed_by: int = -1
var _base_points: int = 0

func _ready() -> void:
	# Ensure the parent (the physical node) is in the group
	get_parent().add_to_group("chaos_interactable")

# Called on a single tap interact
func on_interact(_cat: Node) -> void:
	pass

# Called once when interact is held long enough
func on_hold_start(_cat: Node) -> void:
	pass

# Called every frame while interact is held
func on_hold_tick(_cat: Node, _delta: float) -> void:
	pass

# Called by ClaimTerritory to try to steal this object
func try_steal(new_owner: int) -> bool:
	if claimed_by == new_owner:
		return false
	var old_owner := claimed_by
	claimed_by = new_owner
	_on_stolen(new_owner, old_owner)
	return true

func claim(player_idx: int) -> void:
	claimed_by = player_idx
	_on_claimed(player_idx)

func _on_claimed(_player_idx: int) -> void:
	pass

func _on_stolen(_new_owner: int, _old_owner: int) -> void:
	pass
