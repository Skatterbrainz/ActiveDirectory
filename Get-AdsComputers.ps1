$strFilter = "(objectCategory=Computer)"

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.Filter = $strFilter
$objPath = $objSearcher.FindAll()

foreach ($objItem in $objPath) {
    try {
        $objComputer = $objItem.GetDirectoryEntry()
        $data = [ordered]@{
            Name    = ($objComputer.name).ToString()
            OS      = ($objComputer.operatingSystem).ToString()
            OSVer   = ($objComputer.operatingSystemVersion).ToString()
            DN      = ($objComputer.distinguishedName).ToString()
            Created = ($objComputer.whenCreated).ToString()
            PwdSet  = [datetime]::FromFileTime($objItem.Properties.pwdlastset[0])
        }
        New-Object PSObject -Property $data
    }
    catch {
        # uh-oh, it's implosion time
        Write-Error $_.Exception.Message
    }
}
