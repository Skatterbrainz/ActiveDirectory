<#
#============================================================================================
filename....... Get-AD-Inventory.ps1

author......... David Stein

organization... En Pointe Technologies

date........... 11/16/2015

modified....... 09/17/2016

version........ 1.0.4

purpose........ Active Directory environment inventory summary

example 1...... Get-AD-Inventory -ReportFile "report2.htm"

example 2...... Get-AD-Inventory -MoreGroups "IT Managers,Desktop Admins"

example 3...... Get-AD-Inventory "report2.htm" "IT Managers,Desktop Admins"

#============================================================================================
#>

PARAM (
    [parameter(Mandatory=$False,Position=0)] [string] $ReportFile='adinventory.htm',
    [parameter(Mandatory=$False,Position=1)] [switch] $AdminGroups = $False,
    [parameter(Mandatory=$False,Position=2)] [string] $MoreGroups = ""
)
$ScriptVersion = "1.0.4"
$ReportTitle = "AD Inventory Report"

$style = "body {
	font-family: verdana,sans;
}

h1,h2,h3 {
	font-family: arial,helvetica,verdana,sans;
}

table {
	width: 850px;
	border-collapse: collapse;
}

td, th {
	border: 1px solid #c0c0c0;
	padding: 5px;
	font-family: verdana,sans;
	font-size: 10pt;
}

.v10 {
	font-family: verdana,sans;
	font-size: 10pt;
}

.pad5 {padding: 5px;}
.w200 {width: 200px;}

.footer {
	font-family: verdana,sans;
	font-size: 10pt;
	text-align: center;
}"

#region check runtime conditions
$ep = Get-ExecutionPolicy
if (($ep -ne 'unrestricted') -and ($ep -ne 'bypass')) {
    Write-Host "Error: Execution Policy is restricted.  Use 'Set-ExecutionPolicy -ExecutionPolicy Bypass'." -ForegroundColor Red -BackgroundColor Black
    Break
}
else {
    Write-Host "Info: Execution Policy is configured to allow processing."
}

$pv = $PSVersionTable.PSVersion.Major 
if ($pv -lt 3) {
    Write-Host "Error: This script requires PowerShell 3.0 or higher." -ForegroundColor Red -BackgroundColor Black
    Break
}
else {
    Write-Host "Info: PowerShell version $pv detected."
}

Import-Module ActiveDirectory -ErrorAction SilentlyContinue
if (!($?)) {
    Write-Host "Error: Must be run from an AD Domain Controller, or workstation with RSAT installed." -ForegroundColor Red -BackgroundColor Black
    Break
}

#endregion

#region get-forests
$adf = Get-ADForest -ErrorAction SilentlyContinue
if ($adf -eq $null) {
    Write-Host "Error: Domain environment could not be accessed" -ForegroundColor Red -BackgroundColor Black
    Break
}
#endregion

#region function definitions
#============================================================================================

