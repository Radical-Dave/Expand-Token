Describe 'folder smoke tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.Folder.Tests.','.')
        $ModuleScriptRoot = Split-Path $ModuleScriptPath -Parent
        $PSScriptName = (Split-Path $ModuleScriptPath -Leaf).Replace('.ps1','')
        Write-Verbose "#####################################################`n# $PSScriptName"
        . $ModuleScriptPath
        if (!(Test-Path "$ModuleScriptRoot\results\smoke\test\test-update-folder")) {
            New-Item -Path "$ModuleScriptRoot\results\smoke\test\test-update-folder" -ItemType Directory | Out-Null
        }
    }
    It 'passes folder copy' {
        &"$PSScriptName" "$PSScriptRoot\smoke\test\data" "$ModuleScriptRoot\results\smoke\test\test-copy-folder" -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        $results = (Get-Content "results\smoke\test\test-copy-folder\test.json")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
    It 'passes folder update' {
        Copy-Item "$PSScriptRoot\smoke\test\data\*.*" -Destination "$ModuleScriptRoot\results\smoke\test\test-update-folder" -Force -Recurse
        &"$PSScriptName" "$ModuleScriptRoot\results\smoke\test\test-update-folder" -Verbose| Should -Not -BeNullOrEmpty
        $? | Should -Be $true
        $results = (Get-Content "results\smoke\test\test-update-folder\test.json")
        $results | Should -Not -BeLike '*$(subscription)*'
    }
}