<#
.SYNOPSIS
	2-step AD computer cleanup script
.DESCRIPTION
	Disable and Move computers which haven't logged on for at least [LastLogonDays] days
	Delete disabled computers in the [DisabledOU] OU after [GracePeriodDays] days
.PARAMETER DisabledOU
	LDAP OU path where disabled computers are stored
.PARAMETER LastLogonDays
	Number of days since last logon to consider stale
.PARAMETER GracePeriodDays
	Number of days since being disabled to consider for deletion
.PARAMETER Attribute
	LDAP attribute to use for entering disabled timestamp value
.PARAMETER ExcludeServers
	Ignore server computers
.PARAMETER LogPath
	Path where log file is created
.EXAMPLE
	.\Clean-AdComputerAccounts.p1 -WhatIf
	run scan without making any changes or deletions
.EXAMPLE
	.\Clean-AdComputerAccounts.ps1
	process computers and apply changes and deletions
.NOTES
	0.9.1 - 2021-06-15 - https://github.com/Skatterbrainz/ActiveDirectory

	NO WARRANTY OR GUARANTEE PROVIDED OF ANY KIND, FOR ANY PURPOSE, OR HALLUCINATIONS THAT YOU MAY HAVE.
	USE AT YOUR OWN RISK - TEST THE LIVING SHIT OUT OF THIS BEFORE USING IN ANY PRODUCTION ENVIRONMENT.
#>
[CmdletBinding()]
param(
	[parameter(Mandatory=$False)][string]$DisabledOU = "OU=Computers,OU=Disabled,dc=contoso,dc=local",
	[parameter(Mandatory=$False)][int]$LastLogonDays = 90,
	[parameter(Mandatory=$False)][int]$GracePeriodDays = 60,
	[parameter(Mandatory=$False)][string]$Attribute = "description",
	[parameter(Mandatory=$False)][Boolean]$ExcludeServers = $True,
	[parameter(Mandatory=$False)][string]$label = "disabled on:",
	[parameter(Mandatory=$False)][string]$LogPath = "$($env:TEMP)"
)

[string]$LogFile = Join-Path -Path $LogPath -ChildPath "cleanup_ad_computers_$(Get-Date -f 'yyyyMMdd-hhmm').log"

function Write-LogFile {
	param(
		[parameter(Mandatory=$False)][string][ValidateSet('INFO','WARNING','ERROR')]$Category = 'INFO',
		[parameter(Mandatory=$False)][string]$Message = ""
	)
	$txt = "$(Get-Date -f 'yyyy-MM-dd hh:mm:ss') - $Category - $Message"
	Write-Verbose $txt
	$txt | Out-File -FilePath $LogFile -Append
}

try {
	Write-LogFile "**** begin processing ****"
	[array]$disabled = Get-ADComputer -Filter * -Properties "$Attribute","operatingSystem" | Where-Object {$_.Enabled -ne $True}
	if ($ExcludeServers -eq $True) {
		[array]$disabled = $disabled | Where-Object {$_.operatingSystem -notlike '*server*'}
	}
	Write-LogFile "$($disabled.Count) disabled computers found"

	[array]$active = Get-ADComputer -Filter * -Properties "$Attribute","operatingSystem","lastLogonTimestamp" | Where-Object {$_.Enabled -eq $True}
	if ($ExcludeServers -eq $True) {
		[array]$active = $active | Where-Object {$_.operatingSystem -notlike '*server*'}
	}
	Write-LogFile "$($active.Count) active computers found"

	Write-LogFile "processing disabled computers by attribute label: $Attribute"

	foreach ($computer in $disabled) {
		Write-LogFile "checking computer: $($computer.DistinguishedName)"
		$timestamp = $computer."$Attribute"
		if (![string]::IsNullOrEmpty($timestamp)) {
			[datetime]$tval = $timestamp -replace $label, ""
			[int]$days = (New-TimeSpan -Start $tval -End (Get-Date)).Days
			if ($days -ge $GracePeriodDays) {
				Write-LogFile "deleting computer: $($computer.DistinguishedName)"
			} else {
				Write-LogFile "still $($GracePeriodDays - $days) days from deletion date"
			}
		} else {
			Write-LogFile "attribute label does not contain a timestamp"
		}
	}

	Write-LogFile "processing active computers by lastLogonTimestamp"

	foreach ($computer in $active) {
		Write-LogFile "checking computer: $($computer.DistinguishedName)"
		[datetime]$lldate = [datetime]::FromFileTime($computer.lastLogonTimestamp)
		[int]$days = (New-TimeSpan -Start $lldate -End (Get-Date)).days
		Write-LogFile "last logon was: $lldate ($days days ago)"
		if ($days -ge $LastLogonDays) {
			$target = Get-ADOrganizationalUnit -Identity $DisabledOU
			Write-LogFile "moving computer $($computer.name)"
			Get-ADComputer $computer.name | Move-ADObject -TargetPath $target.DistinguishedName -ErrorAction Stop
		} else {
			Write-LogFile "no action required on this computer account"
		}
	}

	Write-LogFile "**** processing completed successfully ****"
}
catch {
	Write-Error $_.Exception.Message
}