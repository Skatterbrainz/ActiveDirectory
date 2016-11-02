function Test-User {
    param (
        [parameter(Mandatory=$True)] [string] $UserName
    )
    try {
        Get-ADUser $UserName -ErrorAction Stop | Out-Null
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        if ($ErrorMessage -match "Cannot find") {
            return $false
            break
        }
    }
    finally {
        
    }
    return $true
}

