#requires -modules ActiveDirectory
#requires -version 2
<#
.SYNOPSIS
	Returns AD user accounts created on or after a specified date
.DESCRIPTION
	Returns AD user accounts created on or after a specified date
.PARAMETER SinceWhen
	[datetime] (required) Date to query for accounts
.EXAMPLE
	Get-UsersCreatedSince.ps1 -SinceWhen 2/1/2016
#>

param (
	[parameter(Mandatory=$True, HelpMessage="On or After Date")]
	[datetime] $SinceWhen
)
$Ldate = New-Object System.DateTime($SinceWhen.Year,$SinceWhen.Month,$SinceWhen.Day)
Get-ADUser -Properties name,distinguishedName,whenCreated -Filter {(objectClass -eq "user") -and (whenCreated -ge $Ldate)}
