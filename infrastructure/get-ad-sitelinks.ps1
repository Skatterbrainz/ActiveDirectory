$CsvFile = "c:\temp\ad_sitelinks.csv"

Import-Module ActiveDirectory

$params = @{
	Filter = 'objectClass -eq "siteLink"'
	SearchBase = (Get-ADRootDSE).ConfigurationNamingContext
	Property = ('Options', 'Cost', 'ReplInterval', 'SiteList', 'Schedule')
}

$sitelinks = Get-ADObject @params |
	Select-Object Name, @{Name="SiteCount";Expression={$_.SiteList.Count}}, Cost, ReplInterval, @{Name="Schedule";Expression={If($_.Schedule){If(($_.Schedule -Join " ").Contains("240")){"NonDefault"}Else{"24x7"}}Else{"24x7"}}}, Options

$sitelinks | Export-Csv -Path $CsvFile -NoTypeInformation -Force