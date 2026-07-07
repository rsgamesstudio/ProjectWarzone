class_name NakamaClientAdapter
extends RefCounted
## Wraps the vendored Nakama Godot client SDK's HTTP/session API AND
## (as of Phase 5) its realtime WebSocket API. This is the only place
## in the client allowed to reference the raw
## `Nakama`/`NakamaClient`/`NakamaSocket`/`NakamaSession` types from
## `addons/com.heroiclabs.nakama/` directly — every feature service
## depends on THIS adapter's interface instead, so the SDK stays
## swappable behind it (see ARCHITECTURE.md §5).
##
## Not an autoload — constructed once by Bootstrap and registered into
## Services under the key "NakamaClient", exactly like EventBus.

signal match_snapshot_received(snapshot: Dictionary)
signal position_corrected(position: Vector3)
signal match_joined(match_id: String)
signal socket_connection_error(error: String)
signal damage_event_received(target_id: String, source_id: String, amount: float, remaining_health: float)
signal elimination_event_received(user_id: String)

var _client: NakamaClient
var _socket: NakamaSocket = null
var _current_session: NakamaSession = null
var _current_match_id: String = ""

func _init() -> void:
	# `Nakama` here refers to the SDK's own required autoload
	# (client/addons/com.heroiclabs.nakama/Nakama.gd), registered in
	# project.godot — NOT our own core/di ServiceContainer, which is
	# a separate autoload named `Services`.
	_client = Nakama.create_client(
		NakamaConnectionConfig.SERVER_KEY,
		NakamaConnectionConfig.HOST,
		NakamaConnectionConfig.PORT,
		NakamaConnectionConfig.SCHEME,
		NakamaConnectionConfig.TIMEOUT_SECONDS
	)

## Guest login via a stable, locally-generated device ID (see
## client/features/authentication/infrastructure/guest_identity_provider.gd
## for how that ID is generated/persisted).
func authenticate_guest_async(device_id: String) -> AuthResult:
	var session: NakamaSession = await _client.authenticate_device_async(device_id)
	return _to_auth_result(session)

## Email/password login. `create_if_missing` controls whether Nakama
## should create a new account if the email isn't registered yet —
## the authentication feature's application layer decides which UX
## flow (login vs. sign-up) sets this, this adapter just passes it
## through.
func authenticate_email_async(email: String, password: String, create_if_missing: bool) -> AuthResult:
	var session: NakamaSession = await _client.authenticate_email_async(email, password, null, create_if_missing)
	return _to_auth_result(session)

## Google login. `firebase_id_token` is the ID token obtained from
## Firebase client-side after a successful Google sign-in (see
## client/features/authentication/infrastructure/firebase_web_identity_provider.gd).
## The server's `registerBeforeAuthenticateCustom` hook verifies this
## token and rewrites the custom_id to the verified Firebase UID
## before Nakama accepts it (see ADR-0004) — this adapter does not
## and cannot verify the token itself; it only transports it.
func authenticate_google_async(firebase_id_token: String) -> AuthResult:
	var session: NakamaSession = await _client.authenticate_custom_async(firebase_id_token)
	return _to_auth_result(session)

## Calls the `claim_nickname` RPC (see
## server/modules/authentication/src/index.ts) using the current
## session from the most recent successful authenticate_*_async call.
## Returns the parsed JSON result from the server, e.g.
## `{"success": true, "nickname": "Sukesh_D"}` or
## `{"success": false, "errorCode": "ALREADY_TAKEN", "message": "..."}`.
## Returns null if there is no active session or the call itself
## failed at the transport level (network error, server unreachable) —
## distinct from a well-formed `{"success": false, ...}` business
## response.
func claim_nickname_async(nickname: String) -> Variant:
	return await _call_rpc_json("claim_nickname", JSON.stringify({"nickname": nickname}))

## Calls the manual-testing `create_match_for_testing` RPC (see
## server/modules/match_handler/src/index.ts) and returns the created
## match ID, or an empty string on failure. TEMPORARY — real match
## creation goes through the matchmaker in Phase 11; this exists only
## so Phase 5 networking can be exercised end-to-end before that
## exists.
func create_match_for_testing_async() -> String:
	var parsed = await _call_rpc_json("create_match_for_testing", "")
	if parsed == null or not parsed.has("matchId"):
		return ""
	return parsed["matchId"]

## Calls the `get_inventory` RPC (see
## server/modules/inventory_sync/src/index.ts). Returns the raw parsed
## Dictionary — callers typically pass this to
## `InventoryView.from_dict()`. Returns null on transport failure.
func get_inventory_async() -> Variant:
	return await _call_rpc_json("get_inventory", "")

## Calls the `equip_item` RPC. Returns
## `{"success": true, "slotKey": "..."}` or
## `{"success": false, "errorCode": "...", "message": "..."}`, or null
## on transport failure.
func equip_item_async(item_id: String) -> Variant:
	return await _call_rpc_json("equip_item", JSON.stringify({"itemId": item_id}))

## Calls the `purchase_item` RPC. Returns
## `{"success": true, "itemId": "...", "marksSpent": N}` or
## `{"success": false, "errorCode": "...", "message": "..."}`, or null
## on transport failure.
func purchase_item_async(item_id: String) -> Variant:
	return await _call_rpc_json("purchase_item", JSON.stringify({"itemId": item_id}))

