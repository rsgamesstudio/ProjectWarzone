class_name FakeFirebaseWebIdentityProvider
extends FirebaseWebIdentityProvider
## Test double avoiding any real JavaScriptBridge/browser dependency.
## Overriding an `await`-using method with a plain synchronous method
## is valid GDScript — `await` on a non-signal expression simply
## resolves to that expression's value immediately.

var supported: bool = true
var google_id_token_to_return: String = ""
var email_id_token_to_return: String = ""
var error_to_return: String = "fake error"

func is_supported_on_this_platform() -> bool:
	return supported

func sign_in_with_google_async() -> String:
	return google_id_token_to_return

func sign_in_with_email_async(_email: String, _password: String, _create_if_missing: bool) -> String:
	return email_id_token_to_return

func get_last_error() -> String:
	return error_to_return
