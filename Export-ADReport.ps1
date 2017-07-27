<#
.DESCRIPTION
    Compiles files exported from Get-ADInformation.ps1 into single HTML report

.PARAMETER InputFolder
    [string] (optional) folder which contains files to compile.
    Default is ".\"

.PARAMETER ReportFile
    [string] (optional) Name of HTML output file.
    Default is "ADReport.htm"

.PARAMETER ReportTitle
    [string] (optional) Caption for HTML report.
    Default is "AD Report"

.NOTES
    Version 1.0 - 2017.07.27 - David Stein

.EXAMPLES
    .\Export-ADReport.ps1 -
#>


param (
    [parameter(Mandatory=$False, HelpMessage="Folder to process")]
        [string] $InputFolder = ".\",
    [parameter(Mandatory=$False, HelpMessage="HTML Output filename")]
        [string] $ReportFile = ".\ADReport.htm",
    [parameter(Mandatory=$False, HelpMessage="Main Title")]
        [string] $ReportTitle = "AD Report"
)

$style = " 
<style type=`"text/css`" >
body {
    font-family: verdana,sans;
}

table {
    width: 1024px;
    border-color: #efefef;
    border-collapse: collapse;
    border-width: 1px;
    margin-left: 0px;
}

th,td {
    font-family: verdana,sans;
    font-size: 10pt;
    border: 1px solid #c0c0c0;
    padding: 5px;
}

.footer {
    font-size: 10pt;
    font-family: verdana;
    text-align: center;
}
</style>"

if (Test-Path $ReportFile) { 
    Write-Verbose "deleting previous report file"
    Remove-Item -Path $ReportFile -Force 
}

$caption = "`<h1`>$ReportTitle`<`/h1`>"

ConvertTo-Html -Title $ReportTitle -Head $Style -Body $caption | Out-File $ReportFile

$csvFiles = Get-ChildItem -Path $InputFolder -Filter "*.csv"

foreach ($f in $csvfiles) {
    write-output $f.Name
    $('<h2>' + ($f.Name -replace '.csv','') + '</h2>') | Out-File $ReportFile -Append
    Import-Csv -Path $f.FullName | ConvertTo-Html | Out-File -FilePath $ReportFile -Append
}

$txtFiles = Get-ChildItem -Path $InputFolder -Filter "*.txt"

foreach ($f in $txtFiles) {
    write-output $f.Name
    $('<h2>' + ($f.Name -replace '.txt','') + '</h2>') | Out-File $ReportFile -Append
    if ($f.Name -like "*GPOLinks*") {
        Import-Csv -Path $f.FullName -Delimiter '!' -Header @('Target','GUID','Name','Type','Enabled','Enforced') | ConvertTo-Html | Out-File -FilePath $ReportFile -Append
    }
    else {
        Get-Content -Path $f.FullName | ConvertTo-Html | Out-File -FilePath $ReportFile -Append
    }
}

$logFiles = Get-ChildItem -Path $InputFolder -Filter "*.log"

foreach ($f in $logFiles) {
    write-output $f.Name
    $('<h2>' + ($f.Name -replace '.log','') + '</h2>') | Out-File $ReportFile -Append
    if ($f.Name -like "*dcdiag*") {
        $('<table><tr><td><pre>') | Out-File $ReportFile -Append
        $x = Get-Content -Path $f.FullName | Where-Object {$_ -like "*passed test*" -or $_ -like "*failed test*"}
        foreach ($y in $x) { 
            $y = $y.Trim()
            $y = $y -replace '......................... ', ''
            if ($y -like "*passed test*") {
                #write-output "line: $y"
                $y | Out-File -FilePath $ReportFile -Append
            }
            elseif ($y -like "*failed test*") {
                #write-output "line: $y"
                $("<span style=color:red>" + $y + "</span>") | Out-File -FilePath $ReportFile -Append
            }
        }
        $('</pre></td></tr></table>') | Out-File $ReportFile -Append
    }
    else {
        $x = Get-Content -Path $f.FullName
    }
}

$('<p class=footer>Copyright &copy; 2017 PCM. All rights reserved.</p>') | Out-File -FilePath $ReportFile -Append
Write-Output "export complete"
