[CmdletBinding()]
param (
	[parameter(Mandatory=$False)]
	[ValidateNotNullOrEmpty()]
	[string] $inputFile = ".\offline.txt",
	[parameter(Mandatory=$False)]
	[ValidateNotNullOrEmpty()]
	[string] $ReportFile = ".\reports\Computers-OnlineOffline.csv"
)

function Get-ADsComputer {
	param (
		[pararmeter(Mandatory)][string]$ComputerName
	)
	$strFilter = "(&(objectCategory=Computer)(name=$ComputerName))"
	$objDomain   = New-Object System.DirectoryServices.DirectoryEntry
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.SearchRoot = $objDomain
	$objSearcher.Filter = $strFilter
	$objSearcher.PageSize = 2000
	$objPath = $objSearcher.FindOne()
	foreach ($objItem in $objPath) {
		try {
			$objComputer = $objItem.GetDirectoryEntry()
			$data = [ordered]@{
				Name    = ($objComputer.name).ToString()
				OS      = ($objComputer.operatingSystem).ToString()
				OSVer   = ($objComputer.operatingSystemVersion).ToString()
				DN      = ($objComputer.distinguishedName).ToString()
				Created = ($objComputer.whenCreated).ToString()
				PwdSet  = [datetime]::FromFileTime($objItem.Properties.pwdlastset[0])
			}
			New-Object PSObject -Property $data
		} catch {
			# uh-oh, it's implosion time
			Write-Error $_.Exception.Message
		}
	}
}

function Test-ComputerStatus {
	param (
		$inputFile
	)
	if (!(Test-Path $inputFile)) {
		Write-Warning "$inputFile was not found!"
		break
	}
	$computers = Get-Content $inputFile
	$count1 = 0
	$count2 = 0

	Write-Verbose "$($computers.count) computers found in file"

	foreach ($computer in $computers) {
		if ($computer -match '-L') {
			$form = "Laptop"
		} elseif ($computer -match '-D') {
			$form = "Desktop"
		} elseif ($computer -match '-V') {
			$form = "Virtual"
		} else {
			$form = "Unknown"
		}

		if (Get-ADsComputer -ComputerName $computer) {
			$adx = $True
		} else {
			$adx = $False
		}
		if ((Test-NetConnection -ComputerName $computer -WarningAction SilentlyContinue).PingSucceeded) {
			Write-Verbose "$computer is online"
			$stat = "Online"
			$count1++
		} else {
			Write-Verbose "$computer is offline"
			$stat = "Offline"
			$count2++
		}
		$data = [ordered]@{
			Computer   = $computer
			ADAccount  = $adx
			FormFactor = $form
			Status     = $stat
		}
		New-Object PSObject -Property $data
	}
}

if (![string]::IsNullOrEmpty($ReportFile)) {
	Test-ComputerStatus -inputFile $inputFile | Export-Csv -Path $ReportFile -NoTypeInformation
} else {
	Test-ComputerStatus -inputFile $inputFile 
}
