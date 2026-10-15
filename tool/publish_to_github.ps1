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

function Invoke-Git {
    param([string[]]$Arguments)

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git @Arguments 2>&1
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
    throw "推送失败，请检查仓库地址、网络和 GitHub 凭据。"
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
