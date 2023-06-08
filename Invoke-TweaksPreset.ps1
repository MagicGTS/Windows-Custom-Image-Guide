#requires -version 5.1
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
try {
    $Tweaks = Get-Content -Raw "my_tweaks.json" | ConvertFrom-Json    
    Write-Warning "Loading Tweaks from 'my_tweaks.json'"
}
catch {
    Get-Volume | Where-Object { $null -ne $_.DriveLetter -and "OK" -eq $_.OperationalStatus -and (Test-Path -Path ($_.DriveLetter + ":\my_tweaks.json")) } | `
        Select-Object -First 1 | ForEach-Object {
        $Path = ($_.DriveLetter + ":\my_tweaks.json")
        Write-Warning "Loading Tweaks from '$Path'"
        $Tweaks = Get-Content -Raw $Path | ConvertFrom-Json
    }
}
if ($null -eq $Tweaks) {
    try {
        $Tweaks = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/tweaks.json").Content | ConvertFrom-Json
    }
    catch {
        $Tweaks = Get-Content -Raw "tweaks.json" | ConvertFrom-Json
    }
}
try {
    $Presets = Get-Content -Raw "my_presets.json" | ConvertFrom-Json
    Write-Warning "Loading Presets from 'my_presets.json'"
}
catch {
    Get-Volume | Where-Object { $null -ne $_.DriveLetter -and "OK" -eq $_.OperationalStatus -and (Test-Path -Path ($_.DriveLetter + ":\my_presets.json")) } | `
        Select-Object -First 1 | ForEach-Object {
        $Path = ($_.DriveLetter + ":\my_presets.json")
        Write-Warning "Loading Presets from '$Path'"
        $Presets = Get-Content -Raw $Path | ConvertFrom-Json
    }
}

if ($null -eq $Presets) {
    try {
        $Presets = (Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/winutil/raw/main/config/preset.json").Content | ConvertFrom-Json
    }
    catch {
        $Presets = Get-Content -Raw "presets.json" | ConvertFrom-Json
    }
}
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
        Invoke-Expression ((Invoke-WebRequest -Uri $Function.URI).Content)
    }
    catch {
        Invoke-Expression (Get-Content -Raw $Function.LOCAL)
    }
}
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
        $Presets
    )

    process {
        Clear-Host
        $Selections = @{}
        $Count = 1
        Write-Host "================ $Title ================"
        $Presets.psobject.properties | ForEach-Object {
            $Selections[$Count] = $_.Name
            Write-Host "Press $($Count) for '$($_.Name)' option."
            $Count++
        }
        Write-Host "Press 'Q' to quit."
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
        $Presets
    )

    process {
        $Selected = $false
        do {
            $Selections = Show-Menu -Presets $Presets
            $InKey = Read-Host -Prompt "Please make a selection"
            if ([string]$InKey -like 'q') {
                $Selected = $true
                $InKey = -1
                exit
            }
            elseif ($Selections.Keys -contains $InKey) {
                Write-Host "You chose option $($Selections[[int]$InKey])"
                $Selected = $true
            }
            else {
                Write-Error "Undefined option."
            }
        }
        while ($false -eq $Selected)
        Write-Output $Selections[[int]$InKey]
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

# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU52+iIucQn9VouZq9UYEhF0iK
# 5XqgggMkMIIDIDCCAgigAwIBAgIQJFLrNx0RFpdMoK+RvM3T9zANBgkqhkiG9w0B
# AQsFADAoMSYwJAYDVQQDDB1MZXNoa2V2aWNoIEFuZHJldyBDb2RlU2lnbmluZzAe
# Fw0yMzAyMDMwNTU5MjJaFw0yNDAyMDMwNjE5MjJaMCgxJjAkBgNVBAMMHUxlc2hr
# ZXZpY2ggQW5kcmV3IENvZGVTaWduaW5nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAyp4Fyt1BJYGUMh7Jf3UOBjZpNvrrE19pYQQ3Zo832VOMeIbwmF3t
# jv7ivhdRRq9PgEibHAiwxaQ5BXnilYcvcQGZRzq9fvC6W6RRBuvu58hXuZaaFGTU
# 4MMmwll51p8VKmc8SXAyBAaNE0bHzrCcFZNZMsbXPIPLPm0f2SyulJhRHNC7pjLZ
# gAbL5/GblkV1UxQasfgj/dmb1mfGkSWrSwyTf16tN/uAEgfyJHscACuYI5wGTV2i
# RAXpee4RDATVsGYYCrnaWix/LNwyw5rifGJVBC4wWIMkwGgJ57EC8wTk6HeoJ5fH
# k6ERpjLmISa48/LnuqiPKI2MhPSXfP8APQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFCWs8XDc7EKsNg9F51zX
# jdZWoGedMA0GCSqGSIb3DQEBCwUAA4IBAQCdzQF4goyDj/U3ZQsyjlNOmh0XAu5z
# 1dkMAwa11a6KljUMOl9jCUFS+hKUnbwaJ9JKCr2+UUVeqAFGpggiw2ustZP49I8P
# 5ZVZxqwXlSEqepBvRVsDyXXOcXq76Bx/bs2OZd4nr+6Luha3de4fBSIZwZ8JB20V
# 9oKWxNZ7vpfJCe1fFRNEQLSeUIScUJFquTExNr5RorYvv+D6YTp3u1hSiYdDs4D8
# rWJuYjUYBYZ/KgAE0MBiAwqOxDanmuMqCSe4VGU3ZoDG0Rcx4H9Esh0lbukZFbk2
# V8Hg18XvsH9Ibf6Qm0TTmKK6/bE/sHrGYvJjCdsq7uR6nnlp6xJkqrwiMYIB3TCC
# AdkCAQEwPDAoMSYwJAYDVQQDDB1MZXNoa2V2aWNoIEFuZHJldyBDb2RlU2lnbmlu
# ZwIQJFLrNx0RFpdMoK+RvM3T9zAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUyaLV924j6dt4SGAq
# /WRGgFORf1QwDQYJKoZIhvcNAQEBBQAEggEAW8gd7naxChH3ENurk1W+PinUBKv1
# zgsZMQGLTTMGvnjTGbgL7x1n83fGRRtQl85lup0cVwaU3+q/QeLEwmkeSw8f7FhJ
# bYtiP/BYrcE8LLNv8PdaB+zRVlkLxakjftDSsk+UkO9U+FbP+MKq2TShRwRgknwK
# Dq6JIrLD4nA3IiIvLjqR8166g2rjLAr9Cy82fkxvjOSl9lQTUrWwpVd2Cui0RKYq
# BGkfGDhOCdqwcdxgm6n+uhmTn0j9iBKoCIABBIc+ywZNnwvFPK5TjPu6YHDyAK28
# vSeWJKgwcG3u6VaIIVW/fc9McWM2GWO6sKyPp+0ppOTVPvSvi46xwxpkxg==
# SIG # End signature block
