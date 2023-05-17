#requires -RunAsAdministrator
<#
.DESCRIPTION
	Create a new local user account and add to local Administrators group
.PARAMETER (none)
.NOTES
	Requires Windows PowerShell 5.1, or PowerShell 7.3 or later
	Requires Running as Administrator
	Requires user input

	1.0.0 - 2023-01-02 - David Stein

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
	FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
#>
[CmdletBinding()]
param ()
$AddToGroup = 'Administrators'
function RevPwd {
	param (
		[parameter(Mandatory)][securestring]$SecurePassword
	)
	$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
	[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}
try {
	$pattern = '^(?![\.-])(?:[a-zA-Z0-9-.](?!\.$)){1,21}$'
	$username = Read-Host -Prompt "Username (up to 20 characters)"
	if (![string]::IsNullOrWhiteSpace($username)) {
		$username = $username.Trim()
		if ($username -notmatch $pattern) {
			throw "Invalid username: A-Z, a-z, 0-9 only, and up to 20 chars max length"
		}
	} else {
		throw "No username was entered"
	}
	if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
		throw "User account already exists: $UserName"
	}
	$desc = Read-Host -Prompt "Description"
	$Password = Read-Host -Prompt "Password" -AsSecureString
	$ConfirmPassword = Read-Host -Prompt "Confirm Password" -AsSecureString
	if ([string]::IsNullOrWhiteSpace($Password) -or [string]::IsNullOrWhiteSpace($ConfirmPassword)) {
		throw "Empty password is not allowed"
	}
	if ((RevPwd $Password) -ne (RevPwd $ConfirmPassword)) {
		throw "Passwords do not match"
	}
	$params = @{
		Name = $username
		Password = $password
	}
	if (![string]::IsNullOrWhiteSpace($desc)) {
		$params['Description'] = $desc.Trim()
	}
	$user = New-LocalUser @params
	Add-LocalGroupMember -Group "$AddToGroup" -Member $UserName
	Write-Host "User account '$UserName' created and added to group Administrators" -ForegroundColor Green
	Get-LocalGroupMember -Name $AddToGroup | Select-Object @{l='Group';e={$AddToGroup}}, @{l='Class';e={$_.ObjectClass}}, Name, @{l='Source';e={$_.PrincipalSource}}
} catch {
	Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}