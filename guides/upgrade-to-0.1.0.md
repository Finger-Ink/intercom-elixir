# Upgrading to `0.1.0`

`0.1.0` swaps the HTTP backend from [HTTPoison](https://hex.pm/packages/httpoison) to [Req](https://hex.pm/packages/req) and removes a few `HTTPoison.Base`-flavoured shims that the old API exposed.

The maintained fork lives at <https://github.com/finger-ink/intercom-elixir>.

Every breaking change below is a mechanical find/replace. Follow the steps top-to-bottom and finish with the grep in step 6 to confirm nothing was missed.

## 1. Bump the dep

Point `mix.exs` at the fork:

```elixir
# mix.exs
defp deps do
  [
    {:intercom, github: "finger-ink/intercom-elixir", tag: "v0.1.0"},
    # ...
  ]
end
```

Then:

```sh
mix deps.unlock intercom
mix deps.get
```

## 2. Remove any `Intercom.Client.start/0` calls

`HTTPoison.Base` provided a `start/0` to boot the HTTPoison OTP app. Req's Finch pool starts on demand, so this shim is gone. Delete any boot-time calls:

```elixir
# Before
Intercom.Client.start

# After
# (nothing — just delete the line)
```

## 3. Update response-struct pattern matches

Three changes folded together: the struct module renamed (`HTTPoison.Response` → `Req.Response`), the field renamed (`:status_code` → `:status`), and the body is already decoded so `Jason.decode(response.body)` should be dropped.

```elixir
# Before
def parse_response_body(%HTTPoison.Response{status_code: 200} = response),
  do: Jason.decode(response.body)
def parse_response_body(%HTTPoison.Response{status_code: 404}), do: {:error, :not_found}
def parse_response_body(error), do: {:error, error}

# After
def parse_response_body(%Req.Response{status: 200, body: body}), do: {:ok, body}
def parse_response_body(%Req.Response{status: 404}), do: {:error, :not_found}
def parse_response_body(error), do: {:error, error}
```

Req auto-decodes JSON responses by default, so `response.body` is an Elixir term (map/list) — passing it through `Jason.decode/1` would raise.

## 4. Drop the `hackney:` wrap around `auth/2`

`Intercom.Client.auth/2` now returns a Req-native `[auth: {:basic, "app_id:api_key"}]`. It merges directly into the third arg of `get/3`, `post/4`, etc.:

```elixir
# Before
Intercom.Client.post(url, body, [], hackney: Intercom.Client.auth(token, ""))

# After
Intercom.Client.post(url, body, [], Intercom.Client.auth(token, ""))
```

Apply this anywhere you previously used `hackney: Intercom.Client.auth(...)`.

## 5. (Recommended) Drop manual `Jason.encode/1` on write bodies

`Intercom.Client.post/4`, `put/4`, and `patch/4` now route maps/structs through Req's `:json` option, which encodes once. You can simplify call sites:

```elixir
# Before
{:ok, encoded} = Jason.encode(params)
Intercom.Client.post("/tags", encoded, [], Intercom.Client.auth(token, ""))

# After
Intercom.Client.post("/tags", params, [], Intercom.Client.auth(token, ""))
```

This step is **optional** — pre-encoded binaries are still accepted and sent verbatim, so you can migrate call sites one at a time. If you want to keep your existing `Jason.encode/1` calls during a phased rollout, they will continue to work.

## 6. Verify with a grep

Run this from the root of your consumer app:

```sh
grep -rn 'HTTPoison\.Response\|status_code:\|Intercom\.Client\.start\|hackney: Intercom\.Client\.auth\|Intercom\.Client\.process_url\|Intercom\.Client\.process_request_headers' lib/ test/
```

A clean result means every legacy reference is gone. If any hits remain, walk them through steps 2–4.

## Smoke test

After upgrading:

1. Read path: e.g. `Intercom.Client.get!("/users", [], Intercom.Client.auth(token, ""))` → should return a `%Req.Response{status: 200, body: %{"users" => [...]}}`.
2. Write path: tag a test user via your usual wrapper — confirm the tag appears in the Intercom UI.

## What didn't change

- The snippet/boot helpers in the top-level `Intercom` module (`Intercom.snippet/2`, `Intercom.boot/1`, `Intercom.to_javascript_object/1`, `Intercom.inject_user_hash/2`, `Intercom.Escaping`) are untouched. This release is HTTP-client-only.
- `Intercom.Client.get/3`, `post/4`, `put/4`, `patch/4`, `delete/3`, `head/3` (and their `!` variants) keep the same arities and arg order.
- The base URL (`https://api.intercom.io`) and the default JSON `Accept` / `Content-Type` headers are still applied automatically — you don't need to set them at call sites.
