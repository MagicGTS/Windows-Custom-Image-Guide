#requires -version 5.1
using namespace System.Collections.Generic
using namespace System.Management.Automation
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$PSHeader = @'
#requires -version 5.1
using namespace System.Collections.Generic
using namespace System.Management.Automation
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
function Show-Menu {
    <#
    .SYNOPSIS
        Helper function for building simple menu from Presets list.

    .PARAMETER Presets
        The psobject of tweaks presets.

    .OUTPUTS
        Returns hatable contained indexes and names

    .EXAMPLE
        Show-Menu -Presets $Presets

    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [psobject]
        $Presets,
        $Title = "Choose option",
        $Option = "Press {0} for '{1}' option.",
        $Exit = "Press 'Q' to quit."
    )

    process {
        Clear-Host
        $Selections = @{}
        $Count = 1
        Write-Host $("================ {0} ================" -f $Title)
        $Presets.psobject.properties | ForEach-Object {
            $Selections[$Count] = $_.Name
            Write-Host $($Option -f $Count,$_.Name)
            $Count++
        }
        Write-Host $Exit
        Write-Output $Selections
    }
}
function Invoke-Menu {
    <#
    .SYNOPSIS
        Helper function for invoke simple menu.

    .PARAMETER Presets
        The psobject of tweaks presets.

    .OUTPUTS
        Returns string with selected name

    .EXAMPLE
        Invoke-Menu -Presets $Presets

    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [psobject]
        $Presets,
        $Promt = "Please make a selection",
        $Option = "You chose option {0}",
        $Undefined ="Undefined option.",
        $SM_Title = "Choose option",
        $SM_Option = "Press {0} for '{1}' option.",
        $SM_Exit = "Press 'Q' to quit."
    )

    process {
        $Selected = $false
        do {
            $Selections = Show-Menu -Presets $Presets -Title $SM_Title -Option $SM_Option -Exit $SM_Exit
            $InKey = Read-Host -Prompt $Promt
            if ([string]$InKey -like 'q') {
                $Selected = $true
                $InKey = 100
            }
            elseif ($Selections.Keys -contains $InKey) {
                Write-Host $( $Option -f $Selections[[int]$InKey])
                $Selected = $true
            }
            else {
                Write-Host -ForegroundColor Red $Undefined
                Sleep -Seconds 5
            }
        }
        while ($false -eq $Selected)
        if ($InKey -lt 100) {
            Write-Output $Selections[[int]$InKey]
        }
        else {
            Write-Output 100
        }
    }
}
function Invoke-TweaksPreset {

    <#
    .SYNOPSIS
        Helper function for running tweaks from the tweak list.

    .PARAMETER TweaksList
        The array of tweaks names to execute.

    .PARAMETER TweaksDefenitions
        The pscustomobject contains a tweak`s definition

    .EXAMPLE
        Invoke-TweaksPreset -TweaksList $Presets.desktop -TweaksDefenitions $Tweaks
        Invoke-TweaksPreset -TweaksList @("WPFEssTweaksHiber") -TweaksDefenitions $Tweaks

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [array]
        $TweaksList,
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [psobject]
        $TweaksDefenitions
    )

    process {
        $Values = @{
            Registry      = "Value"
            ScheduledTask = "State"
            Service       = "StartupType"
        }
        $TweaksList | ForEach-Object {
            $TweakName = $_
            if ($null -ne $TweaksDefenitions.$TweakName) {
                $Tweak = $TweaksDefenitions.$TweakName
                if ($Tweak.registry) {
                    $Tweak.registry | ForEach-Object {
                        Set-WinUtilRegistry -Name $_.Name -Path $_.Path -Type $_.Type -Value $_.$($Values.registry)
                    }
                }

                if ($Tweak.ScheduledTask) {
                    $Tweak.ScheduledTask | ForEach-Object {
                        Set-WinUtilScheduledTask -Name $_.Name -State $_.$($Values.ScheduledTask)
                    }
                }
                if ($Tweak.service) {
                    $Tweak.service | ForEach-Object {
                        Set-WinUtilService -Name $_.Name -StartupType $_.$($Values.Service)
                    }
                }
                if ($Tweak.appx) {
                    $Tweak.appx | ForEach-Object {
                        Remove-WinUtilAPPX -Name $_
                    }
                }
                if ($Tweak.InvokeScript) {
                    $Tweak.InvokeScript | ForEach-Object {
                        $Scriptblock = [scriptblock]::Create($_)
                        Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $CheckBox
                    }
                }
            }
            else {
                Write-Warning "Can not find `'$TweakName`' in TweaksDefenitions"
            }
        }
    }
}
'@
$Output = ".\tweaker.ps1"
$PSHeader | Out-File $Output -Encoding Unicode
@(
    @{
        URI   = "https://github.com/ChrisTitusTech/winutil/raw/main/functions/private/Set-WinUtilRegistry.ps1";
        LOCAL = "Set-WinUtilRegistry.ps1"
    },
    @{
        URI   = "https://github.com/ChrisTitusTech/winutil/raw/main/functions/private/Set-WinUtilScheduledTask.ps1";
        LOCAL = "Set-WinUtilScheduledTask.ps1"
    },
    @{
        URI   = "https://github.com/ChrisTitusTech/winutil/raw/main/functions/private/Set-WinUtilService.ps1";
        LOCAL = "Set-WinUtilService.ps1"
    },
    @{
        URI   = "https://github.com/ChrisTitusTech/winutil/raw/main/functions/private/Remove-WinUtilAPPX.ps1";
        LOCAL = "Remove-WinUtilAPPX.ps1"
    },
    @{
        URI   = "https://github.com/ChrisTitusTech/winutil/raw/main/functions/private/Invoke-WinUtilScript.ps1";
        LOCAL = "Invoke-WinUtilScript.ps1"
    },
    @{
        URI   = "https://github.com/ChrisTitusTech/winutil/raw/main/functions/public/Invoke-WPFUltimatePerformance.ps1";
        LOCAL = "Invoke-WPFUltimatePerformance.ps1"
    }
) | ForEach-Object {
    $Function = $_
    try {
        (Invoke-WebRequest -Uri $Function.URI).Content | Out-File $Output -Append -Encoding Unicode
    }
    catch {
        Get-Content -Raw $Function.LOCAL | Out-File $Output -Append -Encoding Unicode
    }
}

"`$Tweaks = @'" | Out-File $Output -Append -Encoding Unicode
(Get-Content -Raw "my_tweaks.json").replace("'","''") | Out-File $Output -Append -Encoding Unicode
"'@ | ConvertFrom-Json" | Out-File $Output -Append -Encoding Unicode

"`$Presets = @'" | Out-File $Output -Append -Encoding Unicode
(Get-Content -Raw "my_presets.json").replace("'","''") | Out-File $Output -Append -Encoding Unicode
"'@ | ConvertFrom-Json" | Out-File $Output -Append -Encoding Unicode
@'
$Preset = Invoke-Menu -Presets $Presets -Promt "Please make a selection" -Option "You chose option {0}" -Undefined "Undefined option." `
    -SM_Title "Choose option" -SM_Option "Press {0} for '{1}' option."-SM_Exit "Press 'Q' to quit."
if ($Preset -ne 100){
    Invoke-TweaksPreset -TweaksList $Presets.$Preset -TweaksDefenitions $Tweaks
}
Write-Warning "I have all done here and must go away. Goodby."
Remove-Item -Path $MyInvocation.MyCommand.Source -Force

Sleep -Seconds 5
'@ | Out-File $Output -Append -Encoding Unicode
