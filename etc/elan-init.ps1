<#
.SYNOPSIS
    .

.DESCRIPTION
    This is just a little script that can be downloaded from the Internet to
    install elan. It just does platform detection, downloads the latest
    installer, then runs it.

.PARAMETER Verbose
    Produce verbose output about the elan installation process.

.PARAMETER NoPrompt
    Do not present elan installation menu of choices.

.PARAMETER NoModifyPath
    Do not modify PATH environment variable.

.PARAMETER DefaultToolchain
    Which tool chain to setup as your default toolchain, or specify 'none'

.PARAMETER ElanRoot
    Where to find the elan-init tool, default is https://github.com/leanprover/elan/releases

.PARAMETER ElanVersion
    Specific version of elan to download and run instead of latest, e.g. 1.4.1
#>

# PKUOSC note: forked @ https://github.com/leanprover/elan/blob/af23a1ef506bd78a281d9d5678bd4d3426aead04/elan-init.sh

param(
    [bool] $Verbose = 0,
    [bool] $NoPrompt = 0,
    [bool] $NoModifyPath = 0,
    [string] $DefaultToolchain = "",
    [string] $ElanRoot = "https://mirrors.pku.edu.cn/elan/releases",
    [string] $ElanVersion = ""
)

$cputype = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE");

if ($cputype -ne "AMD64") {
    Write-Host "### Elan install only supports 64-bit Windows with AMD64 architecture"
    return 1
}

$_arch = "x86_64-pc-windows-msvc"
$_ext = ".exe"
$temp = [System.IO.Path]::GetTempPath()
$_dir = Join-Path $temp "elan"
if (-not (Test-Path -Path $_dir)) {
    $null = New-Item -ItemType Directory -Path $_dir
}
$_file = "$_dir/elan-init$_ext"

Write-Host "info: downloading installer to ${temp}"

try {
    [string] $DownloadUrl = ""
    if ($ElanVersion.Length -gt 0) {
        $DownloadUrl = "$ElanRoot/download/v$ElanVersion/elan-$_arch.zip"
    }
    else {
        $DownloadUrl = "$ElanRoot/latest/download/elan-$_arch.zip"
    }
    $null = Start-BitsTransfer -Source $DownloadUrl -Destination "$_dir/elan-init.zip" -ErrorAction Stop
}
catch {
    Write-Host "Download failed for ${DownloadUrl}"
    return 1
}

$null = Expand-Archive -Path "$_dir/elan-init.zip" -DestinationPath "$_dir" -Force

$cmdline = " "
if ($DefaultToolchain -ne "") {
    $cmdline += "--default-toolchain $DefaultToolchain"
}
if ($NoPrompt) {
    $cmdline += " -y"
}
if ($NoModifyPath) {
    $cmdline += " --no-modify-path"
}
if ($Verbose) {
    $cmdline += " --verbose"
}
$details = Start-Process -FilePath "$_file" -ArgumentList $cmdline -Wait -NoNewWindow -Passthru

$rc = $details.exitCode
if ($rc -ne 0 ) {
    Write-Host "Elan failed with error code $rc"
    return 1
}

$null = Remove-Item -Recurse -Force "$_dir"

return 0
