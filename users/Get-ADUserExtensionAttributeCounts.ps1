function Get-UserExtensionAttributes {
    [CmdletBinding()]
    param()
    $schemaRoot = (Get-ADRootDSE).schemaNamingContext
    $allClasses = Get-ADObject -SearchBase $schemaRoot -LDAPFilter '(objectClass=classSchema)' -Properties lDAPDisplayName,subClassOf,auxiliaryClass,systemAuxiliaryClass,mayContain,mustContain,systemMayContain,systemMustContain
    $classByName = @{}
    foreach ($c in $allClasses) {
        if ($c.lDAPDisplayName) {
            $classByName[$c.lDAPDisplayName] = $c
        }
    }

    $queue = [System.Collections.Generic.Queue[string]]::new()
    $seenClasses = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $queue.Enqueue('user')

    while ($queue.Count -gt 0) {
        $className = $queue.Dequeue()
        if (-not $seenClasses.Add($className)) { continue }
        $classObj = $classByName[$className]
        if (-not $classObj) { continue }

        foreach ($nextClass in @($classObj.subClassOf) + @($classObj.auxiliaryClass) + @($classObj.systemAuxiliaryClass)) {
            if ($nextClass) {
                $queue.Enqueue($nextClass)
            }
        }
    }

    $rawUserAttributeNames = foreach ($className in $seenClasses) {
        $classObj = $classByName[$className]
        if (-not $classObj) { continue }
        @(
            $classObj.mayContain
            $classObj.mustContain
            $classObj.systemMayContain
            $classObj.systemMustContain
        )
    }

    $userAttributeNames = $rawUserAttributeNames | Where-Object { $_ } | Sort-Object -Unique

    $schema = Get-ADObject -SearchBase $schemaRoot -LDAPFilter '(objectClass=attributeSchema)' -Properties name,ldapDisplayName
    $userAssociatedAttributes = $schema |
        Where-Object {
            $_.ldapDisplayName -in $userAttributeNames -and
            $_.ldapDisplayName -like '*extension*'
        } |
        Sort-Object ldapDisplayName
    $userAssociatedAttributes
}

$attributeNames = Get-UserExtensionAttributes | Select-Object -ExpandProperty ldapDisplayName
$results = foreach ($attributeName in $attributeNames) {
	Write-Host "Checking: $attributeName"
	Get-ADUser -Filter { $attributeName -like '*' } | Measure-Object | Select-Object @{n='Attribute';e={$attributeName}},Count}
$results | Format-Table -AutoSize
