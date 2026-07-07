extends GutTest
## Unit tests for client/features/inventory/domain/inventory_view.gd.

func test_parses_a_well_formed_payload() -> void:
	var data := {
		"credits": 5000,
		"marks": 250,
		"ownedItems": [
			{"itemId": "skin.assault_rifle.field_issue", "displayName": "VK-12 Field Issue", "acquiredAt": "2026-01-01T00:00:00Z"},
		],
		"equippedSlots": {"weapon_skin:assault_rifle": "skin.assault_rifle.field_issue"},
	}

	var view := InventoryView.from_dict(data)

	assert_not_null(view)
	assert_eq(view.credits, 5000)
	assert_eq(view.marks, 250)
	assert_eq(view.owned_items.size(), 1)
	assert_eq(view.owned_items[0].display_name, "VK-12 Field Issue")
	assert_eq(view.equipped_slots["weapon_skin:assault_rifle"], "skin.assault_rifle.field_issue")

func test_parses_empty_inventory_correctly() -> void:
	var data := {"credits": 0, "marks": 0, "ownedItems": [], "equippedSlots": {}}
	var view := InventoryView.from_dict(data)

	assert_not_null(view)
	assert_eq(view.owned_items.size(), 0)

func test_returns_null_for_malformed_payload_missing_fields() -> void:
	var view := InventoryView.from_dict({"credits": 100})
	assert_null(view)
