function Test-AdUser {
    [CmdletBinding(SupportsShouldProcess=$True)]
	param(
        [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string] $UserName
    )
    $tmpuser = $UserName.Split('\')[$UserName.Split('\').Count - 1]
	Write-Host "Searching for AD user: $UserName" -ForegroundColor Green
	$strFilter = "(&(objectCategory=user)(sAMAccountName=$tmpuser))"
    Write-Verbose $strFilter
	$objDomain   = New-Object System.DirectoryServices.DirectoryEntry
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.SearchRoot = $objDomain
	$objSearcher.PageSize = 1000
	$objSearcher.Filter = $strFilter
	$objSearcher.SearchScope = "Subtree"
	$colProplist = "sAMAccountName"
	foreach ($i in $colProplist){$objSearcher.PropertiesToLoad.Add($i) | out-null}
	$colResults = $objSearcher.FindAll()
	Write-Output ($colResults.Count -gt 0)
}
