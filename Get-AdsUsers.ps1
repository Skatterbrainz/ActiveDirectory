<#
.DESCRIPTION
    Returns AD LDAP information for User accounts
.PARAMETER UserName
    Optional: name of user to query. Default is all users
.EXAMPLE
    $x = .\Get-ADsUsers.ps1
.EXAMPLE
    $x = .\Get-ADsUsers.ps1 -UserName "jsmith"
.EXAMPLE
    $staff = .Get-ADsUsers.ps1 | ?{$_.Manager -eq 'CN=John Smith,OU=Users,OU=CORP,DC=contoso,DC=local'}
.NOTES
    1.0.0 - DS - Initial release
    1.0.1 - DS - Added UserName parameter for focused search
#>

[CmdletBinding()]
param (
    [parameter(Mandatory=$False, HelpMessage="Optional user name")]
    [string] $UserName = ""
)
$pageSize = 1000
if ([string]::IsNullOrEmpty($UserName)) {
    $as = [adsisearcher]"(objectCategory=User)"
}
else {
    $as = [adsisearcher]"(&(objectCategory=User)(sAMAccountName=$UserName))"
}
$as.PropertiesToLoad.Add('cn') | Out-Null
$as.PropertiesToLoad.Add('lastlogonTimeStamp') | Out-Null
$as.PropertiesToLoad.Add('whenCreated') | Out-Null
$as.PropertiesToLoad.Add('department') | Out-Null
$as.PropertiesToLoad.Add('title') | Out-Null
$as.PropertiesToLoad.Add('mail') | Out-Null
$as.PropertiesToLoad.Add('manager') | Out-Null
$as.PropertiesToLoad.Add('employeeID') | Out-Null
$as.PropertiesToLoad.Add('displayName') | Out-Null
$as.PropertiesToLoad.Add('distinguishedName') | Out-Null
$as.PageSize = 1000
$results = $as.FindAll()
foreach ($item in $results) {
    $cn = ($item.properties.item('cn') | Out-String).Trim()
    [datetime]$created = ($item.Properties.item('whenCreated') | Out-String).Trim()
    $llogon = ([datetime]::FromFiletime(($item.properties.item('lastlogonTimeStamp') | Out-String).Trim())) 
    $ouPath = ($item.Properties.item('distinguishedName') | Out-String).Trim() -replace $("CN=$cn,", "")
    $props  = [ordered]@{
        Name        = $cn
        DisplayName = ($item.Properties.item('displayName') | Out-String).Trim()
        Title       = ($item.Properties.item('title') | Out-String).Trim()
        Department  = ($item.Properties.item('department') | Out-String).Trim()
        EmployeeID  = ($item.Properties.item('distinguishedName') | Out-String).Trim()
        Email       = ($item.Properties.item('mail') | Out-String).Trim()
        Manager     = ($item.Properties.item('manager') | Out-String).Trim()
        OUPath      = $ouPath
        Created     = $created
        LastLogon   = $llogon
    }
    New-Object psObject -Property $props
}
