extends Control
## Login screen shown after the loading screen, before the lobby.
## First real UI wiring of `AuthService` (built in Phase 4) — until
## now it existed but wasn't connected to any screen.
##
## Button mapping:
##   - "Sign in with RS GAMES STUDIO" -> reveals an email/password
##     form -> AuthService.login_with_email_async(). This is our
##     existing Email login (ADR-0004), presented under the studio's
##     own brand rather than a generic "Email" label — no new backend
##     needed, just a UI framing choice.
##   - "Sign in with Google" -> AuthService.login_with_google_async().
##     HTML5/Web only today — see FirebaseWebIdentityProvider's scope
##     note; on other platforms this shows a "not available yet"
##     message rather than silently failing.
##   - "Sign in with Facebook" -> NOT in this project's original auth
##     scope (Guest/Google/Email only — see root README). Shown for
##     layout completeness since it was in the reference image, wired
##     to a "not implemented" message rather than faked as working.
##   - "Continue as Guest" -> AuthService.login_as_guest_async(),
##     fully functional on every platform today.

signal login_succeeded(session: AuthSession)

@onready var studio_button: Button = %StudioButton
@onready var google_button: Button = %GoogleButton
@onready var facebook_button: Button = %FacebookButton
@onready var guest_button: Button = %GuestButton
@onready var email_form: Control = %EmailForm
@onready var email_field: LineEdit = %EmailField
@onready var password_field: LineEdit = %PasswordField
@onready var email_submit_button: Button = %EmailSubmitButton
@onready var status_label: Label = %StatusLabel

var _auth_service: AuthService

func _ready() -> void:
	email_form.visible = false
	status_label.text = ""

	var nakama_client: NakamaClientAdapter = Services.resolve("NakamaClient")
	_auth_service = AuthService.new(
		nakama_client,
		GuestIdentityProvider.new(),
		FirebaseWebIdentityProvider.new()
	)

	# Music starts here per design: login screen -> lobby is the first
	# time a player hears it; it keeps looping through the lobby and
	# only pauses once Phase 11 wires a real match-join flow (see
	# MusicPlayer's docstring).
	var music_player: MusicPlayer = Services.resolve("MusicPlayer")
	music_player.play_looped(load(AudioTracks.LOBBY_THEME))

	studio_button.pressed.connect(func() -> void: email_form.visible = not email_form.visible)
	google_button.pressed.connect(_on_google_pressed)
	facebook_button.pressed.connect(func() -> void: _show_status("Facebook sign-in isn't available yet."))
	guest_button.pressed.connect(_on_guest_pressed)
	email_submit_button.pressed.connect(_on_email_submit_pressed)

func _on_guest_pressed() -> void:
	_show_status("Signing in...")
	var session: AuthSession = await _auth_service.login_as_guest_async()
	_handle_login_result(session)

func _on_google_pressed() -> void:
	_show_status("Signing in with Google...")
	var session: AuthSession = await _auth_service.login_with_google_async()
	_handle_login_result(session)

func _on_email_submit_pressed() -> void:
	_show_status("Signing in...")
	var session: AuthSession = await _auth_service.login_with_email_async(
		email_field.text, password_field.text, true
	)
	_handle_login_result(session)

func _handle_login_result(session: AuthSession) -> void:
	if session.is_valid():
		login_succeeded.emit(session)
	else:
		_show_status("Sign-in failed. Please try again.")

func _show_status(message: String) -> void:
	status_label.text = message
