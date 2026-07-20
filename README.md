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

## Project structure
```
txLogin/
├── fxmanifest.lua
├── settings.lua       -- all configuration lives here
├── locales/            -- one file per language, keyed by Settings.Locale
│   ├── en.lua
│   ├── nl.lua
│   ├── fr.lua
│   ├── es.lua
│   └── de.lua
└── server/
    ├── utils.lua        -- Notify/Log providers, Locale/FormatDuration helpers
    ├── duty_tracking.lua -- optional, see Modules below
    └── main.lua          -- core: admin tracking, toggleDuty, exports, event handlers
```
Everything is server-only for now (`server_only 'yes'`); a `client/` folder gets added if/when a feature (e.g. clothing) needs one. This mirrors how other jhag01 resources like skillSystem are laid out — `server/`/`client/` split, config and locales shared at root.

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

## Modules
Optional features are just files in `server/` that check their own `Settings` flag and no-op when it's off — no separate `modules/` folder, matching how other jhag01 resources (e.g. skillSystem's `server/admin.lua`) do it. `duty_tracking.lua` is the only one so far, and it exposes a `DutyTracking` global that `main.lua` calls into directly (it can't use a plain top-of-file `if not Settings.X then return end` bailout like a self-contained file could, since `main.lua` calls its functions inline and expects them to exist either way — so the check happens inside each function instead).

### Duty tracking (`server/duty_tracking.lua`)
Enabled via `Settings.DutyTracking` (default `true`). Every admin record carries `dutySince` (timestamp of when their current duty session started, or `nil` if off duty) and `totalDuty` (accumulated seconds on duty since they connected). Session length is included in Discord/ox logs when going off duty.

This is per-connection, not a permanent stats database — `totalDuty` resets when the admin fully disconnects. It's also the only thing that needs `duty_state.json` (written at the resource root, gitignored): that file exists purely to carry `dutySince`/`totalDuty` across a script restart. When `DutyTracking` is disabled, no file is ever created.

## Locales
Player-facing notifications (currently just the duty on/off message) are pulled from `locales/<code>.lua`. Set `Settings.Locale` to `'en'`, `'nl'`, `'fr'`, `'es'`, or `'de'`. Adding a language is just a new `locales/xx.lua` file following the same shape as the existing ones — no manifest changes needed since `locales/*.lua` is already globbed in.

## Surviving a resource restart
`admins` lives in memory, so a plain `restart txLogin` used to reset everyone's duty status even if they never disconnected. Two things fix that, at two different levels:

* **On/off duty status** needs no extra work: `playerState.txLogin` is a state bag, which belongs to the player's connection, not to this resource's Lua state. It survives a script restart on its own and only clears when the player actually disconnects (or the whole server restarts). On start, txLogin re-triggers `txcl:reAuth` for every connected player, which re-runs the client auth flow and re-fires `txAdmin:events:adminAuth` server-side, letting txLogin rebuild its `admins` table and read the still-correct status straight off the state bag.
* **Duty-time tracking** (`dutySince`/`totalDuty`) has no such home — it's plain bookkeeping in this resource's memory — so it's restored from `duty_state.json` via the duty tracking module above, and only for players who were connected at the moment of restart. A real disconnect always clears their saved entry first, so nobody comes back with stale tracked time after actually leaving.

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
