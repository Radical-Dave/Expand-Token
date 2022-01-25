Describe 'tfvars smoke tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.tfvars.Tests.','.')
        Write-Verbose "ModuleScriptPath:$ModuleScriptPath"
        $ModuleScriptRoot = Split-Path $ModuleScriptPath -Parent
        Write-Verbose "PSScriptRoot:$PSScriptRoot"
        $PSScriptName = (Split-Path $ModuleScriptPath -Leaf).Replace('.ps1','')
        Write-Verbose "#####################################################`n# $PSScriptName"
        . $ModuleScriptPath
    }
    It 'passes tfvars copy file' {
        $dest = "$ModuleScriptRoot\results\smoke\test\test-copy-tfvars-file\test.tfvars"
        &"$PSScriptName" "$PSScriptRoot\smoke\test\data\test.tfvars" $dest -Verbose | Should -Not -BeNullOrEmpty
        $results = (Get-Content "$dest")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes tfvars copy folder' {
        $dest = "$ModuleScriptRoot\results\smoke\test\test-copy-tfvars-folder"
        &"$PSScriptName" "$PSScriptRoot\smoke\test\data" $dest -Verbose | Should -Not -BeNullOrEmpty
        $results = (Get-Content "$dest\test.tfvars")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes tfvars update file' {
        $source = "$PSScriptRoot\smoke\test\data\test.tfvars"
        $dest = "$ModuleScriptRoot\results\smoke\test\test-update-tfvars-file\test.tfvars" #$source.replace('test-update-tfvars','test')
        if (-not (Test-Path $dest)) {
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) {New-Item -Path $parent -ItemType Directory | Out-Null}
        }
        #Copy-Item $source.replace('test-update-tfvars','test') $source -Force
        Copy-Item $source $dest -Force
        &"$PSScriptName" $dest -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        #Get-Item $source | Where-Object { $_.LastWriteTime -lt ($(Get-Date).AddMinutes(-1)) } | ForEach-Object { "Name:" + $_.Name}
        $results = (Get-Content $dest)
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes tfvars update folder' {
        $source = "$PSScriptRoot\smoke\test\data\test.tfvars"
        $dest = "$ModuleScriptRoot\results\smoke\test\test-update-tfvars-folder"
        if (-not (Test-Path $dest)) {
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) {New-Item -Path $parent -ItemType Directory | Out-Null}
        }
        #Copy-Item $source.replace('test-update-tfvars','test') $source -Force
        Copy-Item $source $dest -Force
        &"$PSScriptName" $dest -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        #Get-Item $source | Where-Object { $_.LastWriteTime -lt ($(Get-Date).AddMinutes(-1)) } | ForEach-Object { "Name:" + $_.Name}
        $results = (Get-Content $dest)
        $results | Should -Not -BeLike '*$(subscription)*'
    }
}