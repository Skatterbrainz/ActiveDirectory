<#
.DESCRIPTION
    Import AD user accounts from a CSV input file. Accommodates custom
    and extended attributes if requested.

.PARAMETER CsvFile <filename>
    Required: [String] Full path and filename of CSV input file.

.PARAMETER RowLimit <number>
    Optional: [Integer] Limit import of first N rows of CSV input file
    Default value is 0 (all rows)

.PARAMETER ChgPwdFirstLogon
    Optional: [Switch] configures user accounts to require password
    change at first/next login

.PARAMETER DefaultPwd <string>
    Optional: Default password value.  If not specified, then
    a random password is assigned to each account.
    Default value is ""

.PARAMETER ExcludeNames <string>
    Optional: Name or pattern to identify custom AD attribute names to exlude
    Default value is "ml*"
    To load all attributes (no exclusions) use -ExcludeNames ""

.EXAMPLE
    .\Import-AdUsers.ps1 -CsvFile "users.csv" -Verbose
    .\Import-AdUsers.ps1 -CsvFile "users.csv" -RowLimit 50 -Verbose
    .\Import-AdUsers.ps1 -CsvFile "users.csv" -RowLimit 50 -DefaultPwd "P@ssWoRd123" -Verbose
    .\Import-AdUsers.ps1 -CsvFile "users.csv" -RowLimit 50 -ExcludeNames "abc*" -Verbose

.NOTES
    Author  = David Stein
    Version = 2017.02.14.01
    Date Created = 03/02/2015
    Last Updated = 02/14/2017

    Note that the CSV input file must have the following...

    1. The top row contains AD schema attribute names
    2. One of the headings is "path" for the LDAP path where accounts will be created
    3. No read-only attributes are specified (e.g. msExtendedAttribute20)

    WARNING: USE AT YOUR OWN RISK - NO WARRANTY PROVIDED
    User accepts any and all risk and liability 
	Validate in isolated test environment before production use.
#>

