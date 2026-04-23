# 🔑 • txLogin
A high-performance, standalone utility for FiveM that bridges txAdmin authentication with a togglable "Duty" status. It allows staff members to control their administrative presence and permissions via state bags, making it the perfect foundation for "Incognito" modes or staff tracking systems.

## ✨ • Features
* **txAdmin Integration**: Listens directly to txAdmin authentication events to verify staff.
* **State Bag Synchronization**: Automatically manages txAdmin and txLogin state bags for use in external scripts (Scoreboards, HUDs, Nametags).
* **Dynamic Permissions**: Forces a client-side re-authentication (txcl:reAuth) when toggling duty to refresh the txAdmin menu.
* **ACE Permission Support**: Optional integration with server-side ACE permissions for the toggle command.
* **Auto-Cleanup**: Intelligently handles player disconnects and real-time permission changes from the txAdmin web panel.

## 📖 Documentation & Integration
Whether you need a quick snippet or a deep dive into the system's architecture, we have provided resources for every level of integration:
* **Simple Integration**: For basic needs, check the Exports section below for quick-start snippets.
* **Advanced Usage**: For detailed expansions, full API references, and configuration guides, please visit our [official documentation](https://dots-development.gitbook.io/docs/free-scripts/dots-txlogin).

## 📊 • State Bags & Exports (Developer API)
This resource synchronizes two primary state bags to every player. These can be checked from any other resource (Client or Server) to determine staff status.

| State Bag | Type | Description |
| --------- | ------| -----|
|playerState.txAdmin | boolean | True if the player is an authenticated txAdmin administrator. |
| playerState.txLogin | boolean | True if the admin is currently On Duty. |

<br/>

You can also programmatically control or check an admin's duty status using the provided export.

`toggleDuty` - Toggles the duty status or forces a specific state for a player. Returns the new state (boolean), or nil if the player is not an admin.
|Parameter | Type | Required | Description |
| --------- | ------| -----| -------- |
| source | number | Yes | The Server ID (netid) of the player. |
| status | boolean | No | true to force On Duty, false to force Off Duty. Leave nil to toggle. |
```lua
  exports['txLogin']:toggleDuty(source)
```


`fetchAdmins` - Returns a table of all authenticated administrators currently in the server. Where the key is the player Server ID and the value is an object containing username, isAdmin, and onDuty.
|Parameter | Type | Required | Description |
| --------- | ------| -----| -------- |
| onlyOnDuty | boolean | No | If `true`, the list will only include admins currently On Duty. |
```lua
local activeStaff = exports['txLogin']:fetchAdmins(true)

for src, info in pairs(activeStaff) do
    print(info.username .. " (ID: " .. src .. ") is active!")
end
```

## 🔌 • Usage
The most common practice for this script—and the main reason `txcl:reAuth` is included—is to block usage of the txAdmin menu while players are not On Duty. While there are plenty of other ways to set admin status to false, they often feel "hacky" or don't sync correctly. This method ensures that the menu only becomes available when the state bag allows it.

To set this up, you'll need to locate the following piece of code in `monitor/resource/menu/client/cl_base.lua`. Look for the event called `txcl:setAdmin` and modify it as follows:

**Find the line:**
```
  menuIsAccessible = true
```
**and change it to:**
```
  menuIsAccessible = LocalPlayer.state.txLogin
```

By tying the menu's accessibility directly to the txLogin state bag, you create a foolproof lock. When you toggle duty, the server forces a re-auth, the state bag updates, and the menu either grants or denies access instantly.

From here on out, you can adjust minor things to fit your server's specific needs. That’s pretty much it — enjoy!