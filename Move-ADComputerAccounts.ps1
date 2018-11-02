#requires -RunAsAdministrator
#requires -version 3.0
<#
.DESCRIPTION
  Query AD Computers which haven't logged on in X days and move them to some shithole OU
  so when the lazy bastards finally come whining about why their crappy little turdbox won't
  log onto the domain anymore, you can take their picture to post under 'lazy idiots' section
  of your company intranet.
.PARAMETER TargetOU
.PARAMETER DaysOld
#>

[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [parameter(Mandatory=$False, HelpMessage="LDAP OU path")]
        [ValidateNotNullOrEmpty()]
        [string] $TargetOU = "OU=OldComputers,DC=contoso,DC=local",
    [parameter(Mandatory=$False, HelpMessage="How many days old")]
        [ValidateRange(0,1000)]
        [int] $DaysOld = 90
)

$oldComputers = .\tools\Get-ADsComputers.ps1 | 
    Where-Object { (New-TimeSpan -Start $_.LastLogon -End $(Get-Date)).Days -gt $DaysOld }

Write-Host "$($oldComputers.Count) computers haven't logged onto the domain in $DaysOld days" -ForegroundColor Magenta

foreach ($computer in $oldComputers) {
    Write-Verbose "computer = $computer"
    #Write-Verbose "ou path = $OU"
    $CompDN = ([ADSISEARCHER]"sAMAccountName=$($computer)$").FindOne().Path
    if ($CompDN) {
        try {
            $CompObj = [ADSI]"$CompDN"
            $CompObj.psbase.MoveTo([ADSI]"LDAP://$($OU)")
            Write-Output "$ComputerName moved to $OU"
        }
        catch {
            $Error[0].Exception.Message ; Exit 1
        }
    }
    else {
        Write-Warning "$ComputerName not found in AD"
    }
} # foreach
