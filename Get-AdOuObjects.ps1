function Get-AdOuObjects {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string] $ou
    )
    $root = [ADSI]"LDAP://$ou"
    $search = [adsisearcher]$root
    #$search.Filter = "(&(objectclass=user)(objectcategory=user))"
    $search.SizeLimit = 3000
    $results = $search.FindAll()
    foreach ($result in $results) {
        $props = $result.Properties
        foreach ($p in $props) {
            $itemName = ($p.name | Out-String).Trim()
            $itemPath = ($p.distinguishedname | Out-String).Trim()
            $itemPth  = $itemPath -replace "CN=$itemName,", ''
            $itemType = (($p.objectcategory -split ',')[0]) -replace 'CN=', ''
            $output = [ordered]@{
                Name = $itemName
                DN   = $itemPath
                Path = $itemPth
                Type = $itemType
            }
            New-Object PSObject -Property $output
            #select @{N="Name"; E={$_.name}}, @{N="DistinguishedName"; E={$_.distinguishedname}}, @{N="Class"; E={($_.objectcategory -split ',')[0]}}
        }
    }
}
