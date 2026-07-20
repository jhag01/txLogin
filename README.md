# txLogin

Standalone FiveM resource that bridges txAdmin authentication with a togglable "Duty" status. Staff can toggle their admin presence on/off, which is exposed to other resources via state bags — useful for incognito modes, staff tracking, or gating the txAdmin menu behind duty status.

## Features
* Listens to txAdmin authentication events to track connected staff.
* Syncs `txAdmin` and `txLogin` state bags on every player, readable from any other resource (scoreboards, HUDs, nametags, etc).
* Triggers a client-side re-auth (`txcl:reAuth`) on toggle so the txAdmin menu picks up the change immediately.
* Optional ACE permission support for the toggle command.
* Cleans up state on disconnect and on permission changes pushed from the txAdmin web panel.

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
Returns a table of authenticated admins currently on the server, keyed by server ID, with `username`, `isAdmin`, and `onDuty` fields.

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| onlyOnDuty | boolean | No | If `true`, only returns admins currently on duty. |

```lua
local activeStaff = exports['txLogin']:fetchAdmins(true)

for src, info in pairs(activeStaff) do
    print(info.username .. ' (ID: ' .. src .. ') is active!')
end
```

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
