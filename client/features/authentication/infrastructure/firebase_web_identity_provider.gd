class_name FirebaseWebIdentityProvider
extends RefCounted
## Google/Email login via the Firebase Web SDK, for HTML5 exports
## only. Bridges to `web/firebase_auth_shim.js` via
## `JavaScriptBridge` — Godot's documented mechanism for calling into
## page JavaScript from GDScript.
##
## IMPORTANT SCOPE NOTE: this provider only works when the game is
## running as an HTML5/Web export. Native Android/iOS builds need
## Google/Email login through Firebase's native Android (Kotlin/Java)
## and iOS (Swift) SDKs instead, which requires a genuine Godot
## native plugin (a GDExtension with per-platform build steps,
## Gradle/CocoaPods integration, etc.) — that is real, substantial,
## platform-specific engineering that cannot be produced as a handful
## of GDScript/text files, and is intentionally NOT claimed as done
## here. It is tracked as explicit follow-up work before Android/iOS
## builds can ship Google/Email login (Guest login has no such
## limitation — see guest_identity_provider.gd, which works
## everywhere).
##
## This file's correctness could not be executed/verified in the
## development sandbox this was written in (no browser + Godot Web
## export pipeline available) — verify against a real HTML5 export
## before relying on it. See the Phase 4 report's testing checklist.
##
## Result encoding: each signal below carries a single String payload
## rather than separate success/error signals or multi-argument
## signals, specifically so callers can use GDScript's well-defined
## single-argument `await some_signal` form without relying on
## multi-argument signal/await packing behavior. A leading "ERROR:"
## prefix marks a failure; anything else is the Firebase ID token.

signal google_sign_in_result(payload: String)
signal email_sign_in_result(payload: String)

const ERROR_PREFIX: String = "ERROR:"

var _last_error: String = ""

func is_supported_on_this_platform() -> bool:
	return OS.get_name() == "Web"

func get_last_error() -> String:
	return _last_error

## Returns the Firebase ID token on success, or an empty string on
## failure (check get_last_error() for the reason). Only call this
## after confirming is_supported_on_this_platform().
func sign_in_with_google_async() -> String:
	if not is_supported_on_this_platform():
		push_error("FirebaseWebIdentityProvider: sign_in_with_google_async called on a non-Web platform.")
		return ""

	var window_interface = JavaScriptBridge.get_interface("window")
	window_interface.warzoneGoogleSuccess = JavaScriptBridge.create_callback(_on_google_success)
	window_interface.warzoneGoogleError = JavaScriptBridge.create_callback(_on_google_error)

	JavaScriptBridge.eval(
		"WarzoneFirebaseAuth.signInWithGoogle(window.warzoneGoogleSuccess, window.warzoneGoogleError);",
		true
	)

	var payload: String = await google_sign_in_result
	return _resolve(payload)

## Returns the Firebase ID token on success, or an empty string on
## failure (check get_last_error() for the reason).
func sign_in_with_email_async(email: String, password: String, create_if_missing: bool) -> String:
	if not is_supported_on_this_platform():
		push_error("FirebaseWebIdentityProvider: sign_in_with_email_async called on a non-Web platform.")
		return ""

	var window_interface = JavaScriptBridge.get_interface("window")
	window_interface.warzoneEmailSuccess = JavaScriptBridge.create_callback(_on_email_success)
	window_interface.warzoneEmailError = JavaScriptBridge.create_callback(_on_email_error)

	var escaped_email := email.c_escape()
	var escaped_password := password.c_escape()
	JavaScriptBridge.eval(
		"WarzoneFirebaseAuth.signInWithEmail('%s', '%s', %s, window.warzoneEmailSuccess, window.warzoneEmailError);" % [
			escaped_email, escaped_password, "true" if create_if_missing else "false"
		],
		true
	)

	var payload: String = await email_sign_in_result
	return _resolve(payload)

func _resolve(payload: String) -> String:
	if payload.begins_with(ERROR_PREFIX):
		_last_error = payload.substr(ERROR_PREFIX.length())
		return ""
	_last_error = ""
	return payload

func _on_google_success(args: Array) -> void:
	google_sign_in_result.emit(args[0] as String)

func _on_google_error(args: Array) -> void:
	google_sign_in_result.emit(ERROR_PREFIX + (args[0] as String))

func _on_email_success(args: Array) -> void:
	email_sign_in_result.emit(args[0] as String)

func _on_email_error(args: Array) -> void:
	email_sign_in_result.emit(ERROR_PREFIX + (args[0] as String))
