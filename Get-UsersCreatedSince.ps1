#requires -modules ActiveDirectory
#requires -version 2

param (
    [parameter(Mandatory=$True, HelpMessage="On or After Date")]
    [datetime] $SinceWhen
)
$Ldate = New-Object System.DateTime($SinceWhen.Year,$SinceWhen.Month,$SinceWhen.Day)
Get-ADUser -Properties name,distinguishedName,whenCreated -Filter {(objectClass -eq "user") -and (whenCreated -ge $Ldate)}
