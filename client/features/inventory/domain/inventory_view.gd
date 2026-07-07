class_name InventoryView
extends RefCounted
## Pure data: the full inventory view returned by the `get_inventory`
## RPC — currency balances, owned items, and equipped loadout slots.

var credits: int
var marks: int
var owned_items: Array[InventoryItem]
var equipped_slots: Dictionary # slot_key (String) -> item_id (String)

func _init(p_credits: int, p_marks: int, p_owned_items: Array[InventoryItem], p_equipped_slots: Dictionary) -> void:
	credits = p_credits
	marks = p_marks
	owned_items = p_owned_items
	equipped_slots = p_equipped_slots

## Parses the raw Dictionary returned by
## NakamaClientAdapter.get_inventory_async() into a typed InventoryView.
## Returns null if the payload is malformed rather than raising, since
## this is parsing untrusted-ish network data.
static func from_dict(data: Dictionary) -> InventoryView:
	if not data.has("credits") or not data.has("marks") or not data.has("ownedItems") or not data.has("equippedSlots"):
		return null

	var items: Array[InventoryItem] = []
	for raw_item in data["ownedItems"]:
		items.append(InventoryItem.new(
			raw_item.get("itemId", ""),
			raw_item.get("displayName", ""),
			raw_item.get("acquiredAt", "")
		))

	return InventoryView.new(data["credits"], data["marks"], items, data["equippedSlots"])
