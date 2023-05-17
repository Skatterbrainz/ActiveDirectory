<#
.SYNOPSIS
	Get last AD login timestamp from all Domain Controllers
.DESCRIPTION
	Get the lastLogon attribute value from all domain controllers in the 
	current AD domain.
.PARAMETER Name
	Required. LDAP (name) attribute value.
.PARAMETER ObjectType
	Optional. LDAP objectClass. Either 'User' or 'Computer'
.EXAMPLE
	Get-LastLogonTime -Name "jsmith"
.EXAMPLE
	Get-LastLogonTime -Name "fs001" -ObjectType 'Computer'
.OUTPUTS
	Array of string values. One from each DC
#>
function Get-LastLogonTime {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)][string]$Name,
		[parameter(Mandatory=$False)][string][ValidateSet('User','Computer')]$ObjectType = 'User'
	)
	switch ($ObjectType) {
		'computer' {
			$(foreach ($DC in ((Get-ADDomainController -Filter * -ErrorAction Stop | Sort-Object name).name) ){ 
				Write-Verbose "querying dc: $dc"
				try {
					$user = $null
					$user = Get-ADComputer $Name -Properties lastlogon -Server $dc -ErrorAction Stop | Select-Object name,lastlogon
					if ($null -ne $user) {
						$att = $(w32tm /ntte $user.lastlogon)
					} else {
						$att = $null
					}
					[pscustomobject]@{
						DC = $DC
						Name = $Name 
						Type = $ObjectType
						LastLogon = $att
					}
				}
				catch {}
			})
		}
		'user' {
			$(foreach ($DC in ((Get-ADDomainController -Filter * -ErrorAction Stop | Sort-Object name).name) ){ 
				Write-Verbose "querying dc: $dc"
				try {
					$user = $null
					$user = Get-ADUser $Name -Properties lastlogon -Server $dc -ErrorAction Stop | Select-Object name,lastlogon
					if ($null -ne $user) {
						$att = $(w32tm /ntte $user.lastlogon)
					} else {
						$att = $null
					}
					[pscustomobject]@{
						DC = $DC
						Name = $Name 
						Type = $ObjectType
						LastLogon = $att
					}
				}
				catch {}
			})
		}
	}
}