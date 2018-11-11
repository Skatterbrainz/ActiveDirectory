<#
.DESCRIPTION
  Return AD computers not having logged onto the domain for X days
.PARAMETER DaysOld
  Days since last account login. Default is 30
.PARAMETER RowLimit
  Limit results to prevent performance impact. Default is 100 rows
#>

function Get-OldADComputerAccounts {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$False, HelpMessage="Days since last account login")]
            [ValidateRange(1,3000)]
            [int] $DaysOld = 30,
        [parameter(Mandatory=$False, HelpMessage="Limit results to maximum count")]
            [ValidateRange(1,10000000)]
            [int] $RowLimit = 100
    )
    $as = [adsisearcher]"(&(objectCategory=computer)(lastLogonTimestamp<=$((Get-Date).AddDays(-$DaysOld).ToFileTime())))"
    $as.SizeLimit = $RowLimit
    $as.PropertiesToLoad.AddRange(('name','lastLogonTimestamp','cn','operatingSystem','description'))
    $oldComputers = $as.FindAll()

    $oldComputers |
        ForEach-Object {
            $llogin = ([datetime]::FromFileTime(($_.Properties.Item("lastlogonTimeStamp") | Out-String).Trim()))
            $props = [ordered]@{
                ComputerName    = $_.Properties.Item("name") | Out-String
                OperatingSystem = $_.Properties.Item("operatingSystem") | Out-String
                DN              = $_.Properties.Item("distinguishedName") | Out-String
                LastLogon       = $llogin
            }
            New-Object -TypeName PSObject -Property $props
        }
}
