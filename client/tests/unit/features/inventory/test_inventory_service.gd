extends GutTest
## Unit tests for
## client/features/inventory/application/inventory_service.gd, using
## a fake NakamaClientAdapter — no real network dependency.

var nakama_fake: InventoryTestNakamaClientAdapter
var service: InventoryService

func before_each() -> void:
	nakama_fake = InventoryTestNakamaClientAdapter.new()
	service = InventoryService.new(nakama_fake)

func test_fetch_inventory_caches_the_parsed_view() -> void:
	nakama_fake.inventory_response = {
		"credits": 100, "marks": 50, "ownedItems": [], "equippedSlots": {},
	}

	var view := await service.fetch_inventory_async()

	assert_not_null(view)
	assert_eq(service.current_view, view)

func test_fetch_inventory_returns_null_on_transport_failure() -> void:
	nakama_fake.inventory_response = null
	var view := await service.fetch_inventory_async()
	assert_null(view)

func test_equip_item_updates_cached_view_on_success() -> void:
	nakama_fake.inventory_response = {
		"credits": 0, "marks": 0, "ownedItems": [], "equippedSlots": {},
	}
	await service.fetch_inventory_async()

	nakama_fake.equip_response = {"success": true, "slotKey": "weapon_skin:assault_rifle"}
	await service.equip_item_async("skin.assault_rifle.nightfall")

	assert_eq(service.current_view.equipped_slots["weapon_skin:assault_rifle"], "skin.assault_rifle.nightfall")

func test_equip_item_does_not_touch_cache_on_failure() -> void:
	nakama_fake.inventory_response = {
		"credits": 0, "marks": 0, "ownedItems": [], "equippedSlots": {},
	}
	await service.fetch_inventory_async()

	nakama_fake.equip_response = {"success": false, "errorCode": "NOT_OWNED", "message": "nope"}
	await service.equip_item_async("skin.assault_rifle.nightfall")

	assert_false(service.current_view.equipped_slots.has("weapon_skin:assault_rifle"))

func test_equip_item_transport_failure_is_reported() -> void:
	nakama_fake.equip_response = null
	var result: Dictionary = await service.equip_item_async("some_item")
	assert_false(result["success"])
	assert_eq(result["errorCode"], "TRANSPORT_ERROR")

func test_purchase_item_deducts_marks_from_cached_view() -> void:
	nakama_fake.inventory_response = {
		"credits": 0, "marks": 1000, "ownedItems": [], "equippedSlots": {},
	}
	await service.fetch_inventory_async()

	nakama_fake.purchase_response = {"success": true, "itemId": "skin.assault_rifle.nightfall", "marksSpent": 800}
	await service.purchase_item_async("skin.assault_rifle.nightfall")

	assert_eq(service.current_view.marks, 200)
	assert_eq(service.current_view.owned_items.size(), 1)

func test_purchase_item_failure_does_not_change_cached_marks() -> void:
	nakama_fake.inventory_response = {
		"credits": 0, "marks": 100, "ownedItems": [], "equippedSlots": {},
	}
	await service.fetch_inventory_async()

	nakama_fake.purchase_response = {"success": false, "errorCode": "INSUFFICIENT_FUNDS", "message": "nope"}
	await service.purchase_item_async("skin.assault_rifle.nightfall")

	assert_eq(service.current_view.marks, 100)
