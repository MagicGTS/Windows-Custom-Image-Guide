#requires -version 5.1
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
<# if (!
    #current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
        #is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    #elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
        #flatten to single array
        '-File', $MyInvocation.MyCommand.Source, $args `
        | % { $_ }
    ) `
        -Verb RunAs
    exit
} #>
. .\Invoke-TweaksPreset.ps1
$Preset = Invoke-Menu -Presets $Presets
Invoke-TweaksPreset -TweaksList $Presets[$Preset] -TweaksDefenitions $Tweaks
if (Test-Path -Path ".selfdestroy") {
    Write-Warning "I have all done here and must go away. Goodby."
    @(
        "Set-WinUtilRegistry.ps1",
        "Set-WinUtilScheduledTask.ps1",
        "Set-WinUtilService.ps1",
        "Remove-WinUtilAPPX.ps1",
        "Invoke-WinUtilScript.ps1",
        "Apply-Tweaks.ps1",
        "Invoke-TweaksPreset.ps1",
        ".selfdestroy",
        "tweaks.json"
    ) | ForEach-Object {
        Remove-Item -Path $_ -Force
    }
}