#requires -modules ActiveDirectory
<#
.NOTES
1. Find computers in the default "computers" container
2. Identify OS as workstation or server
3. Move computer to OU by OS
#>
param (
    [parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [string] $WorkstationOU = "OU=Workstations,OU=CORP,DC=contoso,DC=local",
    [parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [string] $ServerOU = "OU=Servers,OU=CORP,DC=contoso,DC=local", 
    [parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [string] $CsvFile = "AD-ComputerMoves.csv"
)

$computers = @(Get-ADComputer -Filter * -Properties 'operatingSystem' | 
    Where-Object {$_.DistinguishedName -like '*CN=Computers*'})

if ($computers.Count -eq 0) {
    Write-Host "no computer accounts need to be moved"
    break
}

$outfile = Join-Path -Path $PSScriptRoot -ChildPath $CsvFile

function Move-Computers {
    param (
        $Computers 
    )
    foreach ($computer in $computers) {
        $ComputerName = $computer.Name
        $OsName = $computer.OperatingSystem
        if ($osname -like '*server*') {
            $target = Get-ADOrganizationalUnit -Identity $ServerOU
            Get-ADComputer $ComputerName | Move-ADObject -TargetPath $target.DistinguishedName
            $ostype = 'Server'
        }
        else {
            $target = Get-ADOrganizationalUnit -Identity $WorkstationOU
            Get-ADComputer $ComputerName | Move-ADObject -TargetPath $target.DistinguishedName
            $ostype = 'Workstation'
        }
        $props = [ordered]@{
            Name = $ComputerName
            OS   = $osname
            Type = $ostype
            DateMoved = (Get-Date)
        }
        New-Object PSObject -Property $props
    }
}

$results = Move-Computers -Computers $computers

$results | Export-Csv -Path $outfile -Append -NoTypeInformation
