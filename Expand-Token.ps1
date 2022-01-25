#Set-StrictMode -Version Latest
#####################################################
# Expand-Token
#####################################################
<#PSScriptInfo

.VERSION 0.1

.GUID bfd55243-60dd-4394-a80e-835718187e1f

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell token regex

.LICENSEURI https://github.com/SharedSitecore/Expand-Token/blob/main/LICENSE

.PROJECTURI https://github.com/SharedSitecore/Expand-Token

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#

.DESCRIPTION
 PowerShell Script to expand tokens in file/folder/strings using RegEx, EnvVar EnvironmentVariables, .env files and .with $(envVar)

.PARAMETER source
Source path to process

.PARAMETER destination
Destination path for output - if not provided, overwrites

.PARAMETER regex
Regex pattern for finding tokens - default to powershell format: $(name)
#>
#####################################################
# Functions
#####################################################
function Expand-TokenContent {
	[OutputType('System.String')]
	[CmdletBinding(SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory=$false)][string]$data,
		[Parameter(Mandatory=$false)][string]$regex
	)
	if (!$data) { return $data }
	#if ($data.GetType() -ne 'Array') {Write-Verbose "wow:$($data.GetType())"}
	$response = $data
	$tokens = [regex]::Matches($response,$regex)
	if (!$tokens) {	return $response }
	$tokensfound = @{}
	$tokens | Foreach-Object {
		$org = $_.groups[0].value
		$token = $org
		#Write-Verbose "token:$token"
		if ($token -like '$(*') {
			$token = $token.Remove(0,2)
			$token = $token.Substring(0, $token.Length - 1)
		}
		$value = [System.Environment]::GetEnvironmentVariable($token)
		#Write-Verbose "Expand-TokenContent:$token=$value"
		$tokensfound[$token] = $value
		$response = $response.Replace($org,"$value") #`n
	}
	#Write-Verbose "Tokens updated:"
	$tokensfound.keys.foreach({
		#Write-Verbose "$($_):$($tokensfound[$_])"
	})
	return $response
}

#TODO - extract to own script or finish inclusion in Set-Env with Nick
function Set-Env {
	[CmdletBinding(SupportsShouldProcess)]
	Param([Parameter(Mandatory=$false)][string]$path)
	try {
		if (!$path) {$path = Get-Location}
		if ($path) {
			#if ($path.GetType() -ne 'Array') {Write-Verbose "wow:$($path.GetType())"}
			if (Test-Path "$path\*.env*") {
				Get-ChildItem -Path "$path\*.env*" | Foreach-Object {
					try {
						$f = $_
						$content = (Get-Content $f.FullName) # -join [Environment]::NewLine # -Raw
						$content | ForEach-Object {
							if (-not ($_ -like '#*') -and ($_ -like '*=*')) {
								$sp = $_.Split('=')
								[System.Environment]::SetEnvironmentVariable($sp[0], $sp[1])
							}
						}
					}
					catch {
						throw "ERROR Set-Env $path-$f"
					}
				}
			} else {
				Write-Verbose "skipped:$p no *.env* files found"
			}
		}
	}
	catch {
		Write-Error "ERROR Set-Env $path" -InformationVariable results
	}
}
#####################################################
# Expand-Token
#####################################################
function Expand-Token {
	[OutputType('System.String')]
	[CmdletBinding(SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory=$false)]
		[string] $source,
		[Parameter(Mandatory=$false)]
		[string] $destination,
		[Parameter(Mandatory=$false)]
		[string] $regex = '(\$\()([a-zA-Z0-9\.\-_]*)(\))'
	)
	begin {
		$Global:ProgressPreference = 'SilentlyContinue'
		$ErrorActionPreference = 'Stop'
		#$commandPath = $MyInvocation.MyCommand.Path
		$commandPath = $PSCommandPath
		Write-Verbose "commandPath:$commandPath"
		$PSScriptName = (Split-Path $commandPath -Leaf).Replace('.ps1','')
		$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
		$currLocation = "$(Get-Location)"
		Write-Verbose "#####################################################`n# $PSScriptName $source $destination called by:$PSCallingScript from $currLocation"

		if (!$source) { $source = "$currLocation\*.*" }
		if (-not (Test-Path $source)) {
			if (-not (Test-Path "$currLocation\$source")) {
				if (-not (Test-Path "$currLocation\tests\$source")) {
					throw "$PSScriptName invalid source:$source"
				} else {
					$source = "$currLocation\tests\$source"
				}
			} else {
				$source ="$currLocation\$source"
			}
		}
		#Write-Verbose "source:$source"
		#Write-Verbose "destination:$destination"
		if (!$destination) {$destination = $source} elseif ($destination.IndexOf(':') -eq -1 -and $destination.Substring(0,1) -ne '\') {$destination = Join-Path $currLocation $destination}
		Write-Verbose "destination:$destination"
		if ($destination) {
			if (-not (Test-Path $source -PathType Leaf)) {
				if (-not (Test-Path $destination)) { New-Item -Path $destination -ItemType Directory | Out-Null}
			} else {
				$destParent = Split-Path $destination -Parent
				if (-not (Test-Path $destParent)) { New-Item -Path $destParent -ItemType Directory | Out-Null}
			}
		}

		@((Split-Path $profile -Parent),$PSScriptRoot,("$currLocation" -ne "$PSScriptRoot" ? $currLocation : ''),(Split-Path $source -Parent),(($destination -ne $source -and $destParent) ? $destParent : '')).foreach({
			Set-Env $_ -Verbose
		})
		#if ($destination -ne $path -and -not (Test-Path $destination -PathType Leaf)) { Set-Env $destination }

		if ($source.IndexOf('*') -eq -1 -and (Test-Path $source -PathType Leaf) ) {
			Write-Verbose "source:$source"
			if(-not (Test-Path $source -PathType Leaf)) {
				$results = Expand-TokenContent $source $regex
			} else {
				$source = (Get-Content $source -Raw)
				$results = Expand-TokenContent $source $regex
				#Write-Verbose "updated:$destination"
				$results | Out-File -Encoding ascii $destination
			}
		} else {
			Write-Verbose "source:$source"
			Get-ChildItem -Path $source | ForEach-Object {
				$path = $_.FullName
				Write-Verbose "path:$path"
				if (!(Test-Path $path -PathType Leaf)) {
					#Write-Verbose "SKIPPED Folder:$path"
				} else {
					$string = Expand-TokenContent (Get-Content $path -Raw) $regex
					#Write-Verbose "tokenized:$string"
					if (!$destination) {
						#Write-Verbose "updated:$path"
						$string | Out-File -Encoding ascii $path
					} else {
						if (Test-Path $destination -PathType Leaf) {
							#Write-Verbose "updated:$destination"
							$string | Out-File -Encoding ascii $destination
						} else {
							$currDestination = "$destination\$($_.Name)"
							#Write-Verbose "updated:$currDestination"
							$string | Out-File -Encoding ascii $currDestination
						}
					}
					$results += $path
				}
			}
		}
		#Write-Verbose "$PSScriptName end"
		return $results
	}
}
