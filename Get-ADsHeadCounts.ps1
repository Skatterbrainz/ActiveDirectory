function Get-AdsComputers {
    [CmdletBinding()]
    param ()
    $as = [adsisearcher]"(objectCategory=computer)"
    [void]$as.PropertiesToLoad.Add('cn')
    [void]$as.PropertiesToLoad.Add('lastlogonTimeStamp')
    [void]$as.PropertiesToLoad.Add('whenCreated')
    [void]$as.PropertiesToLoad.Add('dnsHostName')
    [void]$as.PropertiesToLoad.Add('operatingSystem')
    [void]$as.PropertiesToLoad.Add('operatingSystemVersion')
    [void]$as.PropertiesToLoad.Add('distinguishedName')
    [void]$as.PropertiesToLoad.Add('servicePrincipalName')
    $as.PageSize = 2000
    $results = $as.FindAll()
    foreach ($item in $results) {
        $cn  = ($item.Properties.item('cn') | Out-String).Trim()
        $dn  = ($item.Properties.item('distinguishedName') | Out-String).Trim()
        $os  = ($item.Properties.item('operatingSystem') | Out-String).Trim()
        $osv = ($item.Properties.item('operatingSystemVersion') | Out-String).Trim()
        $ll  = ([datetime]::FromFileTime(($item.Properties.item('lastLogonTimeStamp') | Out-String).Trim()))
        $wc  = ([datetime](($item.Properties.item('whenCreated') | Out-String).Trim()))
        if ($os -match 'server') {
            $ostype = 'Server'
        }
        else {
            $ostype = 'Workstation'
        }
        $props = [ordered]@{
            Name      = $cn
            DN        = $dn
            OS        = $os
            OSVersion = $osv
            OStype    = $ostype
            Created   = $wc
            LastLogon = $ll
        }
        New-Object PSObject -Property $props
    }
}

$adcomps = Get-AdsComputers

$win    = $adcomps | ? {$_.os -match 'windows'}
$other  = $adcomps | ? {$_.os -notmatch 'windows'}
$winsvr = $win | ? {$_.os -match 'server'}
$winwks = $win | ? {$_.os -notmatch 'server'}
$win10  = $win | ? {$_.os -match 'windows 10'}

$ll90   = $adcomps | ? { (New-TimeSpan -Start $_.LastLogon -End (Get-Date)).TotalDays -gt 90 }
$ll180  = $adcomps | ? { (New-TimeSpan -Start $_.LastLogon -End (Get-Date)).TotalDays -gt 180 }

Write-Host "Total Computer Accounts.... $($adcomps.Count)"
Write-Host "Windows computers.......... $($win.Count)"
Write-Host "Non-Windows computers...... $($other.Count)"
Write-Host "Windows Workstations....... $($winwks.Count)"
Write-Host "        Windows 10 only.... $($win10.Count)"
Write-Host "Windows Servers............ $($winsvr.Count)"
Write-Host "Last logon > 90 days....... $($ll90.Count)"
Write-Host "Last logon > 180 days...... $($ll180.Count)"
