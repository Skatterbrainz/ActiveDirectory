#requires -RunAsAdministrator
<#
.DESCRIPTION
	Create a new local user account and add to local Administrators group
.PARAMETER UserName
	Local user account name. Must be valid characters, up to 20 chars in length
.PARAMETER Description
	Local user account description.
.PARAMETER Password
	Password
.PARAMETER AddToGroup
.EXAMPLE
.NOTES
	Requires Windows PowerShell 5.1, or PowerShell 7.3 or later
	Requires Running as Administrator

	1.0.0 - 2023-01-02 - David Stein

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
	FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
#>
[CmdletBinding()]
param (
	[parameter(Mandatory)][string]$UserName,
	[parameter(Mandatory)][string]$Description,
	[parameter(Mandatory)][securestring]$Password,
	[parameter()][string]$AddToGroup = 'Administrators'
)
try {
	$pattern = '^(?![\.-])(?:[a-zA-Z0-9-.](?!\.$)){1,21}$'
	if ($UserName -notmatch $pattern) {
		throw "Invalid username: Must be 1-20 chars in length, and A-Z, a-z, 0-9"
	}
	$params = @{
		Name = $username
		Password = $Password
		Description = $Description
	}
	$user = New-LocalUser @params
	$null = Add-LocalGroupMember -Group "$AddToGroup" -Member $UserName
	$result = [PSCustomObject]@{
		Status   = 'Success'
		Message  = "Account created"
		UserName = $username
		RunOn = $env:COMPUTERNAME
		RunAs = $env:USERNAME
	}
} catch {
	$msg = $_.Exception.Message
	$result = [pscustomobject]@{
		Status   = 'Error'
		Message  = $msg
		UserName = $username
		RunOn = $env:COMPUTERNAME
		RunAs = $env:USERNAME
	}
} finally {
	Write-Output $result
}