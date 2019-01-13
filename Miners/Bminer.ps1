if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Bminer1141\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-lite-v11.4.1-c19297e-CUDA-9.2-amd64.zip"
$Commands = [PSCustomObject]@{
    #"equihashBTG" = " -uri zhash://" #EquihashBTG(miniZ faster)
    #"equihash" = " -uri stratum://" #Equihash(Asic)
    #"equihash144" = " -pers auto -uri equihash1445://" #Equihash144(miniZ faster)
    #"zhash" = " -pers auto -uri equihash1445://" #Zhash(miniZ faster)
    #"ethash" = " -uri ethstratum://" #Ethash(ethminer faster)
    "aeternity" = " -uri aeternity://" #aeternity(testing)
    "beam" = " -uri beam+ssl://" #beam(testing)
    
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.(Get-Algorithm($_)).User):$($Pools.(Get-Algorithm($_)).Pass.ToString().replace(',','%2C'))@$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -max-temperature 94 -devices $($Config.SelGPUCC) -api 127.0.0.1:$Port"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .98} # substract 2% devfee 
        API       = "bminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