function Write-HTML {
    PARAM (
        [parameter(Mandatory=$False,Position=0)] [string] $Message,
        [parameter(Mandatory=$False)] [switch] $Heading,
        [parameter(Mandatory=$False)] [switch] $Footer,
        [parameter(Mandatory=$False)] [switch] $H1,
        [parameter(Mandatory=$False)] [switch] $H2,
        [parameter(Mandatory=$False)] [switch] $H3,
        [parameter(Mandatory=$False)] [switch] $BeginList,
        [parameter(Mandatory=$False)] [switch] $EndList,
        [parameter(Mandatory=$False)] [switch] $PageBreak
    )
    if ($ReportFile.Length -gt 1) {
        if ($Heading -eq $True) {
            Write-HtmlHeading
        }
        elseif ($Footer -eq $True) {
            $rd = (Get-Date).ToLongDateString()
            $rt = (Get-Date).ToLongTimeString()
            $cn = $env:COMPUTERNAME
            "<p class=""footer"">Version $ScriptVersion &copy;2015 En Pointe Technologies</p></body></html>" | 
                Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        elseif ($H1 -eq $True) {
            "<h1>$Message</h1>" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        elseif ($H2 -eq $True) {
            "<h2>$Message</h2>" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        elseif ($H3 -eq $True) {
            "<h3>$Message</h3>" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        elseif ($BeginList -eq $True) {
            "<table class=""t1"">" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        elseif ($EndList -eq $True) {
            "</table>" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        elseif ($PageBreak -eq $True) {
            "<hr />" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
        else {
            $mt = $Message.Replace("~","</td><td class=""pad5 v10"">")
            "<tr><td class=""pad5 v10 w200"">$mt</td></tr>" | Out-File -FilePath $ReportFile -Append -Force -NoClobber
        }
    }
    else {
        Write-Host $Message
    }
}

function Write-Summary {
    $un = $env:USERNAME
    $cn = $env:COMPUTERNAME
    $rd = (Get-Date).ToLongDateString()
    $rt = (Get-Date).ToLongTimeString()
    $os = Get-WmiObject -Class Win32_OperatingSystem -Property Caption | Select-Object -ExpandProperty Caption
    Write-HTML "Summary" -H3
    Write-HTML "" -BeginList
    Write-HTML "Executed By~$un"
    Write-HTML "Executed From~$cn"
    Write-HTML "Execution Time~$rd at $rt"
    Write-HTML "Host OS~$os"
    Write-HTML "PowerShell Version~$pv"
    Write-HTML "" -EndList
}

function Test-DomainController {
    PARAM (
        [parameter(Mandatory=$False,Position=0)]
        [string] $ComputerName
    )
    if ($ComputerName.Length -gt 1) {
        $cs = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName 
    }
    else {
        $cs = Get-WmiObject -Class Win32_ComputerSystem
    }
    $role = ($cs).DomainRole
    if ($role -ge 5) {
        Return $True
    }
}

function Write-HtmlHeading {
    $ht = "<!DOCTYPE html PUBLIC `"-//W3C//DTD XHTML 1.0 Transitional//EN`""
    $ht += "`"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd`">" 
    $ht += "`n<html xmlns=`"http://www.w3.org/1999/xhtml`" lang=`"en`" xml:lang=`"en`">"
    $ht += "`n<head>"
	$ht += "`n<meta charset=`"u`tf-8`">"
	$ht += "`n<meta http-equiv=`"Content-Language`" content=`"en-us`" />"
	$ht += "`n<meta http-equiv=`"Content-Type`" content=`"text/html; charset=windows-1252`" />"
	$ht += "`n<meta http-equiv=`"Cache-Control`" content=`"cache`" />"
	$ht += "`n<meta name=`"distribution`" content=`"Global`" />"
	$ht += "`n<meta name=`"revisit-after`" content=`"1 days`" />"
	$ht += "`n<meta name=`"robots`" content=`"follow, index, noodp, noydir`" />"
	$ht += "`n<meta name=`"description`" content="" />"
	$ht += "`n<meta name=`"abstract`" content="" />"
	$ht += "`n<meta name=`"author`" content=`"David M. Stein`" />"
	$ht += "`n<meta name=`"copyright`" content=`"(c) 2015 David M. Stein, En Pointe Technologies`" />"
	$ht += "`n<meta name=`"keywords`" content=`"`" />"
	$ht += "`n<title>$ReportTitle</title>"
	#$ht += "`n<link rel=`"stylesheet`" type=`"text/css`" href=`"default.css`" />"
    $ht += "`n<style type=`"text/css`">`n $style `n</style>`n"
    $ht += "`n</head>`n<body>`n"
    $ht | Out-File -FilePath $ReportFile -Append -Force -NoClobber

}

function Get-AD-OSList {
    $os = Get-ADComputer -Filter * -Properties operatingSystem | Select-Object -ExpandProperty operatingSystem | Select -Unique
    Return $os
}

function Get-AD-OSCounts {
    Write-Host "querying: Domain computer operating systems..."
    Write-HTML "Operating Systems" -H3
    Write-HTML -BeginList
    Write-HTML "Qty~OperatingSystem"

    $oslist = Get-AD-OSList
    foreach ($os in $oslist) {
        $occ = 0
        $oc = Get-ADComputer -Filter "operatingSystem -eq `"$os`""
        if ($oc.length -gt 1) {
            $occ = $oc.Length
        }
        elseif ($oc.GetType().name -eq 'ADComputer') {
            $occ = 1
        }
        Write-HTML "$occ~$os"
    }
    Write-HTML -EndList
}

#============================================================================================
#endregion

if (Test-Path -Path $ReportFile) {
    Write-Host "Replacing previous report file..."
    Remove-Item -Path $ReportFile -Force
}
Write-Host "Beginning environment check..."

#region get-domains

Write-Host "querying: Forest environment..."
$adds = $adf.Domains | Sort-Object

# $DNs = GetDNs -domains $adds
$dclist = Get-ADDomainController -Filter * | Sort-Object 

Write-HTML "" -Heading
Write-HTML $adf.Name -H1
Write-HTML "" -BeginList

Write-HTML "Forest name~$($adf.Name)"
Write-HTML "Forest root~$($adf.RootDomain)"
Write-HTML "Forest mode~$($adf.ForestMode)"
Write-HTML "FSMO DNM~$($adf.DomainNamingMaster)"
Write-HTML "FSMO SM~$($adf.SchemaMaster)"
Write-HTML "Global Catalogs~$(($adf.GlobalCatalogs).count)"
Write-HTML "" -EndList

Write-Host "querying: Forest Domains..."
foreach ($dom in $adds) {
    Write-HTML "Domain: $dom" -H2
    
    $adn = Get-ADDomain -Identity $dom
    $sys = $adn.SystemsContainer
    $gpo = $adn.LinkedGroupPolicyObjects

    Write-HTML "" -BeginList
    Write-HTML "Parent domain~$($adn.ParentDomain)"
    Write-HTML "Domain mode~$($adn.DomainMode)"
    Write-HTML "Domain GUID~$($adn.ObjectGUID)"
    Write-HTML "Domain SID~$($adn.DomainSID)"
    Write-HTML "FSMO PDC~$($adn.PDCEmulator)"
    Write-HTML "FSMO IM~$($adn.InfrastructureMaster)"
    Write-HTML "FSMO RM~$($adn.RIDMaster)"

    $count1 = $(Get-ADComputer -Filter *).Length
    $count2 = $(Get-ADUser -Filter *).Length
    $count3 = $(Get-ADGroup -Filter *).Length 
    $count4 = $(Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(OperatingSystem=*server*))").length

    Write-HTML "User Accounts~$count2"
    Write-HTML "Security Groups~$count3"
    Write-HTML "" -EndList

    Write-HTML "Domain Computers" -H2
    Write-HTML "" -BeginList
    Write-HTML "Computer Accounts~$count1"
    Write-HTML "Server Accounts~$count4"
    Write-HTML "" -EndList

    Write-HTML "SCCM Schema Configuration" -H2
    Write-HTML "" -BeginList
    $try = Get-ADObject -Filter 'objectClass -eq "container"' | Where-Object {$_.Name -eq 'System Management'}
    if ($try -eq $null) {
        Write-HTML "Schema Extended~NO" -ForegroundColor Red
    }
    else {
        Write-HTML "Schema Extended~YES"
        $try2 = Get-ADObject -Filter 'objectClass -eq "mSSMSSite"'
        if ($try2 -eq $null) {
            Write-HTML "Published?~NO" -ForegroundColor Red
        }
        else {
            Write-HTML "Published?~YES"
            foreach ($psn in $try2) {
                Write-HTML "Published Names~$($psn.Name)"
            }
        }
    }
    Write-HTML "" -EndList
}
#endregion

Write-Host "querying: Domain Controllers..."

#region get-domain-controllers
Write-HTML "Domain Controllers" -H2
Write-HTML "" -BeginList
foreach ($dc in $dclist) {
    Write-HTML "Name~$($dc.Name)"
    Write-HTML "Read-Only~$($dc.IsReadOnly)"
    Write-HTML "GC Host~$($dc.IsGlobalCatalog)"
    Write-HTML "IPv4 Address~$($dc.IPv4Address)"
    Write-HTML "IPv6 Address~$($dc.IPv6Address)"
    Write-HTML "AD Site~$($dc.Site)"
    Write-HTML "OS Version~$($dc.OperatingSystem)"
    Write-HTML "OS Service Pack~$($dc.OperatingSystemServicePack)`n"
}
Write-HTML "" -EndList
#endregion

#region ad-sitelinks
Write-Host "querying: AD Site Links..."

Write-HTML "AD Site Links" -H2
$asl = Get-ADReplicationSiteLink -Filter *
Write-HTML "" -BeginList
foreach ($sl in $asl) {
    Write-HTML "Link name~$($sl.Name)"
    Write-HTML "Link cost~$($sl.Cost)"
    Write-HTML "Interval~$($sl.ReplicationFrequencyInMinutes)"
    foreach ($sn in $sl.SitesIncluded) {
        Write-HTML "Site name~$sn"
    }
}
Write-HTML "" -EndList
#endregion

Write-Host "querying: AD trusts..."
Write-HTML "AD Forest and Domain Trusts" -H2

$adTrusts = Get-ADTrust -Filter *
#$adTrusts = Get-ADTrust -Filter * | ConvertTo-Html -Fragment -As List
foreach ($adt in $adTrusts) {
    Write-HTML "" -BeginList
    Write-HTML $adt
    Write-HTML "" -EndList
}

#region local administrators
Write-Host "querying: User Groups..."

if (Test-DomainController) {
    Write-Host "(no local Administrators group on a domain controller)"
}
else {
    #H2
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
    $context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $env:COMPUTERNAME
    $idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
    $group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, 'Administrators')
    Write-HTML "" -BeginList
    foreach ($gm in $group.Members) {
        Write-HTML "User~$($context.Name)\$($gm.SamAccountName)"
    }
    Write-HTML "" -EndList
}

#endregion

#region group-memberships

if ($AdminGroups) {
    $glist = Get-ADGroup -Filter {(name -like "*admin*")} | Select-Object -ExpandProperty name | Sort-Object -Property name
    foreach ($gname in $glist) {
        $mcount = 0
        Write-HTML "Group: $gname" -H3
        $ulist = Get-ADGroupMember -Identity "$gname" | Select-Object -ExpandProperty name
        Write-HTML "" -BeginList
        foreach ($uname in $ulist) {
            Write-HTML "User~$uname"
            $mcount++
        }
        if ($mcount -eq 0) {
            Write-HTML "(no members found)"
        }
        Write-HTML "" -EndList
    }
}

if ($MoreGroups.Length -gt 0) {
    foreach ($gn in $MoreGroups.Split(",")) {
        Write-HTML "Group: $gn" -H3
        $ulist = Get-ADGroupMember -Identity "$gn" | Select-Object -ExpandProperty name
        Write-HTML "" -BeginList
        foreach ($uname in $ulist) {
            Write-HTML "User~$uname"
        }
        Write-HTML "" -EndList
    }
}

#endregion

Get-AD-OSCounts 

Write-Host "Writing report file..."

Write-Summary 
Write-HTML "" -Footer


Write-Host "Report completed! Report saved to --> $ReportFile"