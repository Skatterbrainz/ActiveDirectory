function Get-AdsAccounts {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[ValidateSet('computer','user')]
		[string] $AccountType
	)
	try {
		$as = [adsisearcher]"(objectCategory=$AccountType)"
		$props = @("name","distinguishedName","lastLogonTimeStamp")
		$props | %{ $as.PropertiesToLoad.Add($_) | Out-Null }
		$as.PageSize = 2000
		$accounts = $as.FindAll()
		foreach ($account in $accounts) {
			$name = ($account.Properties.item('name') | Out-String).Trim()
			$dn   = ($account.Properties.item('distinguishedName') | Out-String).Trim()
			$lts  = ($account.Properties.item('lastLogonTimeStamp') | Out-String).Trim()
			$lts  = ([datetime]::FromFileTime($lts))
			$params = [ordered]@{
				Name      = $name
				Type      = $AccountType
				LastLogon = $lts
				DN        = $dn
			}
			New-Object PSObject -Property $params
		}
	}
	catch {
		Write-Error $Error[0].Exception.Message
	}
}
