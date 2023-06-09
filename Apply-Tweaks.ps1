#requires -version 5.1
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
if (!
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
        '-ExecutionPolicy Bypass', '-File', $MyInvocation.MyCommand.Source, $args `
        | % { $_ }
    ) `
        -Verb RunAs
    exit
}
Set-Location -Path $(Split-Path -Path $MyInvocation.MyCommand.Source)
. .\Invoke-TweaksPreset.ps1
$Preset = Invoke-Menu -Presets $Presets -Promt "Please make a selection" -Option "You chose option {0}" -Undefined "Undefined option." `
    -SM_Title "Choose option" -SM_Option "Press {0} for '{1}' option."-SM_Exit "Press 'Q' to quit."
if ($Preset -ne -1){
    Invoke-TweaksPreset -TweaksList $Presets.$Preset -TweaksDefenitions $Tweaks
}
if (Test-Path -Path ".selfdestroy") {
    Write-Warning "I have all done here and must go away. Goodby."
    Sleep -Seconds 5
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