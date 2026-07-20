# txLogin

Standalone FiveM resource that bridges txAdmin authentication with a togglable "Duty" status. Staff can toggle their admin presence on/off, which is exposed to other resources via state bags — useful for incognito modes, staff tracking, or gating the txAdmin menu behind duty status.

## Features
* Listens to txAdmin authentication events to track connected staff.
* Syncs `txAdmin` and `txLogin` state bags on every player, readable from any other resource (scoreboards, HUDs, nametags, etc).
* Triggers a client-side re-auth (`txcl:reAuth`) on toggle so the txAdmin menu picks up the change immediately.
* Optional ACE permission support for the toggle command.
* Tracks time spent on duty per admin, per connection.
* Cleans up state on disconnect and on permission changes pushed from the txAdmin web panel.
* Survives a `restart txLogin` without losing admin/duty state for players who stayed connected.
* Player-facing messages available in English, Dutch, French, Spanish, and German.

## Documentation
Full config and API reference: https://dots-development.gitbook.io/docs/free-scripts/dots-txlogin

## State Bags & Exports

| State Bag | Type | Description |
| --------- | ---- | ----------- |
| `playerState.txAdmin` | boolean | True if the player is an authenticated txAdmin administrator. |
| `playerState.txLogin` | boolean | True if the admin is currently on duty. |

### `toggleDuty(source, status)`
Toggles duty status, or forces a specific state. Returns the new state (`boolean`), or `nil` if the player isn't an admin.

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| source | number | Yes | Server ID (netid) of the player. |
| status | boolean | No | `true` to force on duty, `false` to force off duty. Omit to toggle. |

```lua
exports['txLogin']:toggleDuty(source)
```

### `fetchAdmins(onlyOnDuty)`
Returns a table of authenticated admins currently on the server, keyed by server ID, with `username`, `isAdmin`, `onDuty`, `dutySince`, and `totalDuty` fields.

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| onlyOnDuty | boolean | No | If `true`, only returns admins currently on duty. |

```lua
local activeStaff = exports['txLogin']:fetchAdmins(true)

for src, info in pairs(activeStaff) do
    print(info.username .. ' (ID: ' .. src .. ') is active!')
end
```

### `getDutyTime(source)`
Returns the total number of seconds an admin has spent on duty since they connected, including the current session if they're on duty right now.

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| source | number | Yes | Server ID (netid) of the player. |

```lua
local seconds = exports['txLogin']:getDutyTime(source)
```

## Duty tracking
Every admin record carries `dutySince` (timestamp of when their current duty session started, or `nil` if off duty) and `totalDuty` (accumulated seconds on duty since they connected). Session length is included in Discord/ox logs when going off duty.

This is per-connection, not a permanent stats database — `totalDuty` resets when the admin fully disconnects, not on a `restart txLogin` (see below).

## Locales
Player-facing notifications (currently just the duty on/off message) are pulled from `locales/<code>.lua`. Set `Settings.Locale` to `'en'`, `'nl'`, `'fr'`, `'es'`, or `'de'`. Adding a language is just a new `locales/xx.lua` file following the same shape as the existing ones — no manifest changes needed since `locales/*.lua` is already globbed in.

## Surviving a resource restart
`admins` (and duty state) live in memory, so a plain `restart txLogin` used to reset everyone's duty status even if they never disconnected. Now, on start, txLogin re-triggers `txcl:reAuth` for every currently connected player, which re-runs the client's admin auth flow and re-fires `txAdmin:events:adminAuth` server-side — the same event this resource already listens to. Duty status and accumulated time for those players are restored from `duty_state.json` (written next to the resource's Lua files, gitignored) at that point.

This only restores state for players who were connected at the moment of restart — a real disconnect always clears their saved state, so nobody comes back on-duty from a stale file after actually leaving.

## Gating the txAdmin menu behind duty status
This is the main use case for `txcl:reAuth`: keep the txAdmin menu unusable while an admin is off duty.

In `monitor/resource/menu/client/cl_base.lua`, find the `txcl:setAdmin` event handler and change:
```lua
menuIsAccessible = true
```
to:
```lua
menuIsAccessible = LocalPlayer.state.txLogin
```

Since toggling duty forces a re-auth, the state bag updates immediately and the menu accessibility follows it.
