<#
.DESCRIPTION
    Returns AD LDAP information for Computer accounts
.PARAMETER ComputerName
    Optional: name of one computer to query. Default is all computers
.PARAMETER SearchType
    List: All, Disabled, Workstations, Servers (default = All)
.EXAMPLE
    $x = .\Get-ADsComputers.ps1
.EXAMPLE
    $x = .\Get-ADsComputers.ps1 -ComputerName "DT12345"
.EXAMPLE
    $x = .\Get-ADsComputers.ps1 -SearchType Disabled
.EXAMPLE
    $x = .\Get-ADsComputers.ps1 -SearchType Servers
#>

[CmdletBinding()]
param (
    [parameter(Mandatory=$False, HelpMessage="Name of computer to query")]
    [string] $ComputerName = "",
    [parameter(Mandatory=$False, HelpMessage="Search type")]
    [ValidateSet('All','Disabled','Workstations','Servers')]
    [string] $SearchType = 'All'
)
$pageSize = 200
if (![string]::IsNullOrEmpty($ComputerName)) {
    $as = [adsisearcher]"(&(objectCategory=Computer)(name=$ComputerName))"
}
else {
    switch ($SearchType) {
        'Disabled' {
            $as = [adsisearcher]"(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=2))"
            break
        }
        'Workstations' {
            $as = [adsisearcher]"(&(objectCategory=computer)(!operatingSystem=*server*))"
            break
        }
        'Servers' {
            $as = [adsisearcher]"(&(objectCategory=computer)(operatingSystem=*server*))"
            break
        }
        default {
            $as = [adsisearcher]"(objectCategory=computer)"
            break
        }
    }
}
$as.PropertiesToLoad.Add('cn') | Out-Null
$as.PropertiesToLoad.Add('lastlogonTimeStamp') | Out-Null
$as.PropertiesToLoad.Add('whenCreated') | Out-Null
$as.PropertiesToLoad.Add('operatingSystem') | Out-Null
$as.PropertiesToLoad.Add('operatingSystemVersion') | Out-Null
$as.PropertiesToLoad.Add('distinguishedName') | Out-Null

$as.PageSize = $pageSize
$results = $as.FindAll()

foreach ($item in $results) {
    $cn = ($item.properties.item('cn') | Out-String).Trim()
    [datetime]$created = ($item.Properties.item('whenCreated') | Out-String).Trim()
    $llogon = ([datetime]::FromFiletime(($item.properties.item('lastlogonTimeStamp') | Out-String).Trim())) 
    $ouPath = ($item.Properties.item('distinguishedName') | Out-String).Trim() -replace $("CN=$cn,", "")
    $props  = [ordered]@{
        Name       = $cn
        OS         = ($item.Properties.item('operatingSystem') | Out-String).Trim()
        OSVer      = ($item.Properties.item('operatingSystemVersion') | Out-String).Trim()
        DN         = ($item.Properties.item('distinguishedName') | Out-String).Trim()
        OU         = $ouPath
        Created    = $created
        LastLogon  = $llogon
    }
    New-Object psObject -Property $props
}
