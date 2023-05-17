function Get-ComputerADSite ($ComputerName) {
    $site = nltest /server:$ComputerName /dsgetsite 2>$null
    if ($LASTEXITCODE -eq 0) {
        $site[0]
    }
    else {
        "DEFAULT"
    }
}
