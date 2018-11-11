param (
    [string] $GroupName = ""
)
if ([string]::IsNullOrEmpty($GroupName)) {
    $strFilter = "(objectCategory=group)"
}
else {
    $strFilter = "(&(objectCategory=group)(sAMAccountName=$GroupName))"
}

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.Filter = $strFilter
$objSearcher.PageSize = 1000
$objPath = $objSearcher.FindAll()

foreach ($objItem in $objPath) {
    try {
        $objUser = $objItem.GetDirectoryEntry()
        $group   = [adsi]$($objUser.distinguishedName).ToString()
        $Group.Member | ForEach-Object {
            $Searcher = [adsisearcher]"(distinguishedname=$_)"
            $searcher.FindOne().Properties
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }

}
