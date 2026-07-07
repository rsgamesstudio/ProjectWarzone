class_name InventoryService
extends RefCounted
## Orchestrates inventory fetch/equip/purchase against
## NakamaClientAdapter's RPC wrappers. Application layer per
## ARCHITECTURE.md §3 — coordinates domain (InventoryView,
## InventoryItem) and infrastructure (NakamaClientAdapter), no
## scene-tree dependency, fully testable with a fake adapter.

var _nakama_client: NakamaClientAdapter

var current_view: InventoryView = null

func _init(nakama_client: NakamaClientAdapter) -> void:
	_nakama_client = nakama_client

## Fetches and caches the current inventory view. Returns null on
## transport failure or a malformed response (same as
## InventoryView.from_dict's contract) — callers should treat null as
## "could not load inventory right now", not "empty inventory".
func fetch_inventory_async() -> InventoryView:
	var raw = await _nakama_client.get_inventory_async()
	if raw == null:
		return null

	var view := InventoryView.from_dict(raw)
	if view != null:
		current_view = view
	return view

## Equips an owned item, and refreshes the cached view on success so
## `current_view.equipped_slots` immediately reflects the change
## without a second round trip.
func equip_item_async(item_id: String) -> Dictionary:
	var response = await _nakama_client.equip_item_async(item_id)
	if response == null:
		return {"success": false, "errorCode": "TRANSPORT_ERROR", "message": "Could not reach the server."}

	if response.get("success", false) and current_view != null:
		current_view.equipped_slots[response["slotKey"]] = item_id

	return response

## Purchases an item, refreshing the cached view's currency/owned-items
## on success.
func purchase_item_async(item_id: String) -> Dictionary:
	var response = await _nakama_client.purchase_item_async(item_id)
	if response == null:
		return {"success": false, "errorCode": "TRANSPORT_ERROR", "message": "Could not reach the server."}

	if response.get("success", false) and current_view != null:
		current_view.marks -= int(response.get("marksSpent", 0))
		current_view.owned_items.append(InventoryItem.new(item_id, item_id, ""))

	return response
