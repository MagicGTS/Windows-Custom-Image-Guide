#requires -version 5.1
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$Tweaks = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/tweaks.json").Content | ConvertFrom-Json
$Presets = @"
{
    "desktop": [
      "WPFEssTweaksAH",
      "WPFEssTweaksDVR",
      "WPFEssTweaksHiber",
      "WPFEssTweaksHome",
      "WPFEssTweaksLoc",
      "WPFEssTweaksOO",
      "WPFEssTweaksRP",
      "WPFEssTweaksServices",
      "WPFEssTweaksStorage",
      "WPFEssTweaksTele",
      "WPFEssTweaksWifi",
      "WPFMiscTweaksPower",
      "WPFMiscTweaksNum"
    ],
    "laptop": [
      "WPFEssTweaksAH",
      "WPFEssTweaksDVR",
      "WPFEssTweaksHome",
      "WPFEssTweaksLoc",
      "WPFEssTweaksOO",
      "WPFEssTweaksRP",
      "WPFEssTweaksServices",
      "WPFEssTweaksStorage",
      "WPFEssTweaksTele",
      "WPFEssTweaksWifi",
      "WPFMiscTweaksLapPower",
      "WPFMiscTweaksLapNum"
    ],
    "minimal": [
      "WPFEssTweaksHome",
      "WPFEssTweaksOO",
      "WPFEssTweaksRP",
      "WPFEssTweaksServices",
      "WPFEssTweaksTele"
    ]
  }
"@ | ConvertFrom-Json

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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUE8ULVSoMuCL2oBeK5nUu5+0J
# VvWgggMkMIIDIDCCAgigAwIBAgIQJFLrNx0RFpdMoK+RvM3T9zANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUtPJs5NkiWDO/E3Di
# RWfJACiVgIkwDQYJKoZIhvcNAQEBBQAEggEAudJvxp29FezWwSvTYTiQatUVBLO8
# FZB5/6cC58Xi6WZoMhtIeI/pIQvnvPpEF7ipbwFhkL1Rz0eRVXuA0gE1WhrGPWgt
# YJdPUU0oJGgRjoew/CW1kB0LF5IG/VHudaSaYuoPJYDrKaxXETyk1tj4kFxk8+kP
# e/q4GCne+Li8YdWnk4RbTzW1nwetPdHj83zGSSnqh56W7mVA9RzEBySzRRFUyd+3
# AiQ+9IrmpAaN1WE5qMVCFMAbmVZHX3IWli7ORbeZdPcQvE0FEtUxuiQwfz7KwxbG
# 3yWi7uACWzwOri5z22ifgrVV5YpLJCHwBYVTGq7tt/uXzLjlX9mosAn/yQ==
# SIG # End signature block