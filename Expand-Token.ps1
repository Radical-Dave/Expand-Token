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

.LICENSEURI https://github.com/Radical-Dave/Expand-Token/blob/main/LICENSE

.PROJECTURI https://github.com/Radical-Dave/Expand-Token

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS Expand-TokenString,Set-EnvToken

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#

.DESCRIPTION
 PowerShell Script to expand tokens in file/folder/strings using RegEx, EnvVar EnvironmentVariables, .env files and .with

.PARAMETER source
Source path to process

.PARAMETER destination
Destination path for output - if not provided, overwrites

.PARAMETER regex
Regex pattern for finding tokens - default to powershell format:
#>
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
	$currLocation = Get-Location
	Write-Verbose "#####################################################`n# $PSScriptName $source $destination called by:$PSCallingScript from $currLocation"
}
process {
	if (!$source) { $source = "$currLocation" }
	if ($source -eq $PSScriptRoot) { throw "$PSScriptName ERROR - will not run in root of $PSScriptRoot"}
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
	Write-Output "source:$source"
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

	if (-not (Get-Command -Name 'Set-EnvToken')) {Install-Script -Name 'Set-EnvToken' -Confirm:$False -Force}
	Set-EnvToken @((Split-Path $profile -Parent),$PSScriptRoot,("$currLocation" -ne "$PSScriptRoot" ? $currLocation : ''),(Split-Path $source -Parent),(($destination -ne $source -and $destParent) ? $destParent : ''))
	#if ($destination -ne $path -and -not (Test-Path $destination -PathType Leaf)) { Set-Env $destination }

	if (-not (Get-Command -Name 'Expand-TokenString')) {Install-Script -Name 'Expand-TokenString' -Confirm:$False -Force}
	if ($source.IndexOf('*') -eq -1 -and (Test-Path $source -PathType Leaf) ) {
		Write-Verbose "source:$source"
		if(-not (Test-Path $source -PathType Leaf)) {
			$results = Expand-TokenString $source -regex $regex
		} else {
			$source = (Get-Content $source -Raw)
			$results = Expand-TokenString $source -regex $regex
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
				$string = Expand-TokenString (Get-Content $path -Raw) -regex $regex
				#Write-Verbose "tokenized:$string"
				Write-Output "destination:$destination"
				if (!$destination) {
					Write-Output "updated:$path"
					$string | Out-File -Encoding ascii $path
				} else {
					if ((Test-Path $destination -PathType Leaf) -and $destination.IndexOf('*') -eq -1) {
						#Write-Verbose "updated:$destination"
						$string | Out-File -Encoding ascii $destination
					} else {
						if ($destination.IndexOf('*') -ne -1) {
							$currDestination = "$(Split-Path $destination -Parent)"
							Write-Output "currDestination:$currDestination"
							if ($currDestination -eq '/' -or $currDestination -eq '\') {
								$currDestination = Get-Location
								Write-Output "currDestination:$currDestination"
							}
							$currDestination = "$currDestination\$($_.Name)"
						} else {
							$currDestination = "$destination\$($_.Name)"
						}
						Write-Output "updated:$currDestination"
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


