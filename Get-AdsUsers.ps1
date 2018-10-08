$strFilter = "(objectCategory=User)"

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.Filter = $strFilter
$objPath = $objSearcher.FindAll()

foreach ($objItem in $objPath) {
    try {
        $objUser = $objItem.GetDirectoryEntry()
        $Manager = ""
        if (![string]::IsNullOrEmpty($objUser.manager).ToString()) {
            $Manager = $(($objUser.manager).ToString() -split ',')[0]
        }
        $data = [ordered]@{
            Name        = ($objUser.name).ToString()
            EmpID       = ($objUser.employeeID).ToString()
            DN          = ($objUser.distinguishedName).ToString()
            FullName    = ($objUser.displayName).ToString()
            Description = ($objUser.description).ToString()
            Department  = ($objUser.department).ToString()
            Manager     = $Manager
            Mail        = ($objUser.mail).ToString()
            Title       = ($objUser.title).ToString()
            Created     = ($objUser.whenCreated).ToString()
        }
        New-Object PSObject -Property $data
    }
    catch {
        # uh-oh, it's implosion time
        Write-Error $_.Exception.Message
    }
}
