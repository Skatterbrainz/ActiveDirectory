[CmdletBinding()]
param (
    [parameter(Mandatory=$True, HelpMessage="Name of Group")]
    [ValidateNotNullOrEmpty()]
    [string] $GroupName
)
$as = [adsisearcher]"(&(objectCategory=group)(cn=$GroupName))"
$as.PropertiesToLoad.Add('cn') | Out-Null
$as.PropertiesToLoad.Add('distinguishedName') | Out-Null
$as.PageSize = 1000
$results = $as.FindAll()
foreach ($item in $results) {
    $dn = ($item.Properties.item('distinguishedName') | Out-String).Trim()
}
if (![string]::IsNullOrEmpty($dn)) {
    $Group = [ADSI]"LDAP://$dn"
    $Group.Member | ForEach-Object {
        $Searcher = [adsisearcher]"(distinguishedname=$_)"
        $objItem = $searcher.FindOne()
        if ($objItem) {
            [datetime]$created = ($($objItem.Properties).Item('whenCreated') | Out-String)
            $props = [ordered]@{
                UserName    = $($objItem.Properties).Item('sAmAccountName') | Out-String
                CN          = $($objItem.Properties).Item('cn') | Out-String
                DN          = $($objItem.Properties).Item('distinguishedName') | Out-String
                DisplayName = $($objItem.Properties).Item('displayName') | Out-String
                Mail        = $($objItem.Properties).Item('mail') | Out-String
                Telephone   = $($objItem.Properties).Item('telephonenumber') | Out-String
                Manager     = $($objItem.Properties).Item('manager') | Out-String
                Created     = $created
            }
            New-Object -TypeName PSObject -Property $props
        }
    }
}
