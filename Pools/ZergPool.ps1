<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru


NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           ZergPool.ps1
Version:        3.9.9.49
Version date:   09 June 2021
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Name_Norm = $Name -replace "24hr" -replace "Coins$"

$PayoutCurrency = $PoolsConfig.$Name_Norm.Wallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Select-Object -Index 0
$Wallet = $PoolsConfig.$Name_Norm.Wallets.$PayoutCurrency

If ($Wallet) { 

    $PayoutThreshold = $PoolsConfig.$Name_Norm.PayoutThreshold.$PayoutCurrency
    If (-not $PayoutThreshold -and $PoolsConfig.$Name_Norm.PayoutThreshold.mBTC) { $PayoutThreshold = $PoolsConfig.$Name_Norm.PayoutThreshold.mBTC / 1000 }
    $PayoutThresholdParameter = ",pl=$([Double]$PayoutThreshold)"

    Try { 
        $Request = Get-Content ((Split-Path -parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Brains\zergpool\zergpool.json") | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "mine.zergpool.com"
    $PriceField = "Plus_Price"
    # $PriceField = "actual_last24h"
    # $PriceField = "estimate_current"
    $DivisorMultiplier = 1000000

    $PoolRegions = "eu", "na", "asia"

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolHost = "$Algorithm.$HostSuffix"
        $PoolPort = $Request.$_.port
        $Updated = $Request.$_.Updated
        $Workers = $Request.$_.workers

        $Fee = [Decimal]($Request.$_.Fees / 100)
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor)

        Try { $EstimateFactor = [Decimal](($Request.$_.actual_last24h / 1000) / $Request.$_.estimate_last24h) }
        Catch { $EstimateFactor = [Decimal]1 }

        If ($Config.UseAnycast -or $PoolsConfig.($Name_Norm -replace '24hr$' -replace 'Coins$').UseAnycast) { 
            $PoolHost = "$Algorithm.$HostSuffix"

            [PSCustomObject]@{ 
                Algorithm                = [String]$Algorithm_Norm
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolsConfig.$Name_Norm.EarningsAdjustmentFactor
                Host                     = [String]$PoolHost
                Port                     = [UInt16]$PoolPort
                User                     = [String]$Wallet
                Pass                     = "$($PoolsConfig.$Name_Norm.WorkerName),c=$PayoutCurrency$PayoutThresholdParameter"
                Region                   = "N/A (Anycast)"
                SSL                      = [Bool]$false
                Fee                      = [Decimal]$Fee
                EstimateFactor           = [Decimal]$EstimateFactor
                Updated                  = [DateTime]$Updated
                Workers                  = [Int]$Workers
            }
        }
        Else { 
            ForEach ($Region in $PoolRegions) { 
                $Region_Norm = Get-Region $Region
                $PoolHost = "$Algorithm.$Region.$HostSuffix"

                [PSCustomObject]@{ 
                    Algorithm                = [String]$Algorithm_Norm
                    Price                    = [Double]$Stat.Live
                    StablePrice              = [Double]$Stat.Week
                    MarginOfError            = [Double]$Stat.Week_Fluctuation
                    EarningsAdjustmentFactor = [Double]$PoolsConfig.$Name_Norm.EarningsAdjustmentFactor
                    Host                     = [String]$PoolHost
                    Port                     = [UInt16]$PoolPort
                    User                     = [String]$Wallet
                    Pass                     = "$($PoolsConfig.$Name_Norm.WorkerName),c=$PayoutCurrency$PayoutThresholdParameter"
                    Region                   = [String]$Region_Norm
                    SSL                      = [Bool]$false
                    Fee                      = [Decimal]$Fee
                    EstimateFactor           = [Decimal]$EstimateFactor
                    Updated                  = [DateTime]$Updated
                    Workers                  = [Int]$Workers
                }
            }
        }
    }
}
