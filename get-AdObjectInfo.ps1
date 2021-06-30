function Get-AdObjectInfo {
	param (
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Caption, 
		[parameter(Mandatory=$False)] 
			[string] $ClassName = "user",
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $QueryString,
		[parameter(Mandatory=$False)]
			[string[]] $PropList = "",
		[parameter(Mandatory=$False)]
			[string] $sort = ""
	)
	$rows = 0
	$rootDSE = [adsi]"LDAP://rootDSE"
	$searchBase = "LDAP://$($rootDSE.defaultNamingContext)"
	$query = New-Object System.DirectoryServices.DirectorySearcher
	$query.SearchRoot = $searchBase
	$query.PageSize = 1000
	$query.SizeLimit = 0
	$filter = "(&(objectClass=$ClassName)($QueryString))"
	$query.Filter = $filter
	$query.SearchScope = "subtree"
	$query.PropertiesToLoad.Clear() | Out-Null
	$query.PropertiesToLoad.AddRange($PropList.split(","))
	$res = $query.FindAll()
	$rows = $res.Count
	$query.Dispose()
	return $res
}

$cap = "Domain Controllers"
$plist = "sAMAccountName,operatingSystem,whenCreated"
$qx  = "primaryGroupId=516"
$cls = "computer"



$test = Get-AdObjectInfo -Caption $cap -ClassName $cls -QueryString $qx -PropList $plist

foreach ($pset in $test.Properties.GetEnumerator()) {
	$result = "<table border='1'>"
	foreach ($p in $pset.GetEnumerator()) {
		$pn = $p.Name
		$pv = $p.Value
		$result += "<tr><td>$pn</td><td>$pv</td></tr>"
	}
	$result += "</table>"
	#write-host $pset.Name
	#write-host $pset.Value
}