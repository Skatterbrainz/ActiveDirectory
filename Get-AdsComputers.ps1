<#
.DESCRIPTION
    Returns AD LDAP information for Computer accounts
.PARAMETER ComputerName
    Optional: name of one computer to query. Default is all computers
.EXAMPLE
    $x = .\Get-ADsComputers.ps1
.EXAMPLE
    $x = .\Get-ADsComputers.ps1 -ComputerName "DT12345"
.NOTES
    1.0.0 - DS - initial glue-sniffing disaster that somehow worked
    1.0.1 - DS - added ComputerName param for focused search
#>

[CmdletBinding()]
param (
    [parameter(Mandatory=$False, HelpMessage="Name of computer to query")]
    [string] $ComputerName = ""
)
$pageSize = 200
if (![string]::IsNullOrEmpty($ComputerName)) {
    $as = [adsisearcher]"(&(objectCategory=Computer)(name=$ComputerName))"
}
else {
    $as = [adsisearcher]"(objectCategory=Computer)"
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
