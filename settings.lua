Settings = {

    Command = 'txLogin', -- Command to toggle duty status
    AcePerms = false, -- Use ace permissions: command.txLogin

    Notify = 'none', -- Notification type: 'none', 'ox' (ox_lib required), 'custom' (Insert own notification system in utils.Notify function)
    Logger = 'none', -- Logger type: 'none', 'ox' (ox_lib required), 'discord', 'custom' (Insert own logging system in utils.Log function)

    DiscordLogs = { -- Discord Logger Settings
        Webhook = 'WEBHOOK',
        Username = 'txLogin',
        Color = '16711680',
        Title = 'txLogin:Logger',
        Footer = 'githubUser: jhag01'
    },

    OxLogs = { -- Ox Logger Settings
        Event = 'txLogin'
    }
}