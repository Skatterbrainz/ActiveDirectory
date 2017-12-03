function Get-ADGroupNestedMember {
    param (
        [parameter(Mandatory=$True, ValueFromPipeline, HelpMessage="Name of Group")]
        [ValidateNotNullOrEmpty()]
        [string] $GroupName
    )
    $Members = (Get-ADGroupMember -Identity $GroupName).samAccountName
    foreach ($Member in $Members) {
        try {
            Write-Host "user: $Member ($GroupName)"
            ## Test to see if the group member is a group itself
            if (Get-ADGroup -Identity $Member) {
                Get-MyADGroupMember -GroupName $Member
            }
        }
        catch {}
    }
}
