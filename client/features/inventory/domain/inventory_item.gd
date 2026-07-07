class_name InventoryItem
extends RefCounted
## Pure data: one owned inventory item, as returned by the
## `get_inventory` RPC. Mirrors
## server/modules/inventory_sync/src/application/get_inventory.ts's
## `InventoryView.ownedItems` shape.

var item_id: String
var display_name: String
var acquired_at: String

func _init(p_item_id: String, p_display_name: String, p_acquired_at: String) -> void:
	item_id = p_item_id
	display_name = p_display_name
	acquired_at = p_acquired_at
