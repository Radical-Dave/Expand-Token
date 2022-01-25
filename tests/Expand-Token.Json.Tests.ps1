Describe 'json smoke tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.Json.Tests.','.')
        $ModuleScriptRoot = Split-Path $ModuleScriptPath -Parent
        $PSScriptName = (Split-Path $ModuleScriptPath -Leaf).Replace('.ps1','')
        Write-Verbose "#####################################################`n# $PSScriptName"
        #. $ModuleScriptPath
    }
    It 'passes json file copy' {
        #if (-not (Test-Path "$ModuleScriptRoot\results\smoke\test\test-copy-json")) { New-Item -Path "$ModuleScriptRoot\results\smoke\test\test-copy-json" -ItemType Directory | Out-Null}
        #&"$PSScriptName"
        $dest = "$ModuleScriptRoot\results\smoke\test\test-json-file-copy\test.json"
        . .\"$PSScriptName" "$PSScriptRoot\smoke\test\data\test.json" $dest -Verbose | Should -Not -BeNullOrEmpty
        $results = (Get-Content "$dest")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes json file update' {
        $source = "$PSScriptRoot\smoke\test\data\test.json"
        $dest = "$ModuleScriptRoot\results\smoke\test\test-json-file-update\test.json"
        if (-not (Test-Path $dest)) {
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) {New-Item -Path $parent -ItemType Directory | Out-Null}
        }
        Copy-Item $source $dest -Force
        . .\"$PSScriptName" $dest -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        #Get-Item $source | Where-Object { $_.LastWriteTime -lt ($(Get-Date).AddMinutes(-1)) } | ForEach-Object { "Name:" + $_.Name}
        $results = (Get-Content $dest)
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes json folder copy' {
        . .\"$PSScriptName" "$PSScriptRoot\smoke\test\data" "$ModuleScriptRoot\results\smoke\test\test-json-folder-copy" -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        $results = (Get-Content "results\smoke\test\test-json-folder-copy\test.json")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes json folder update' {
        if (!(Test-Path "$ModuleScriptRoot\results\smoke\test\test-json-folder-update")) {
            New-Item -Path "$ModuleScriptRoot\results\smoke\test\test-json-folder-update" -ItemType Directory | Out-Null
        }
        Copy-Item "$PSScriptRoot\smoke\test\data\*.*" -Destination "$ModuleScriptRoot\results\smoke\test\test-json-folder-update" -Force -Recurse
        . .\"$PSScriptName" "$ModuleScriptRoot\results\smoke\test\test-json-folder-update" -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        $results = (Get-Content "results\smoke\test\test-json-folder-update\test.json")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
}