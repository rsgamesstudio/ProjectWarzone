class_name GuestIdentityProvider
extends RefCounted
## Provides a stable, locally-generated device ID for Guest login.
##
## Deliberately does NOT use Godot's OS.get_unique_id(): that API is
## unreliable across platforms in Godot 4 (notably returning an empty
## string on several platforms due to OS-level privacy restrictions,
## particularly on mobile). Instead, we generate a random ID
## ourselves on first run and persist it locally — this is the same
## approach most mobile games use for guest/device-based login.
##
## The ID persists in `user://` (sandboxed per-app storage — the
## correct location for this on both Android and iOS export
## templates), so reinstalling the app WILL generate a new guest
## identity, which is expected and consistent with how "guest"
## accounts work industry-wide (they are not tied to a physical
## device beyond a single install).

const SAVE_PATH: String = "user://guest_device_id.cfg"
const CONFIG_SECTION: String = "guest"
const CONFIG_KEY: String = "device_id"

## Returns the persisted device ID, generating and saving a new one on
## first call. Safe to call repeatedly — subsequent calls return the
## same ID until the save file is deleted (e.g. app reinstall).
func get_or_create_device_id() -> String:
	var config := ConfigFile.new()
	var load_result := config.load(SAVE_PATH)

	if load_result == OK and config.has_section_key(CONFIG_SECTION, CONFIG_KEY):
		var existing: String = config.get_value(CONFIG_SECTION, CONFIG_KEY)
		if not existing.is_empty():
			return existing

	var new_id := _generate_device_id()
	config.set_value(CONFIG_SECTION, CONFIG_KEY, new_id)
	var save_result := config.save(SAVE_PATH)
	if save_result != OK:
		push_error("GuestIdentityProvider: failed to persist device ID (error %d). A new ID will be generated every launch until this is fixed." % save_result)

	return new_id

func _generate_device_id() -> String:
	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(16)
	return random_bytes.hex_encode()
