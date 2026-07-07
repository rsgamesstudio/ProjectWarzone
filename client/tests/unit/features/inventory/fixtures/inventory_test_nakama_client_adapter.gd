class_name InventoryTestNakamaClientAdapter
extends NakamaClientAdapter
## Test double for NakamaClientAdapter, scoped to inventory tests.
## Overrides `_init` without calling `super()` to skip the real
## constructor's `Nakama.create_client(...)` call — same rationale as
## the other feature-scoped fakes in this project (e.g.
## authentication's and character_controller's).

var inventory_response: Variant = null
var equip_response: Variant = null
var purchase_response: Variant = null

var last_equipped_item_id: String = ""
var last_purchased_item_id: String = ""

func _init() -> void:
	pass

func get_inventory_async() -> Variant:
	return inventory_response

func equip_item_async(item_id: String) -> Variant:
	last_equipped_item_id = item_id
	return equip_response

func purchase_item_async(item_id: String) -> Variant:
	last_purchased_item_id = item_id
	return purchase_response
