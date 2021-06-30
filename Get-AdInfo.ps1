[CmdletBinding()]
param (
	[parameter(Mandatory)][string] $Server,
	[parameter(Mandatory)][pscredential] $Credential,
	[parameter()][string] $OutputFolder = "$($env:USERPROFILE)\Documents",
	[parameter()][switch] $IncludeUsers,
	[parameter()][switch] $IncludeGroups
)
try {
	
	Write-Host "getting forest and domain information"
	$adDomain   = Get-ADDomain -Credential $Credential -Server $Server
	$xlFile     = "$($OutputFolder)\$($adDomain.NetBIOSName)_AD_info.xlsx"
	$dnsSuffix  = $adDomain.Forest

	$adForest   = Get-ADForest -Credential $Credential -Identity $DnsSuffix -Server $Server
	
	Write-Host "getting ad sites"
	$sites      = $adForest.Sites | % {
					Get-ADReplicationSite -Identity $_ -Credential $Credential -Server $server | 
						Select-Object Name
				  }

	$props = $($adForest.psobject.Properties | Where-Object {$_.TypeNameOfValue -eq "System.String"}).Name
	$table = "Name,Value"
	foreach ($p in $props) {
		$v = $adForest.Item("$p")[0]
		$table += "`n`"$p`",`"$v`""
	}
	$forest = $table | ConvertFrom-Csv

	$props = $($adDomain.psobject.Properties | Where-Object {$_.TypeNameOfValue -eq "System.String"}).Name
	$table = "Name,Value"
	foreach ($p in $props) {
		$v = $adDomain.Item("$p")[0]
		$table += "`n`"$p`",`"$v`""
	}
	$domain = $table | ConvertFrom-Csv
	
	Write-Host "getting subnets"
	$subnets    = Get-ADReplicationSubnet -Credential $Credential -Server $server -Filter * |
		Foreach-Object {
			if ([string]::IsNullOrEmpty($_.Site)) {
				$sitename = ""
			} else {
				$sitename = $($_.Site -split ',')[0] -replace 'CN=',''
			}
			[pscustomobject]@{
				Name = $_.Name 
				Site = $sitename
				SiteDN = $_.Site
			}
		}

	Write-Host "getting org units"
	$ous = Get-ADOrganizationalUnit -Credential $Credential -Filter * -Server $Server | Select-Object Name,DistinguishedName

	Write-Host "getting domain controllers"
	$dclist = Get-ADDomainController -Credential $Credential -Filter * -Server $Server |
		Select-Object Name,Domain,Site,HostName,IPv4Address,IsGlobalCatalog,IsReadOnly,OperatingSystem,OperatingSystemVersion,OperationsMasterRoles |
			% {
				[pscustomobject]@{
					Name          = $_.Name
					Domain        = $_.Domain 
					Site          = $_.Site
					HostName      = $_.HostName 
					IPv4Address   = $_.IPv4Address
					GlobalCatalog = $_.IsGlobalCatalog
					ReadOnly      = $_.IsReadOnly 
					OS            = $_.OperatingSystem 
					OSVersion     = $_.OperatingSystemVersion 
					FSMORoles     = $($_.OperationsMasterRoles -join ',')
				}
			}

	Write-Host "getting computers"
	$comps = Get-ADComputer -Credential $Credential -Filter * -Properties lastLogonTimestamp,operatingSystem,operatingSystemVersion,description -Server herrier | 
		Select-Object Name,DNSHostName,Enabled,SID,ObjectGUID,DistinguishedName,operatingSystem,operatingSystemVersion,lastLogonTimestamp,description
	$total = $comps.Count
	$i = 1
	$comps = $comps |
		Select-Object Name,lastLogonTimestamp,operatingSystem,operatingSystemVersion,description,distinguishedName,ObjectGUID |
			Foreach-Object {
				#Write-Host "[$i] of [$total] $($_.Name) ..." -ForegroundColor Cyan
				Write-Progress -Activity "Getting AD Computers" -Status "Reading computer" -PercentComplete $(($i/$total)*100) -CurrentOperation "$i of $total"
				if ([string]::IsNullOrEmpty($_.lastLogonTimestamp)) {
					$llogon = $null
					$ldays  = $null
				} else {
					$llogon = $([datetime]::FromFiletime($_.lastlogonTimeStamp)).ToString().Trim()
					$ldays = $(New-TimeSpan -Start $llogon -End (Get-Date)).Days
				}
				[pscustomobject]@{
					Name        = $_.Name
					OSName      = $_.operatingSystem
					OSVersion   = $_.operatingSystemVersion
					Description = $_.description
					GUID        = $_.ObjectGUID
					LastLogon   = $llogon
					LogonDays   = $ldays
					DN          = $_.distinguishedName
				}
				$i++
			}

	if ($IncludeUsers) {
		Write-Host "getting users"
		$users = Get-ADUser -Credential $Credential -Filter * -Properties displayName,lastLogonTimestamp,description -Server $Server
		$total = $users.Count
		$i = 1
		$users = $users |
			Select-object SamAccountName,GivenName,SurName,UserPrincipalName,displayName,description,Enabled,SID,ObjectGUID,lastLogonTimestamp,distinguishedName |
				Foreach-Object {
					Write-Progress -Activity "Getting AD Computers" -Status "Reading user" -PercentComplete $(($i/$total)*100) -CurrentOperation "$i of $total"
					if ([string]::IsNullOrEmpty($_.lastLogonTimestamp)) {
						$llogon = $null
						$ldays  = $null
					} else {
						$llogon = $([datetime]::FromFiletime($_.lastlogonTimeStamp)).ToString().Trim()
						$ldays = $(New-TimeSpan -Start $llogon -End (Get-Date)).Days
					}
					[pscustomobject]@{
						Name        = $_.SamAccountName
						FirstName   = $_.GivenName
						LastName    = $_.SurName
						UPN         = $_.UserPrincipalName
						Display     = $_.displayName
						Description = $_.description
						Enabled     = $_.Enabled
						SID         = $_.SID
						GUID        = $_.ObjectGUID
						LastLogon   = $llogon
						LogonDays   = $ldays
						DN          = $_.distinguishedName
					}
					$i++
				}
	}

	Write-Host "getting groups"
	$groups = Get-ADGroup -Credential $Credential -Filter * -Server $Server | 
		Where-Object {$_.GroupCategory -eq 'Security'} |
			Select-Object Name,GroupScope,ObjectGUID,DistinguishedName
	Write-Host "exporting data to workbook..."
	$forest | Export-Excel -Path $xlFile -WorksheetName "Forest" -ClearSheet -AutoSize
	$domain | Export-Excel -Path $xlFile -WorksheetName "Domain" -ClearSheet -AutoSize
	$sites | Export-Excel -Path $xlFile -WorksheetName "Sites" -ClearSheet -AutoSize
	$subnets | Select-Object Name,Site | Export-Excel -Path $xlFile -WorksheetName "Subnets" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	$ous | Export-Excel -Path $xlFile -WorksheetName "OrgUnits" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	$comps | Sort-Object Name |
		Export-Excel -Path $xlFile -WorksheetName "Computers" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	if ($IncludeUsers) {
		$users | Sort-Object SamAccountName | 
			Export-Excel -Path $xlFile -WorksheetName "Users" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	}
	if ($IncludeGroups) {
		$groups | Sort-Object Name |
			Export-Excel -Path $xlFile -WorksheetName "Groups" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	}
}
catch {
	Write-Error $_.Exception.Message 
}

$props = $($adForest.psobject.Properties | Where-Object {$_.TypeNameOfValue -eq "System.String"}).Name
$table = "Name,Value"
foreach ($p in $props) {
	$v = $adForest.Item("$p")[0]
	$table += "`n`"$p`",`"$v`""
}