param (
    [parameter(Mandatory=$True, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string] $CsvFile,
    [parameter(Mandatory=$False)]
      [int] $RowLimit = 0,
    [parameter(Mandatory=$False)]
  	  [switch] $ChgPwdFirstLogon,
	  [parameter(Mandatory=$False)]
  	  [string] $DefaultPwd = "",
    [parameter(Mandatory=$False)]
      [string] $ExcludeNames = ""
)
if ($ChgPwdFirstLogon) { $FirstLogon = $True } else { $FirstLogon = $False }
if ($DefaultPwd -eq "") { $Randomize = $True } else { $Randomize = $False }

$ErrorActionPreference = "Stop"
$startTime = Get-Date
$ScriptVer = "2017.02.14.01"

function Get-UserAttributes 
{
    param (
        [string] $InputFile 
    )
    Write-Verbose "[Get-UserAttributes]"
    $attlist  = @()
	  $csvRaw   = Get-Content -Path $InputFile
	  $attlist  = $csvRaw[0].ToLower().Split(",") | ? {$_ -notlike "_*"}
	  $attlist  = $attlist | ? {$_ -ne "samaccountname"} | ? {$_ -ne "name"} | ? {$_ -ne "path"}
    return $attlist
}

function New-RandomPassword 
{
    [CmdletBinding(DefaultParameterSetName='Length')]
    param (
        [parameter(Mandatory=$False)][int] $Length = 24
    )
    <#
    .DESCRIPTION
    Generate a random password of a given length.
   
    .PARAMETER Length
    Optional: Length of password to generate (number of digits).
    Default: 15

    .EXAMPLE
    New-RandomPassword -Length 32
	
	thanks to http://blog.oddbit.com/2012/11/04/powershell-random-passwords/
    #>
    Write-Verbose "[New-RandomPassword] length: $Length"
    $punc    = 46..46
    $digits  = 48..57
    $letters = 65..90 + 97..122
    $password = Get-Random -Count $Length `
        -Input ($punc + $digits + $letters) |
            % -Begin { $aa = $null } `
            -Process {$aa += [char]$_} `
            -End {$aa}
    return $password
}

if (!(Test-Path $csvfile)) 
{
    Write-Host "error: $csvfile not found"
}
else 
{
    $rowNum = 1

    $attlist  = Get-UserAttributes -InputFile $CsvFile
	  $attcount = $attlist.Length
	  Write-Verbose "info: $attcount attributes returned"

    Write-Verbose "info: reading input data file..."
    $csvData = Import-Csv -Path $CsvFile | ? {$_._LOAD -eq 1}
    if ($RowLimit -gt 0) 
    {
        $csvData = $csvData[0..$($RowLimit-1)]
    }
    $csvRows = $csvData.Count
    Write-Verbose "info: loaded $csvRows entries"

    Write-Verbose "info: processing accounts..."
    foreach ($row in $csvData) 
    {
        $sam   = $row.sAMAccountName
        $upath = $row.PATH
        $uname = $sam
        Write-Verbose "info: [$rowNum] user = $sam"
        Write-Verbose "info: [$rowNum] path = $upath"
        if ($Randomize -eq $True) 
        {
            $rpwd = New-RandomPassword -Length 32
        }
        else 
        {
            $rpwd = $DefaultPwd
        }
        try 
        {
            $user = Get-ADUser -Identity "$sam" -ErrorAction SilentlyContinue
            Write-Host "[$rowNum] updating user: $sam" -ForegroundColor Cyan
        }
        catch 
        {
            $user = $null
            Write-Host "[$rowNum] creating user: $sam" -ForegroundColor Green
            New-ADUser -Name "$sam" `
                -SamAccountName "$sam" -Path $upath `
                -AccountPassword (ConvertTo-SecureString $rpwd -AsPlainText -Force) `
                -Enabled:$True -ChangePasswordAtLogon:$FirstLogon
            $user = Get-ADUser -Identity "$sam"
        }
        if ($user -eq $null) 
        {
            Write-Error "error: [$rowNum] failed to create user account $sam"
            break
        }
        Write-Verbose "info: [$rowNum] account created: $sam"

        foreach ($att in $attlist) 
        {
            if ($att -ne "cn") 
            {
                $v = ($row."$att").Trim()
                if ($v.length -gt 0) {
                    if ($att -like "$ExcludeNames") 
                    {
                        Write-Verbose "info: [$rowNum] $sam ($att == $v) IGNORED"
                    }
                    else
                    {
                        Write-Verbose "info: [$rowNum] $sam ($att == $v)"
                        switch ($att.ToUpper()) 
                        {
                            "MSEXCHEXTENSIONATTRIBUTE18" 
                            {
                                Write-Verbose "info: [$rowNum] $sam -- updating GUID value..."
                                $g = (Get-ADUser -Identity $sam | Select-Object -ExpandProperty 'ObjectGUID').guid
                                Set-ADUser -Identity $sam -replace @{"$att"="$g"} -Confirm:$False
                                break
                            }
                            "PROXYADDRESSES" 
                            {
                                Write-Verbose "info: [$rowNum] $sam -- updating ProxyAddresses list..."
                                $g = $v.Split(";")
                                Set-ADUser -Identity $sam -replace @{"$att"=$g} -Confirm:$False
                                break
                            }
                            "MANAGER" 
                            {
                                try 
                                {
                                    $muser = Get-ADUser $v -ErrorAction SilentlyContinue
                                    if ($muser -ne $null)
                                    {
                                        Write-Verbose "info: [$rowNum] $sam -- updating manager reference: $v"
                                        Set-ADUser $User -replace @{"$att"="$v"} -Confirm:$False
                                    }
                                }
                                catch 
                                {
                                    Write-Verbose "error: [$rowNum] $sam -- manager reference is invalid: $v"
                                    Write-Warning "[$rownum] manager reference for $sam could not be assigned. Rerun script to assign usable references or add the missing records."
                                }
                                break
                            }
                            default 
                            {
                                try
                                {
                                    Set-ADUser $User -replace @{"$att"="$v"} -Confirm:$False -ErrorAction SilentlyContinue
                                }
                                catch
                                {
                                    Write-Warning "[$rownum] $att could not be assigned"
                                }
                                break
                            }
                        }
                    }
                }
                else 
                {
                    Write-Verbose "info: [$rowNum] $sam ($att == null value)"
                }
            }
        }

        $rowNum += 1

        Write-Verbose "--------------------------------"
    }
}
$StopTime = Get-Date
$RunSecs  = ((New-TimeSpan -Start $startTime -End $StopTime).TotalSeconds).ToString()
$ts = [timespan]::FromSeconds($RunSecs)
$RunTime = $ts.ToString("hh\:mm\:ss")

Write-Host "------------------------------------------------"
Write-Host "info: $($rowNum-1) rows were processed."
Write-Host "info: total runtime was $RunTime (hh:mm:ss)"
