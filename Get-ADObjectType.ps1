function Get-ADAccount {
    param (
        [string] $Name
    )
    if ($Name.Contains('\')) {
        $Domain = $Name.Split('\')[0]
        $Name   = $Name.Split('\')[1]
    }
    $strFilter   = "(&(objectCategory=*)(samAccountName=$Name))"
    $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $objSearcher.Filter = $strFilter
    try {
        $objPath = $objSearcher.FindOne()
        $objAccount = $objPath.GetDirectoryEntry()
        Write-Output $objAccount
    }
    catch {
        Write-Warning "no such object: $Name"
    }
}

function Get-ADObjectType {
    param (
        [parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Names
    )
    BEGIN {}
    PROCESS {
        foreach ($name in $Names) {
            try {
                Get-ADAccount "$name" | 
                    Select -ExpandProperty distinguishedName | 
                        Get-AdObject | 
                            Select-Object -ExpandProperty ObjectClass
            }
            catch {
                Write-Error $_.Exception.Message
            }
        }
    }
    END {}
}
