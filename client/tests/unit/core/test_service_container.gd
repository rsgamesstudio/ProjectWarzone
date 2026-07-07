extends GutTest
## Unit tests for client/core/di/service_container.gd.
##
## ServiceContainer is registered as the `Services` autoload in the
## real game, but for isolated unit testing we instantiate the script
## directly rather than depending on autoload state, per
## CODING_STANDARDS.md's testing policy.

var ServiceContainerScript: Script = preload("res://core/di/service_container.gd")
var container: Node

func before_each() -> void:
	container = ServiceContainerScript.new()

func after_each() -> void:
	container.free()

func test_register_and_resolve_returns_same_instance() -> void:
	var fake_service := Node.new()
	container.register("FakeService", fake_service)

	var resolved: Variant = container.resolve("FakeService")

	assert_eq(resolved, fake_service, "resolve() should return the exact instance passed to register()")
	fake_service.free()

func test_resolve_unregistered_key_returns_null() -> void:
	var resolved: Variant = container.resolve("DoesNotExist")
	assert_null(resolved, "resolving an unregistered key should return null")

func test_double_registration_without_override_is_rejected() -> void:
	var first := Node.new()
	var second := Node.new()

	container.register("SameKey", first)
	container.register("SameKey", second)

	var resolved: Variant = container.resolve("SameKey")
	assert_eq(resolved, first, "second register() without allow_override should NOT replace the first")

	first.free()
	second.free()

func test_double_registration_with_override_replaces() -> void:
	var first := Node.new()
	var second := Node.new()

	container.register("SameKey", first)
	container.register("SameKey", second, true)

	var resolved: Variant = container.resolve("SameKey")
	assert_eq(resolved, second, "register() with allow_override=true should replace the existing instance")

	first.free()
	second.free()

func test_has_service_reflects_registration_state() -> void:
	assert_false(container.has_service("Ghost"), "has_service should be false before registration")

	var svc := Node.new()
	container.register("Ghost", svc)
	assert_true(container.has_service("Ghost"), "has_service should be true after registration")

	container.unregister("Ghost")
	assert_false(container.has_service("Ghost"), "has_service should be false after unregister")
	svc.free()

func test_clear_all_removes_every_registration() -> void:
	var a := Node.new()
	var b := Node.new()
	container.register("A", a)
	container.register("B", b)

	container.clear_all()

	assert_false(container.has_service("A"))
	assert_false(container.has_service("B"))
	a.free()
	b.free()

func test_registered_keys_lists_all_registrations() -> void:
	var a := Node.new()
	container.register("OnlyKey", a)

	var keys: Array = container.registered_keys()

	assert_true(keys.has("OnlyKey"))
	assert_eq(keys.size(), 1)
	a.free()
