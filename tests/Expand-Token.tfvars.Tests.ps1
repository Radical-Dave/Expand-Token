Describe 'tfvars smoke tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.tfvars.Tests.','.')
        Write-Verbose "ModuleScriptPath:$ModuleScriptPath"
        $ModuleScriptRoot = Split-Path $ModuleScriptPath -Parent
        Write-Verbose "PSScriptRoot:$PSScriptRoot"
        $PSScriptName = (Split-Path $ModuleScriptPath -Leaf).Replace('.ps1','')
        Write-Verbose "#####################################################`n# $PSScriptName"
        #. $ModuleScriptPath
    }
    It 'passes tfvars file copy' {
        $dest = "$ModuleScriptRoot\results\smoke\test\test-tfvars-file-copy\test.tfvars"
        . .\"$PSScriptName" "$PSScriptRoot\smoke\test\data\test.tfvars" $dest -Verbose | Should -Not -BeNullOrEmpty
        $results = (Get-Content "$dest")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes tfvars folder copy' {
        $dest = "$ModuleScriptRoot\results\smoke\test\test-tfvars-folder-copy"
        . .\"$PSScriptName" "$PSScriptRoot\smoke\test\data" $dest -Verbose | Should -Not -BeNullOrEmpty
        $results = (Get-Content "$dest\test.tfvars")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes tfvars file update' {
        $source = "$PSScriptRoot\smoke\test\data\test.tfvars"
        $dest = "$ModuleScriptRoot\results\smoke\test\test-tfvars-file-update\test.tfvars" #$source.replace('test-update-tfvars','test')
        if (-not (Test-Path $dest)) {
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) {New-Item -Path $parent -ItemType Directory | Out-Null}
        }
        #Copy-Item $source.replace('test-update-tfvars','test') $source -Force
        Copy-Item $source $dest -Force
        . .\"$PSScriptName" $dest -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        #Get-Item $source | Where-Object { $_.LastWriteTime -lt ($(Get-Date).AddMinutes(-1)) } | ForEach-Object { "Name:" + $_.Name}
        $results = (Get-Content $dest)
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes tfvars folder update' {
        #$destPath = "$ModuleScriptRoot\results\smoke\test\test-tvars-folder-update"
        #if (!(Test-Path $destPath)) {
        #    New-Item -Path $destPath -ItemType Directory | Out-Null
        #}
        $source = "$PSScriptRoot\smoke\test\data\test.tfvars"
        #$dest = "$destPath\test.tfvars"
        $dest = "$ModuleScriptRoot\results\smoke\test\test-tvars-folder-update\test.tfvars"
        if (-not (Test-Path $dest)) {
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) {New-Item -Path $parent -ItemType Directory | Out-Null}
        }
        #Copy-Item $source.replace('test-update-tfvars','test') $source -Force
        #Copy-Item $source $dest -Force
        Copy-Item "$PSScriptRoot\smoke\test\data\test.tfvars" -Destination "$dest" -Force -Recurse
        . .\"$PSScriptName" "$dest" -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        #Get-Item $source | Where-Object { $_.LastWriteTime -lt ($(Get-Date).AddMinutes(-1)) } | ForEach-Object { "Name:" + $_.Name}
        $results = (Get-Content "$dest")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
}