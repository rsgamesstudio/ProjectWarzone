class_name FakeGuestIdentityProvider
extends GuestIdentityProvider
## Test double avoiding real filesystem access (ConfigFile persistence
## to user://) during unit tests.

var device_id_to_return: String = "fake-device-id"

func get_or_create_device_id() -> String:
	return device_id_to_return
