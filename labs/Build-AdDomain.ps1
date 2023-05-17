<# 
.SYNOPSIS
	Build-AdDomain.ps1
	Configure a new AD Domain

.DESCRIPTION
	Configure a new AD Domain using a set of CSV input files
	
.PARAMETER

.NOTES
	Author........: David Stein
	Comment.......: run this script on any DC in the domain
	Version.......: 2016.03.02.04

#>

Import-Module ServerManager

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Import-Module ActiveDirectory 

$RootPath = ([ADSI]"LDAP://RootDSE").defaultNamingContext

$path = Split-Path -parent $MyInvocation.MyCommand.Definition  

$org_file    = $path + "\orgunits.csv"
$user_file   = $path + "\users.csv"
$group_file  = $path + "\groups.csv"
$member_file = $path + "\members.csv"
$comp_file   = $path + "\computers.csv"

#region FUNCTIONS

function Create-OrgUnits {
    param (
		[parameter(Mandatory=$True)] [string] $InputFile, 
		[parameter(Mandatory=$True)] [string] $Root
	)
	<#
	.PARAMETER InputFile
		[string] (required) Path and filename of CSV file to import
	
	.PARAMETER Root
		[string] (required) Root OU LDAP path string
	#>
    Write-Verbose "info: reading input file ($InputFile)..."
    if (Test-Path $InputFile) {
        Write-Output "info: creating new organizational units..."
        $csvdata = Import-Csv $InputFile
        foreach ($row in $csvdata) {
            if ($row.Path -eq "") {
				Write-Verbose "info: creating ou $($row.Name) in root level..."
                $x = New-ADOrganizationalUnit -Name "$($row.Name)" -Path "$Root" -ErrorAction SilentlyContinue
				if ($x -ne $null) {
					Write-Verbose "info: ou was created successfully."
				}
				else {
					Write-Verbose "error: failed to create ou."
				}
            }
            else {
				Write-Verbose "info: creating ou $($row.Name) in sub level $($row.Path)..."
                $x = New-ADOrganizationalUnit -Name "$($row.Name)" -Path "$($row.Path),$Root" -ErrorAction SilentlyContinue
				if ($x -ne $null) {
					Write-Verbose "info: ou was created successfully."
				}
				else {
					Write-Verbose "error: failed to create ou."
				}
            }
        }
		Write-Output "info: completed."
    }
    else {
        Write-Output "error: input file not found ($InputFile)"
    }
}

function Create-UserAccounts {
	param (
		[parameter(Mandatory=$True)] [string] $InputFile, 
		[parameter(Mandatory=$True)] [string] $DefPwd
	)
	<#
	.PARAMETER InputFile
		[string] (required) Path and filename of CSV file to import
	
	.PARAMETER DefPwd
		[string] (required) Default password for new user accounts
	#>
	Write-Verbose "info: reading input file ($InputFile)..."
	if (Test-Path $InputFile) {
		Write-Output "info: creating user accounts..."
		Import-Csv $InputFile | 
			New-ADUser -PassThru | 
				Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$DefPwd" -Force) -PassThru | 
					Enable-ADAccount 
		Write-Output "info: completed."
	}
	else {
		Write-Output "error: input file not found ($InputFile)"
	}
}

function Create-Groups {
	param (
		[parameter(Mandatory=$True)] [string] $InputFile
	)
	<#
	.PARAMETER InputFile
		[string] (required) Path and filename of CSV file to import	
	#>
	Write-Output "info: reading input file ($InputFile)..."
	if (Test-Path $InputFile) {
		Write-Output "info: creating security groups..."
		$csvdata = Import-Csv -Path $InputFile 
		$searchbase = Get-ADDomain | ForEach {  $_.DistinguishedName } 
		ForEach ($row In $csvdata) { 
			$check = [ADSI]::Exists("LDAP://$($row.GroupLocation),$($searchbase)") 
			If ($check -eq $True) { 
				Try { 
					$exists = Get-ADGroup $row.GroupName 
					Write-Verbose "warning: Group $($row.GroupName) alread exists! Group creation skipped!" 
				} 
				Catch { 
					$create = New-ADGroup -Name $row.GroupName -GroupScope $row.GroupType -Path ($($row.GroupLocation)+","+$($searchbase)) 
					Write-Verbose "info: Group $($row.GroupName) created!" 
				} 
			}
			Else { 
				Write-Output "error: Target OU can't be found! Group creation skipped!" 
			} 
		}
		Write-Output "info: completed."
	}
	else {
		Write-Output "error: input file not found ($InputFile)"
	}
}

function Create-Computers {
	param (
		[parameter(Mandatory=$True)] [string] $InputFile
	)
	<#
	.PARAMETER InputFile
		[string] (required) Path and filename of CSV file to import
	#>
	Write-Verbose "info: reading input file ($InputFile)..."
	if (Test-Path $InputFile) {
		$csvdata = Import-Csv -Path $InputFile
		$searchbase = Get-ADDomain | ForEach {  $_.DistinguishedName } 
		Write-Output "info: creating AD computer accounts..."
		foreach ($row in $csvdata) {
			Write-Verbose $row.Name
			Write-Verbose $row.Path
			$check = [ADSI]::Exists("LDAP://$($row.Path),$($searchbase)") 
			If ($check -eq $True) { 
				Try { 
					$exists = Get-ADComputer $row.Name 
					Write-Verbose "computer $($row.Name) already exists!" 
				} 
				Catch { 
					$create = New-ADComputer -Name $row.Name -Path ($($row.Path)+","+$($searchbase)) -Description $row.Description
					Write-Verbose "computer $($row.Name) created!" 
				} 
			}
			Else { 
				$ou = $row.Path
				Write-Output "error: Target OU $ou can't be found! computer creation skipped!" 
			} 
		}
		Write-Output "info: completed."
	}
	else {
		Write-Output "error: input file not found ($InputFile)"
	}
}

function Add-GroupMembers {
	param (
		[parameter(Mandatory=$True)] [string] $InputFile
	)
	<#
	.PARAMETER InputFile
		[string] (required) Path and filename of CSV file to import
	#>
	Write-Output "info: reading input file ($InputFile)..."
	if (Test-Path $InputFile) {
		Write-Output "info: populating security group members..."
		$mdata = Import-Csv -path $InputFile
		foreach ($item in $mdata) {
			$gn = $item.GroupName
			$mx = $item.Members
			foreach ($mbr in $mx.Split(",")) {
				Write-Output "`tadding ($mbr) to ($gn)..."
				Add-ADGroupMember "$gn" $mbr -ErrorAction Continue
			}
		}
		Write-Output "info: completed."
	}
	else {
		Write-Output "error: input file not found ($InputFile)"
	}
}

#endregion

Create-OrgUnits -InputFile $org_file -Root $RootPath -Verbose
Create-UserAccounts -InputFile $user_file -DefPwd "P@ssW0rd$2016.11.15" -Verbose
Create-Groups -InputFile $group_file -Verbose
Create-Computers -InputFile $comp_file -Verbose
Add-GroupMembers -InputFile $member_file -Verbose

Write-Output "info: domain setup complete!"
