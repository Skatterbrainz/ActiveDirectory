<#
.DESCRIPTION
	Display summary of last-login age (days) for computer accounts in AD
.PARAMETER DaysOld
	Optional: Filter on accounts with last-login older than DaysOld (days)
	Default is group and show counts by 30,60,90,180,365,720 days etc.
.PARAMETER Detailed
	Show detailed LDAP information for accounts with last-login older than DaysOld
.EXAMPLE
	.\Get-ADsComputer-LastLoginSummary.ps1
.EXAMPLE
	.\Get-ADsComputer-LastLoginSummary.ps1 -DaysOld 180 -Detailed
.NOTES
	1.0.0 - DS - Initial release
	1.0.1 - DS - Added Detailed parameter
#>
[CmdletBinding()]
param (
	[parameter(Mandatory=$False, HelpMessage="Age of last login in days")]
	[ValidateRange(0,3000)]
	[int] $DaysOld = 60,
	[parameter(Mandatory=$False, HelpMessage="Show individual accounts")]
	[switch] $Detailed
)
function Get-Pct {
	param (
		[parameter(Mandatory=$True, HelpMessage="Index of current item within total number of items")]
		[int]$HowMany, 
		[parameter(Mandatory=$True, HelpMessage="Total number of items")]
		[int]$TotalNumber
	)
	if ($HowMany -gt 0 -and $TotalNumber -gt 0) {
		Write-Output "$([math]::Round($($HowMany / $TotalNumber)*100,0))`%"
	}
}

Write-Host "getting computer accounts from active directory..." -ForegroundColor Cyan
$all = .\tools\Get-AdsComputers.ps1
$xcount = $all.Count
Write-Verbose "$xcount accounts returned from query"

$tcount = 0
$l30  = 0
$c60  = 0
$c90  = 0
$c180 = 0
$c365 = 0
$c720 = 0

foreach ($computer in $all) {
	Write-Verbose "account: $($computer.Name)"
	$ll  = $($computer.LastLogon).DateTime
	$now = $(Get-Date).DateTime
	$dif = $(New-TimeSpan -Start $ll -End $now).Days
	if ($Detailed) {
		if ($dif -gt $DaysOld) {
			$data = [ordered]@{
				ComputerName = $computer.Name
				LastLogon    = $ll
			}
			$tcount++
			New-Object PSObject -Property $data
		}
	}
	else {
		if ($dif -le 30)  { $l30++ }
		if ($dif -ge 60)  { $c60++ }
		if ($dif -ge 90)  { $c90++ }
		if ($dif -ge 180) { $c180++ }
		if ($dif -ge 365) { $c365++ }
		if ($dif -ge 720) { $c720++ }
	}
}
if ($Detailed) {
	if ($tcount -gt 0) {
		$pct = [math]::Round($($tcount / $xcount)*100,0)
		Write-Host "$tcount of $($xcount) computers logged on more than $DaysOld days ago $(Get-Pct -HowMany $tcount -TotalNumber $xcount)" -ForegroundColor Cyan
	}
	else {
		Write-Host "$ccount of $($xcount) computers logged on more than $DaysOld days ago" -ForegroundColor Green
	}
}
else {
	$p30  = Get-Pct -HowMany  $l30 -TotalNumber $xcount
	$p60  = Get-Pct -HowMany  $c60 -TotalNumber $xcount
	$p90  = Get-Pct -HowMany  $c90 -TotalNumber $xcount
	$p180 = Get-Pct -HowMany $c180 -TotalNumber $xcount
	$p365 = Get-Pct -HowMany $c365 -TotalNumber $xcount
	$p720 = Get-Pct -HowMany $c720 -TotalNumber $xcount
	Write-Host "$l30 of $xcount less than 30 days ($p30)" -ForegroundColor Cyan
	Write-Host "$c60 of $xcount more than 60 days ($p60)" -ForegroundColor Cyan
	Write-Host "$c90 of $xcount more than 90 days ($p90)" -ForegroundColor Cyan
	Write-Host "$c180 of $xcount more than 180 days ($p180)" -ForegroundColor Cyan
	Write-Host "$c365 of $xcount more than 365 days ($p365)" -ForegroundColor Cyan
	Write-Host "$c720 of $xcount more than 720 days ($p720)" -ForegroundColor Cyan
}