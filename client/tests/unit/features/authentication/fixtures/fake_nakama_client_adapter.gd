class_name FakeNakamaClientAdapter
extends NakamaClientAdapter
## Test double for NakamaClientAdapter. Overrides `_init` WITHOUT
## calling `super()` specifically to skip the real constructor's
## `Nakama.create_client(...)` call — that would depend on the `Nakama`
## SDK autoload being present, which is unnecessary ceremony for a
## pure application-layer unit test. This is valid GDScript: `_init`
## has no required parent arguments, so overriding it without `super()`
## simply skips the parent's initialization logic entirely.

var guest_result: AuthResult = AuthResult.failure("not configured")
var google_result: AuthResult = AuthResult.failure("not configured")
var claim_response: Variant = null

func _init() -> void:
	pass

func authenticate_guest_async(_device_id: String) -> AuthResult:
	return guest_result

func authenticate_google_async(_firebase_id_token: String) -> AuthResult:
	return google_result

func claim_nickname_async(_nickname: String) -> Variant:
	return claim_response
