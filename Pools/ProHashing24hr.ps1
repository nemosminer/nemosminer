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
File:           ProHashing24hr.ps1
Version:        3.9.9.22
Version date:   23 February 2021
#>


using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.UserName) { 
    Try {
        $Request = (Invoke-RestMethod -Uri "https://prohashing.com/api/v1/status" -TimeoutSec 15 -Headers @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }).data
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $PoolHost = "prohashing.com"
    # $PriceField = "actual_last24h"
    $PriceField = "actual_last24h"
    $PoolRegions = "US"
    
    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.estimate_current) -gt 0 } | ForEach-Object {
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolPort = $Request.$_.port

        $Fee = [Decimal]$Request.$_.pps_fee
        $Divisor = [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor)

        ForEach ($Region in $PoolRegions) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Host               = [String]$PoolHost
                Port               = [UInt16]$PoolPort
                User               = [String]$PoolConfig.UserName
                Pass               = "a=$($Algorithm_Norm),n=$($PoolConfig.WorkerName)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateFactor     = [Decimal]1
            }
        }
    }
}