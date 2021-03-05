#requires -version 7

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $Name
)

# ユーザ設定
$Profiles =
@{
    "CBWSurvival" =
    @{
        latestLogPath = "~/Servers/CBWSurvival/logs/latest.log"
        hookUrl = "https://discordapp.com/api/webhooks/XXXXXXXXXX"
    }
}

<#
想定したlatest.log
[04:18:54] [Server thread/INFO]: <yucaf> ﾗｼﾞｬ！
[16:25:26] [Server thread/INFO]: yucaf joined the game
[16:27:45] [Server thread/INFO]: yucaf lost connection: Disconnected
[16:27:45] [Server thread/INFO]: yucaf left the game
[16:25:26] [User Authenticator #141/INFO]: UUID of player yucaf is XXX-XXX-XXX-XXX
[16:25:26] [Server thread/INFO]: yucaf[/みせられないよ！] logged in with entity id 60248913 at (-24.24919487158972, 126.0, 373.40783442617834)
[20:06:30] [Server thread/INFO]: [Server] The server shuts down after 10 seconds.
[20:06:40] [Server thread/INFO]: Stopping the server
[20:06:40] [Server thread/INFO]: Stopping server
[20:06:40] [Server thread/INFO]: Saving players
[20:06:40] [Server thread/INFO]: Saving worlds
[20:06:40] [Server thread/INFO]: Saving chunks for level 'world'/minecraft:the_end
[20:06:40] [Server thread/INFO]: ThreadedAnvilChunkStorage (DIM1): All chunks are saved
...
#>
# tmux new-session -ds readmcchat pwsh ~/Repos/mcchat-discord/readmcchat.ps1
Get-Content -Wait -Tail 0 -Path $Profiles.$Name.latestLogPath | Select-String -Pattern "Server thread/INFO\]: (<.*|.*(joined|left) the game)" | ForEach-Object {
    Invoke-RestMethod -Uri $Profiles.$Name.hookUrl -Method Post -Headers @{ "Content-Type" = "application/json" } -Body ([System.Text.Encoding]::UTF8.GetBytes(([PSCustomObject]@{ content = "$(($_ -split ']: ')[1])"; username = "$Name" } | ConvertTo-Json -Depth 1)))
}
