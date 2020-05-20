using module ..\Includes\Include.psm1

Try { 
    $Request = Get-Content ((Split-Path -Parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\blockmasters\blockmasters.json") | ConvertFrom-Json 
}
Catch { return }

If (-not $Request) { 
    return
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "blockmasters.co"
$PriceField = "Plus_Price"
# $PriceField = "actual_last24h"
# $PriceField = "estimate_current"
$DivisorMultiplier = 1000000

$Location = "US"

# Placed here for Perf (Disk reads)
$ConfName = If ($Config.PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolHost = "$($HostSuffix)"
    $PoolPort = $Request.$_.port
    $PoolAlgorithm = Get-Algorithm $Request.$_.name
    $Fee = [Decimal]($Request.$_.Fees / 100)

    $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

    If ((Get-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit") -eq $null) { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }
    Else { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }

    $PwdCurr = If ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency } Else { $Config.Passwordcurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

    $Locations = "eu.", ""
    $Locations | ForEach-Object { 
        $Pool_Location = $_

        switch ($Pool_Location) { 
            "eu." { $Location = "EU" }
            "" { $Location = "US" }
        }
        $PoolHost = "$($Pool_Location)$($HostSuffix)"

        If ($PoolConf.Wallet) { 
            [PSCustomObject]@{ 
                Algorithm     = [String]$PoolAlgorithm
                Coin          = [String]$TopCoin.Symbol
                Info          = [String]$TopCoin.Name
                Price         = [Double]($Stat.Live * $PoolConf.PricePenaltyFactor)
                StablePrice   = [Double]$Stat.Week
                MarginOfError = [Double]$Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = [String]$PoolHost
                Port          = [Int]$PoolPort
                User          = $PoolConf.Wallet
                Pass          = "$($WorkerName),c=$($PwdCurr)"
                Location      = [String]$Location
                SSL           = [Bool]$false
                Fee           = $Fee
            }
        }
    }
}
