Describe 'smoke tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.Tests.','.')
        $PSScriptName = (Split-Path $ModuleScriptPath -Leaf).Replace('.ps1','')
        Write-Verbose "#####################################################`n# $PSScriptName"
        . $ModuleScriptPath
    }
    It 'passes default PSScriptAnalyzer rules' {        
        Invoke-ScriptAnalyzer -Path $ModuleScriptPath | Should -BeNullOrEmpty
    }
    It 'passes empty params' {
        {&"$PSScriptName"} | Should -Not -BeNullOrEmpty
    }
    It 'passes do test' {
        #.\Set-Tokens "$PSScriptRoot\tests\az\$armconfig\*.json" "$PSScriptRoot\tests\az\$myResourceGroupName-$armconfig" -Verbose
        #Copy-Item "$PSScriptRoot\tests\smoke\test" -Destination "$PSScriptRoot\tests\smoke\test-update-folder" -Force -Recurse
        #.\Set-Tokens "tests\smoke\test-update-folder" -Verbose| Should -Not -BeNullOrEmpty
        #$? | Should -Be $true
        #$results = (Get-Content "tests\smoke\test-update-folder\test.json")
        #$results | Should -Not -BeLike '*$(subscription)*'
    }
}