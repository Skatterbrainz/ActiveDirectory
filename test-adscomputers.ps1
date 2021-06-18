Function DecodeUserAccountControl ([int]$UAC)
{
$UACPropertyFlags = @(
"SCRIPT",
"ACCOUNTDISABLE",
"RESERVED",
"HOMEDIR_REQUIRED",
"LOCKOUT",
"PASSWD_NOTREQD",
"PASSWD_CANT_CHANGE",
"ENCRYPTED_TEXT_PWD_ALLOWED",
"TEMP_DUPLICATE_ACCOUNT",
"NORMAL_ACCOUNT",
"RESERVED",
"INTERDOMAIN_TRUST_ACCOUNT",
"WORKSTATION_TRUST_ACCOUNT",
"SERVER_TRUST_ACCOUNT",
"RESERVED",
"RESERVED",
"DONT_EXPIRE_PASSWORD",
"MNS_LOGON_ACCOUNT",
"SMARTCARD_REQUIRED",
"TRUSTED_FOR_DELEGATION",
"NOT_DELEGATED",
"USE_DES_KEY_ONLY",
"DONT_REQ_PREAUTH",
"PASSWORD_EXPIRED",
"TRUSTED_TO_AUTH_FOR_DELEGATION",
"RESERVED",
"PARTIAL_SECRETS_ACCOUNT"
"RESERVED"
"RESERVED"
"RESERVED"
"RESERVED"
"RESERVED"
)
$Attributes = ""
1..($UACPropertyFlags.Length) | Where-Object {$UAC -bAnd [math]::Pow(2,$_)} | ForEach-Object {If ($Attributes.Length -EQ 0) {$Attributes = $UACPropertyFlags[$_]} Else {$Attributes = $Attributes + " | " + $UACPropertyFlags[$_]}}
Return $Attributes
}

function Get-AdsComputers {
    [array]$computers = [System.DirectoryServices.DirectorySearcher]::new("objectCategory=computer").FindAll() | select -first 50
    foreach ($computer in $computers) {
        #write-host "computer: $($computer.Properties.name[0])"
        if ($null -ne $computer.Properties.lastlogontimestamp) {
            $llogon = [datetime]::FromFileTime($computer.Properties.lastlogontimestamp[0])
        } else {
            $llogon = $null
        }
        $computer.Properties.name
        $computer.Properties.operatingsystem
        $computer.Properties.distinguishedname
        $computer.Properties.lastlogontimestamp
        $computer.Properties.pwdlastset
        DecodeUserAccountControl $($computer.Properties.useraccountcontrol)

        #[pscustomobject]@{
        #    Name = $computer.Properties.name[0]
        #    OS = $computer.Properties.operatingsystem[0]
        #    DN = $computer.Properties.distinguishedname[0]
        #    LastLogon = $llogon
            #PwdLastSet = [datetime]::FromFileTime($computer.Properties.pwdlastset[0])
            #UAC = $computer.Properties.useraccountcontrol[0]
        #}
    }
}


Get-AdsComputers | FT