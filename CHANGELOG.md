# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-14

> Upgrading from `0.0.x`? Follow [`guides/upgrade-to-0.1.0.md`](guides/upgrade-to-0.1.0.md) — every breaking change is a mechanical find/replace.

### Changed

- **Breaking**: HTTP client switched from `:httpoison` to [`:req`](https://hex.pm/packages/req) (`~> 0.5`).
- **Breaking**: Successful responses are now `%Req.Response{}` with `:status` (not `:status_code`) and an auto-decoded `:body` (Elixir term, not a raw JSON binary). Callers should drop any manual `Jason.decode(response.body)`.
- **Breaking**: `Intercom.Client.auth/2` now returns Req-native `[auth: {:basic, "app_id:api_key"}]`. Drop the previous `hackney:` wrap at call sites:

  ```elixir
  # Before
  Intercom.Client.get!("/users", [], hackney: Intercom.Client.auth(token, ""))

  # After
  Intercom.Client.get!("/users", [], Intercom.Client.auth(token, ""))
  ```

- `Intercom.Client.post/4`, `put/4`, and `patch/4` now accept maps/structs as the body and auto-encode them as JSON via Req's `:json` option. Pre-encoded binaries are still sent verbatim, so legacy callers continue to work during migration.
- `Intercom.to_javascript_object/1` now emits map properties in alphabetical key order so generated snippets are byte-stable across runs and BEAM versions. Previously the order followed Erlang's map iteration, which is implementation-defined for small maps.
- Widened the Elixir version requirement from `~> 1.14.4` to `~> 1.14`.
- `config/config.exs` migrated from the deprecated `use Mix.Config` to `import Config`.
- `mix.exs` `package/0` `links:` and `files:` updated to point at the maintained fork (`finger-ink/intercom-elixir`) and to ship `CHANGELOG*` and `guides/` with the Hex package.

### Added

- `CHANGELOG.md` (this file).
- `guides/upgrade-to-0.1.0.md` — step-by-step consumer migration.
- `test/intercom_client_test.exs` covering `Intercom.Client` GET/POST flows (including nested event metadata, tag user arrays, and pre-encoded binary bodies), default headers, base URL, basic auth via `auth/2`, and transport errors using `Req.Test` stubs.
- `:plug` as a `:test`-only dependency to support `Req.Test` plug-style stubbing.

### Removed

- **Breaking**: `:httpoison` (and its transitive `:hackney` dependency).
- **Breaking**: `Intercom.Client.start/0`, `Intercom.Client.process_url/1`, and `Intercom.Client.process_request_headers/1` — these were `HTTPoison.Base` callbacks/shims. Base URL prepending and JSON `Accept` / `Content-Type` headers are still applied automatically inside the client wrappers; only the public symbols are gone.

## [0.0.5]

Last release on the HTTPoison-backed line. See git history for prior changes.
