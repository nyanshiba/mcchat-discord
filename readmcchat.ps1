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
    # /etc/crontab: @reboot user pwsh readmcchat.ps1 -Name CBWSurvival
    "CBWSurvival" =
    @{
        # latest.logのパス
        latestLogPath = "~/Servers/CBWSurvival/logs/latest.log"

        # Webhook URL (Discord, Slack等)
        hookUrl = "https://discordapp.com/api/webhooks/XXXXXXXXXX"

        # 一致する行の条件 (Minecraftサーバへの接続/切断, プレイヤーのチャットに一致)
        Pattern = "Server thread/INFO\]: (<.*|.*(joined|left) the game)"

        # 一致した行の整形
        Formatter =
        ({
            return [Regex]::Replace($_, "^.*]: (.*)$", { $args.Groups[1].Value })
        })
    }
    "GetPlayerCountry" =
    @{
        latestLogPath = "~/Servers/CBWSurvival/logs/latest.log"
        hookUrl = "https://discordapp.com/api/webhooks/XXXXXXXXXX"
        Pattern = "logged"
        Formatter =
        ({
            # プレイヤーのIPv4/IPv6アドレスを取得
            $ipaddr = [Regex]::Replace($_, "^.*]: .*[[/]((\w*:\w+)+|[\d.]+).*$", { $args.Groups[1].Value })

            # ipinfo.ioで国を取得
            return (Invoke-WebRequest -Uri "https://ipinfo.io/$ipaddr/json" | ConvertFrom-Json).country
        })
    }
}

# ファイル監視
Get-Content -Wait -Tail 0 -Path $Profiles.$Name.latestLogPath | Select-String -Pattern $Profiles.$Name.Pattern | ForEach-Object {
    # Webhook
    Invoke-RestMethod -Uri $Profiles.$Name.hookUrl -Method Post -Headers @{
        "Content-Type" = "application/json"
    } -Body (
        [System.Text.Encoding]::UTF8.GetBytes(
            (
                [PSCustomObject]@{
                    content = "$(Invoke-Command -ScriptBlock $Profiles.$Name.Formatter)"
                    username = "$Name"
                } | ConvertTo-Json -Depth 1
            )
        )
    )
}
