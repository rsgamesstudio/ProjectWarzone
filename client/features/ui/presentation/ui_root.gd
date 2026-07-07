extends Control
## UIRoot: the project's actual `run/main_scene`. Owns a single-screen
## container and transitions between top-level screens by instancing
## and freeing them — this is the "menu navigation stack" mentioned in
## this feature's README, in its simplest form (a stack of depth 1;
## true push/pop history isn't needed yet since splash → loading →
## lobby is a linear sequence, not a navigable stack).
##
## This script hardcodes the splash → loading → lobby sequence
## directly rather than being a fully generic router, because that
## sequence IS the entire current application flow — generalizing
## further belongs in Phase 9 when there's more than one flow to
## generalize over.

const SPLASH_SCREEN_SCENE: PackedScene = preload("res://features/ui/presentation/splash_screen/splash_screen.tscn")
const LOADING_SCREEN_SCENE: PackedScene = preload("res://features/ui/presentation/loading_screen/loading_screen.tscn")
const LOGIN_SCREEN_SCENE: PackedScene = preload("res://features/authentication/presentation/login_screen.tscn")
const LOBBY_SCREEN_SCENE: PackedScene = preload("res://features/lobby/presentation/lobby_screen.tscn")

@onready var screen_container: Control = %ScreenContainer

func _ready() -> void:
	_show_splash()

func _show_splash() -> void:
	var splash: Control = _swap_screen(SPLASH_SCREEN_SCENE)
	splash.finished.connect(_show_loading, CONNECT_ONE_SHOT)

func _show_loading() -> void:
	var loading: Control = _swap_screen(LOADING_SCREEN_SCENE)
	loading.finished.connect(_show_login, CONNECT_ONE_SHOT)

func _show_login() -> void:
	var login: Control = _swap_screen(LOGIN_SCREEN_SCENE)
	login.login_succeeded.connect(_show_lobby, CONNECT_ONE_SHOT)

func _show_lobby(_session: AuthSession = null) -> void:
	_swap_screen(LOBBY_SCREEN_SCENE)

func _swap_screen(scene: PackedScene) -> Control:
	for child in screen_container.get_children():
		child.queue_free()
	var instance: Control = scene.instantiate()
	screen_container.add_child(instance)
	return instance
