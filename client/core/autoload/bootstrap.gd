extends Node
## Autoload name: `Bootstrap`
##
## The second (and last) true Godot autoload in the project (see
## ARCHITECTURE.md §5 and client/core/autoload/README.md). Bootstrap's
## only job is startup sequencing: constructing the small set of core
## services that don't belong to any single feature (EventBus,
## NakamaClientAdapter, MusicPlayer) and registering them into
## `Services` before any feature scene's `_ready()` can run.
##
## Godot guarantees autoloads are added to the tree, in project.godot
## order, before the first scene loads. `Services` and the SDK's own
## `Nakama` autoload are both listed before `Bootstrap` in
## project.godot specifically so this script can assume they already
## exist when its own `_ready()` runs.
##
## Do NOT add feature-specific initialization here. If a feature needs
## startup logic, it belongs in that feature's own composition root
## (its top-level scene script), which resolves what it needs from
## `Services`. Bootstrap only ever grows by adding genuinely
## cross-cutting, feature-agnostic services.

func _ready() -> void:
	_register_core_services()
	print("[Bootstrap] Core services registered: %s" % [Services.registered_keys()])

func _register_core_services() -> void:
	var event_bus := EventBus.new()
	Services.register("EventBus", event_bus)

	var nakama_client := NakamaClientAdapter.new()
	Services.register("NakamaClient", nakama_client)

	# MusicPlayer must be an actual Node (AudioStreamPlayer) in the
	# scene tree to play audio, unlike EventBus/NakamaClientAdapter
	# above — added as a child of this autoload rather than
	# instantiated as a bare RefCounted.
	var music_player := MusicPlayer.new()
	add_child(music_player)
	Services.register("MusicPlayer", music_player)
