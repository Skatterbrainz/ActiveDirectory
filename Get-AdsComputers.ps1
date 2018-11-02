<#
.DESCRIPTION
    Returns AD LDAP information for Computer accounts
.PARAMETER ComputerName
    Optional: name of one computer to query. Default is all computers
.PARAMETER Disabled
    Optional: return only disabled computers (ignores ComputerName input)
.EXAMPLE
    $x = .\Get-ADsComputers.ps1
.EXAMPLE
    $x = .\Get-ADsComputers.ps1 -ComputerName "DT12345"
.EXAMPLE
    $x = .\Get-ADsComputers.ps1 -Disabled
#>

[CmdletBinding()]
param (
    [parameter(Mandatory=$False, HelpMessage="Name of computer to query")]
    [string] $ComputerName = "",
    [switch] $Disabled
)
$pageSize = 200
if (![string]::IsNullOrEmpty($ComputerName)) {
    $as = [adsisearcher]"(&(objectCategory=Computer)(name=$ComputerName))"
}
else {
    if ($Disabled) {
        $as = [adsisearcher]"(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=2))"
    }
    else {
        $as = [adsisearcher]"(objectCategory=Computer)"
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
