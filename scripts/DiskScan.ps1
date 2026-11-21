param(
    [string]$Drive = 'C',
    [switch]$Clean,
    [switch]$Deep
)

$ErrorActionPreference = 'Continue'
$D = $Drive.TrimEnd(':', '\') + ':'
$report = Join-Path $env:TEMP ("disk-report-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$lines = New-Object System.Collections.Generic.List[string]

function Add-Line([string]$s) { $lines.Add($s); Write-Output $s }
function Get-SizeMB([string]$p) {
    try { if (-not (Test-Path -LiteralPath $p -ErrorAction Stop)) { return -1 } } catch { return -1 }
    try { $s = (Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch { return -1 }
    return [math]::Round($s / 1MB, 1)
}

Add-Line "===== 磁盘报告 $D  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="

$v = Get-Volume -DriveLetter $Drive.TrimEnd(':')
$usedGB = [math]::Round(($v.Size - $v.SizeRemaining) / 1GB, 2)
$freeGB = [math]::Round($v.SizeRemaining / 1GB, 2)
$pct = [math]::Round($v.SizeRemaining / $v.Size * 100, 1)
Add-Line ("总容量 {0} GB | 已用 {1} GB | 可用 {2} GB ({3}%)" -f [math]::Round($v.Size/1GB,1), $usedGB, $freeGB, $pct)

Add-Line ""
Add-Line "--- 顶层目录占用 ---"
Get-ChildItem "$D\" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $s = (Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    [pscustomobject]@{ Name = $_.Name; GB = [math]::Round($s / 1GB, 2) }
} | Sort-Object GB -Descending | Where-Object { $_.GB -ge 0.1 } | ForEach-Object {
    Add-Line ("  {0,-32} {1,8} GB" -f $_.Name, $_.GB)
}

Add-Line ""
Add-Line "--- 根目录大文件 ---"
Get-ChildItem "$D\" -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 200MB } | Sort-Object Length -Descending | ForEach-Object {
    Add-Line ("  {0,-32} {1,8} GB" -f $_.Name, [math]::Round($_.Length/1GB,2))
}

Add-Line ""
Add-Line "--- 系统缓存与临时文件 ---"
$targets = [ordered]@{
    'Windows\Temp'                    = "$D\Windows\Temp"
    'Windows\SoftwareDistribution'    = "$D\Windows\SoftwareDistribution\Download"
    'Windows\Prefetch'                = "$D\Windows\Prefetch"
    'Windows\Installer'               = "$D\Windows\Installer"
    'Windows.old'                     = "$D\Windows.old"
    '用户 Temp'                       = $env:TEMP
    '回收站'                          = "$D\`$Recycle.Bin"
    'D3DSCache'                       = (Join-Path $env:LOCALAPPDATA 'D3DSCache')
    'NVIDIA DXCache'                  = (Join-Path $env:LOCALAPPDATA 'NVIDIA\DXCache')
    'NVIDIA GLCache'                  = (Join-Path $env:LOCALAPPDATA 'NVIDIA\GLCache')
    'DeliveryOptimization'            = "$D\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
}
foreach ($k in $targets.Keys) {
    $mb = Get-SizeMB $targets[$k]
    if ($mb -ge 0) { Add-Line ("  {0,-28} {1,9} MB   {2}" -f $k, $mb, $targets[$k]) }
}

Add-Line ""
Add-Line "--- 组件存储 (WinSxS) ---"
$winsxs = "$D\Windows\WinSxS"
if (Test-Path $winsxs) { Add-Line ("  WinSxS 名义大小: {0} GB（含硬链接，实际占用更小）" -f [math]::Round((Get-SizeMB $winsxs)/1024,2)) }

Add-Line ""
Add-Line "--- 建议项 ---"
Add-Line "  休眠文件 hiberfil.sys : 关闭可省约 $(if (Test-Path "$D\hiberfil.sys") { [math]::Round((Get-Item "$D\hiberfil.sys" -Force).Length/1GB,1) } else { 0 }) GB  → powercfg /h off (需管理员)"
Add-Line "  WinSxS 清理          : DISM /Online /Cleanup-Image /StartComponentCleanup (需管理员)"

if ($Clean) {
    Add-Line ""
    Add-Line "--- 执行清理（仅安全项）---"
    $before = (Get-Volume -DriveLetter $Drive.TrimEnd(':')).SizeRemaining
    $cands = @("$D\Windows\Temp", $env:TEMP, (Join-Path $env:LOCALAPPDATA 'D3DSCache'), (Join-Path $env:LOCALAPPDATA 'NVIDIA\DXCache'))
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath $c) {
            Get-ChildItem -LiteralPath $c -Force -ErrorAction SilentlyContinue | ForEach-Object {
                try { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop } catch { }
            }
            Add-Line "  已清: $c"
        }
    }
    try { Clear-RecycleBin -DriveLetter $Drive.TrimEnd(':') -Force -ErrorAction Stop; Add-Line "  已清空回收站" } catch { }
    Start-Sleep -Seconds 1
    $after = (Get-Volume -DriveLetter $Drive.TrimEnd(':')).SizeRemaining
    Add-Line ("  释放: {0} MB | 现可用 {1} GB" -f [math]::Round(($after-$before)/1MB,0), [math]::Round($after/1GB,2))
}

$lines | Set-Content -LiteralPath $report -Encoding UTF8
Add-Line ""
Add-Line "报告已保存: $report"