## Shared helper for the simple "call an RPC, parse JSON response"
## pattern every method above follows. Returns null on no-session,
## transport-level failure, or an unparseable response — callers
## can't distinguish which of those three occurred from the return
## value alone, which is an accepted simplification (none of today's
## callers need to distinguish them; see each method's docstring).
func _call_rpc_json(rpc_name: String, payload: String) -> Variant:
	if _current_session == null:
		push_error("NakamaClientAdapter: %s called with no active session." % rpc_name)
		return null

	var response = await _client.rpc_async(_current_session, rpc_name, payload)
	if response.is_exception():
		var exception: NakamaException = response.get_exception()
		push_error("NakamaClientAdapter: %s RPC failed: %s" % [rpc_name, exception.message])
		return null

	var parsed = JSON.parse_string(response.payload)
	if parsed == null:
		push_error("NakamaClientAdapter: %s RPC returned unparseable payload: %s" % [rpc_name, response.payload])
	return parsed

## Opens the realtime WebSocket connection. Must be called (and
## awaited) once, after a successful authenticate_*_async, before
## join_match_async. Safe to call only once per adapter instance —
## reconnect handling (required by this project's networking spec) is
## built on top of this in a later pass once there's a real match loop
## to reconnect into; see this folder's README for current scope.
func connect_socket_async() -> bool:
	if _current_session == null:
		push_error("NakamaClientAdapter: connect_socket_async called with no active session.")
		return false

	_socket = Nakama.create_socket_from(_client)
	_socket.received_match_state.connect(_on_received_match_state)
	_socket.connection_error.connect(_on_socket_connection_error)

	var result: int = await _socket.connect_async(_current_session)
	if result != OK:
		push_error("NakamaClientAdapter: socket connect failed (error code %d)." % result)
		return false
	return true

## Joins the given match ID over the realtime socket. Must be called
## after connect_socket_async(). Emits `match_joined` on success.
func join_match_async(match_id: String) -> bool:
	if _socket == null:
		push_error("NakamaClientAdapter: join_match_async called before connect_socket_async.")
		return false

	var result = await _socket.join_match_async(match_id)
	if result.is_exception():
		var exception: NakamaException = result.get_exception()
		push_error("NakamaClientAdapter: join_match failed: %s" % exception.message)
		return false

	_current_match_id = match_id
	match_joined.emit(match_id)
	return true

## Sends a player input message ({position, deltaSeconds}) to the
## match handler's matchLoop. Uses the unreliable-by-default send for
## high-frequency input, matching how the server broadcasts snapshots
## (see server/modules/match_handler/src/infrastructure/match_handler.ts).
func send_player_input(position: Vector3, delta_seconds: float) -> void:
	if _socket == null or _current_match_id.is_empty():
		push_error("NakamaClientAdapter: send_player_input called with no active match.")
		return

	var payload := JSON.stringify({
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"deltaSeconds": delta_seconds,
	})
	_socket.send_match_state_async(_current_match_id, MatchOpcodes.PLAYER_INPUT, payload)

## Sends a weapon fire claim to the match handler (see ADR-0007 —
## the server validates plausibility, it does not re-simulate the
## shot). `distance_meters` is the client's own raycast-measured
## distance to the target at the moment of firing.
func send_weapon_fire_claim(target_id: String, weapon_id: String, distance_meters: float) -> void:
	if _socket == null or _current_match_id.is_empty():
		push_error("NakamaClientAdapter: send_weapon_fire_claim called with no active match.")
		return

	var payload := JSON.stringify({
		"targetId": target_id,
		"weaponClass": weapon_id,
		"claimedDistanceMeters": distance_meters,
	})
	_socket.send_match_state_async(_current_match_id, MatchOpcodes.WEAPON_FIRE_CLAIM, payload)

func _on_received_match_state(match_data) -> void:
	match match_data.op_code:
		MatchOpcodes.SNAPSHOT:
			var parsed = JSON.parse_string(match_data.data)
			if parsed != null:
				match_snapshot_received.emit(parsed)
		MatchOpcodes.POSITION_CORRECTION:
			var parsed = JSON.parse_string(match_data.data)
			if parsed != null and parsed.has("x"):
				position_corrected.emit(Vector3(parsed["x"], parsed["y"], parsed["z"]))
		MatchOpcodes.DAMAGE_EVENT:
			var parsed = JSON.parse_string(match_data.data)
			if parsed != null:
				damage_event_received.emit(
					parsed.get("targetId", ""), parsed.get("sourceId", ""),
					parsed.get("amount", 0.0), parsed.get("remainingHealth", 0.0)
				)
		MatchOpcodes.ELIMINATION_EVENT:
			var parsed = JSON.parse_string(match_data.data)
			if parsed != null:
				elimination_event_received.emit(parsed.get("userId", ""))

func _on_socket_connection_error(error) -> void:
	var message: String = error.message if error is NakamaException else str(error)
	push_error("NakamaClientAdapter: socket connection error: %s" % message)
	socket_connection_error.emit(message)

func _to_auth_result(session: NakamaSession) -> AuthResult:
	if session.is_exception():
		var exception: NakamaException = session.get_exception()
		return AuthResult.failure(exception.message)

	_current_session = session
	return AuthResult.ok(session.token, session.refresh_token, session.user_id)
