function Get-CmhAdDcStatus {
    param (
        [parameter(Mandatory=$True)]
        [ValidateSet('DCDiagBasic','DCDiagFull','RepAdminBasic','RepAdminFull')]
        [string] $Option,
        [switch] $SaveToLogFile
    )
    $date = Get-Date -format M.d.yyyy 
    $server = $($env:LOGONSERVER).Substring(2,$($env:LOGONSERVER).Length-2)
 
    $dcdiag        = {cmd.exe /c dcdiag} 
    $dcdiagverbose = {cmd.exe /c dcdiag /v} 
    $showrepl      = {cmd.exe /c repadmin /showrepl} 
    $replsummary   = {cmd.exe /c repadmin /replsummary} 
    $errorMessage  = "*** INVALID ENTRY ***" 
 
    switch ($Option) {
        'DCDiagBasic' {
            $cmd = $dcdiag; break;
        }
        'DCDiagFull' {
            $cmd = $dcdiagverbose; break;
        }
        'RepAdminBasic' {
            $cmd = $showrepl; break;
        }
        'RepAdminFull' {
            $cmd = $replsummary; break;
        }
        default { 
            $errorMessage ; Exit 
        } 
    } 
 
    # Run the chosen command on the server 
    $command = $cmd 
    Write-Host -ForegroundColor yellow "Please wait... Running command: $cmd" 
    $runCommand = Invoke-Command -Computername $server -ScriptBlock $command 
    if ($SaveToLogFile) {
        $runCommand | Out-File $logPath -Append
        Write-Host -ForegroundColor Yellow "Script complete, logfile is located at $logPath"
        # Path the where the logs will be stored 
        $logPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\$server`_$date.log" 
    }
    else {
        $runCommand
    }
}
