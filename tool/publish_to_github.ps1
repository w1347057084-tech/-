<#
.SYNOPSIS
    把本工程推送到 GitHub，并给出 iOS 出包（未签名 IPA）的下一步。

.DESCRIPTION
    在 GitHub 网页上建好一个空仓库后，运行本脚本即可完成 remote 配置和推送。
    推送成功会在 GitHub Actions 里自动触发 ios-unsigned-ipa 流程：
    先跑静态分析和单元测试，再用 macOS runner 产出未签名 IPA。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tool\publish_to_github.ps1 `
        -RepoUrl https://github.com/yourname/periodic-table-study.git
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl
)

$ErrorActionPreference = 'Stop'

function Resolve-GitExecutable {
    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    # 刚装完 Git 但当前终端还没刷新 PATH 时，回退到常见安装位置。
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    return $null
}

$gitExe = Resolve-GitExecutable
if (-not $gitExe) {
    throw "未找到 git。请先安装 Git for Windows（https://git-scm.com/download/win），再重新运行本脚本。"
}

function Get-SystemProxyUrl {
    # 国内直连 github.com 经常超时；Windows 上开着代理时，git 默认不走它，这里补上。
    $settings = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
    if (-not $settings -or $settings.ProxyEnable -ne 1 -or -not $settings.ProxyServer) {
        return $null
    }

    $server = "$($settings.ProxyServer)".Trim()
    if ($server -match '=') {
        # 形如 "http=host:port;https=host:port" 的多协议写法
        $parts = @{}
        foreach ($piece in ($server -split ';')) {
            $pair = $piece -split '=', 2
            if ($pair.Count -eq 2) {
                $parts[$pair[0].Trim().ToLower()] = $pair[1].Trim()
            }
        }
        if ($parts.ContainsKey('https')) { $server = $parts['https'] }
        elseif ($parts.ContainsKey('http')) { $server = $parts['http'] }
        else { return $null }
    }

    if ($server -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        $server = "http://$server"
    }
    return $server
}

$script:GitProxyArgs = @()
$systemProxy = Get-SystemProxyUrl
if ($systemProxy) {
    Write-Host "检测到系统代理 $systemProxy，git 将通过它访问 GitHub。"
    $script:GitProxyArgs = @('-c', "http.proxy=$systemProxy", '-c', "https.proxy=$systemProxy")
}
else {
    Write-Host "未检测到已启用的系统代理，git 将直连 GitHub。"
}

function Invoke-Git {
    param([string[]]$Arguments)

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $gitExe @($script:GitProxyArgs + $Arguments) 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }

    return [pscustomobject]@{ ExitCode = $code; Output = @($output) }
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not (Test-Path '.git')) {
    throw "当前目录不是 Git 仓库，请先执行 git init -b main 并提交。"
}

$branchResult = Invoke-Git @('rev-parse', '--abbrev-ref', 'HEAD')
if ($branchResult.ExitCode -ne 0) {
    throw "无法确定当前分支：$($branchResult.Output -join ' ')"
}
$branch = "$($branchResult.Output[0])".Trim()

$remoteResult = Invoke-Git @('config', '--get', 'remote.origin.url')
if ($remoteResult.ExitCode -eq 0 -and "$($remoteResult.Output[0])".Trim()) {
    Write-Host "更新 origin：$("$($remoteResult.Output[0])".Trim()) -> $RepoUrl"
    $setResult = Invoke-Git @('remote', 'set-url', 'origin', $RepoUrl)
}
else {
    Write-Host "添加 origin：$RepoUrl"
    $setResult = Invoke-Git @('remote', 'add', 'origin', $RepoUrl)
}
if ($setResult.ExitCode -ne 0) {
    throw "配置 origin 失败：$($setResult.Output -join ' ')"
}

Write-Host "推送 $branch ..."
$pushResult = Invoke-Git @('push', '-u', 'origin', $branch)
foreach ($line in $pushResult.Output) {
    Write-Host $line
}
if ($pushResult.ExitCode -ne 0) {
    throw @"
推送失败，请检查仓库地址和 GitHub 凭据。
如果报的是 "Could not connect to server"，说明到 github.com 的网络不通：
本脚本会自动使用 Windows 已启用的系统代理，代理未开启时只能直连，国内网络容易超时，
打开代理后重试即可。
"@
}

Write-Host ""
Write-Host "推送完成。"
if ($RepoUrl -match '^https://github\.com/(?<slug>[^/]+/[^/]+?)(\.git)?$') {
    $slug = $Matches['slug']
    Write-Host "下一步：打开 https://github.com/$slug/actions"
    Write-Host "等待 ios-unsigned-ipa 运行完成，在该次运行的 Artifacts 里下载"
    Write-Host "periodic-table-study-unsigned-ipa，即为未签名 IPA。"
    Write-Host "仓库公开的话这次构建不消耗额度；私有仓库的 macOS runner 按 10 倍计费。"
}
