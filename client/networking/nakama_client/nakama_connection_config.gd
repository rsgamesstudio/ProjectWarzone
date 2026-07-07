class_name NakamaConnectionConfig
extends RefCounted
## Connection settings for reaching the Nakama server. Values here are
## the LOCAL DEVELOPMENT defaults, matching
## infra/docker/nakama/local.yml — they intentionally match a fresh
## `docker compose up` with no `.env` overrides.
##
## TODO(Phase 15): replace these hardcoded defaults with a build-time
## or runtime-configurable source (e.g. an exported Resource per
## environment, or a value injected by the CI/CD release pipeline) so
## staging/production builds don't ship pointed at localhost. Tracked
## here rather than silently left as a trap for a future contributor.

const SERVER_KEY: String = "warzone_dev_server_key_change_me"
const HOST: String = "127.0.0.1"
const PORT: int = 7350
const SCHEME: String = "http"
const TIMEOUT_SECONDS: int = 5
