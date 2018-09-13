
# This allows the unit test to run locally, and from any $PWD path.
$joinPathParameters = @{
    Path = (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent)
    ChildPath = 'CompositeResource'
}

$modulePath = Join-Path @joinPathParameters

# Import the module with force so when testing locally it picks up any changes.
Import-Module $modulePath -Force

InModuleScope 'CompositeResource' {
    Describe 'ConvertTo-CompositeResource' {
        BeforeAll {
            $mockGuid = 'fbb616d3-f7b1-4681-a747-48ac62c6f8cb'

            # --- START MOCK CONFIGURATION

            <#
                .DESCRIPTION
                    This is the configuration description.

                .NOTES
                    This is notes about the configuration.
            #>
            Configuration Example
            {
                Import-DscResource -ModuleName PSDesiredStateConfiguration

                node localhost
                {
                    WindowsFeature 'NetFramework45'
                    {
                        Name   = 'NET-Framework-45-Core'
                        Ensure = 'Present'
                    }
                }
            }

            <#
                .DESCRIPTION
                    This is the configuration description.

                .NOTES
                    This is notes about the configuration.
            #>
            Configuration Example2
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true)]
                    [ValidateNotNullOrEmpty()]
                    [System.Management.Automation.PSCredential]
                    $InstallCredential
                )

                Import-DscResource -ModuleName PSDesiredStateConfiguration

                node localhost
                {
                    WindowsFeature 'NetFramework45'
                    {
                        Name   = 'NET-Framework-45-Core'
                        Ensure = 'Present'
                    }
                }
            }

            $configurationScriptBlock = {
                <#
                    .DESCRIPTION
                        This is the configuration description.

                    .NOTES
                        This is notes about the configuration.
                #>
                Configuration Example3
                {
                    Import-DscResource -ModuleName PSDesiredStateConfiguration

                    node localhost
                    {
                        WindowsFeature 'NetFramework45'
                        {
                            Name   = 'NET-Framework-45-Core'
                            Ensure = 'Present'
                        }
                    }
                }
            }
            # --- END MOCK CONFIGURATION
        }

        AfterAll {
            Remove-Item -Path 'function:Example'
            Remove-Item -Path 'function:Example2'
        }

        Context 'When converting a configuration using default values' {
            BeforeEach {
                $convertToCompositeResourceParameters = @{
                    ConfigurationName = 'Example'
                    ModuleVersion = '1.1.0'
                    OutputPath = $TestDrive
                }

                Mock -CommandName New-Guid -MockWith {
                    return @{
                        Guid = $mockGuid
                    }
                }
            }

            It 'Should have created the correct folder structure and correct files' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                "$TestDrive\ExampleDSC" | Should -Exist
                "$TestDrive\ExampleDSC\1.1.0" | Should -Exist
                "$TestDrive\ExampleDSC\1.1.0\ExampleDSC.psd1" | Should -Exist
                "$TestDrive\ExampleDSC\1.1.0\DSCResources" | Should -Exist
                "$TestDrive\ExampleDSC\1.1.0\DSCResources\Example" | Should -Exist
                "$TestDrive\ExampleDSC\1.1.0\DSCResources\Example\Example.psd1" | Should -Exist
                "$TestDrive\ExampleDSC\1.1.0\DSCResources\Example\Example.schema.psm1" | Should -Exist
            }

            It 'Should have written the correct content to the module manifest' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $moduleManifestPath = "$TestDrive\ExampleDSC\1.1.0\ExampleDSC.psd1"
                $moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
                $moduleManifest.GUID | Should -Be $mockGuid
                $moduleManifest.Author | Should -Be $env:USERNAME
                $moduleManifest.Description | Should -Be 'Automatically generated by the Composite Resource module.  http://github.com/microsoft/compositeresource'
                $moduleManifest.ModuleVersion | Should -Be '1.1.0'
                $moduleManifest.FunctionsToExport | Should -HaveCount 0
                $moduleManifest.VariablesToExport | Should -Be '*'
                $moduleManifest.CmdletsToExport  | Should -HaveCount 0
                $moduleManifest.AliasesToExport | Should -HaveCount 0
                $moduleManifest.DscResourcesToExport | Should -Be 'Example'
                $moduleManifest.PrivateData.PSData.Keys | Should -HaveCount 0
            }

            It 'Should have written the correct content to the resource manifest' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $resourceManifestPath = "$TestDrive\ExampleDSC\1.1.0\DSCResources\Example\Example.psd1"

                $resourceManifest = Import-PowerShellDataFile -Path $resourceManifestPath
                $resourceManifest.GUID | Should -Be $mockGuid
                $resourceManifest.Author | Should -Be $env:USERNAME
                $resourceManifest.ModuleVersion | Should -Be '1.0'
                $resourceManifest.FunctionsToExport | Should -Be '*'
                $resourceManifest.VariablesToExport | Should -Be '*'
                $resourceManifest.CmdletsToExport  | Should -Be '*'
                $resourceManifest.AliasesToExport | Should -Be '*'
                $resourceManifest.RootModule | Should -Be 'Example.schema.psm1'
                $resourceManifest.PrivateData.PSData.Keys | Should -HaveCount 0
            }

            It 'Should have written the correct content to the composite resource module file' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $resourceModulePath = "$TestDrive\ExampleDSC\1.1.0\DSCResources\Example\Example.schema.psm1"

                $parseErrors = $null
                $definitionAst = [System.Management.Automation.Language.Parser]::ParseFile($resourceModulePath, [ref] $null, [ref] $parseErrors)

                if ($parseErrors)
                {
                    throw $parseErrors
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst]
                }

                $configurationDefinition = $definitionAst.Find($astFilter, $true)

                <#
                    Each line must exist as it does in the actual output of the
                    definition, but the test will trim any existing white space
                    characters before and after each row. It will do this for
                    both the expected and the actual definition.
                #>
                $expectedDefinition = @"
Configuration Example
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node localhost
    {
        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
    }

}
"@

                $configurationDefinition.ConfigurationType | Should -Be 'Resource'

                <#
                    We remove carriage return  character before splitting so we
                    always know the correct line-ending character.
                #>
                $definitionRows = ($configurationDefinition.Extent.Text -replace '\r') -split '\n'
                $expectedDefinitionRows = ($expectedDefinition -replace '\r') -split '\n'

                # Test so that we have equal number of rows.
                $definitionRows.Count | Should -Be $expectedDefinitionRows.Count

                for ($line = 0; $line -le $expectedDefinitionRows.Count - 1; $line++)
                {
                    # Trimming any white space characters before and after each line.
                    $definitionRows[$line].Trim() | Should -Be $expectedDefinitionRows[$line].Trim()
                }
            }
        }

        Context 'When converting a configuration using specific parameter values' {
            BeforeEach {
                $convertToCompositeResourceParameters = @{
                    ConfigurationName = 'Example'
                    ResourceName = 'MyResource'
                    ModuleName = 'MyModuleDsc'
                    ModuleVersion = '1.1.0'
                    OutputPath = $TestDrive
                }

                Mock -CommandName New-Guid -MockWith {
                    return @{
                        Guid = $mockGuid
                    }
                }
            }

            It 'Should have created the correct folder structure and correct files' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                "$TestDrive\MyModuleDsc" | Should -Exist
                "$TestDrive\MyModuleDsc\1.1.0" | Should -Exist
                "$TestDrive\MyModuleDsc\1.1.0\MyModuleDsc.psd1" | Should -Exist
                "$TestDrive\MyModuleDsc\1.1.0\DSCResources" | Should -Exist
                "$TestDrive\MyModuleDsc\1.1.0\DSCResources\MyResource" | Should -Exist
                "$TestDrive\MyModuleDsc\1.1.0\DSCResources\MyResource\MyResource.psd1" | Should -Exist
                "$TestDrive\MyModuleDsc\1.1.0\DSCResources\MyResource\MyResource.schema.psm1" | Should -Exist
            }

            It 'Should have written the correct content to the module manifest' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $moduleManifestPath = "$TestDrive\MyModuleDsc\1.1.0\MyModuleDsc.psd1"

                $moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
                $moduleManifest.GUID | Should -Be $mockGuid
                $moduleManifest.Author | Should -Be $env:USERNAME
                $moduleManifest.Description | Should -Be 'Automatically generated by the Composite Resource module.  http://github.com/microsoft/compositeresource'
                $moduleManifest.CompanyName | Should -Be 'Unknown'
                $moduleManifest.ModuleVersion | Should -Be '1.1.0'
                $moduleManifest.FunctionsToExport | Should -HaveCount 0
                $moduleManifest.VariablesToExport | Should -Be '*'
                $moduleManifest.CmdletsToExport  | Should -HaveCount 0
                $moduleManifest.AliasesToExport | Should -HaveCount 0
                $moduleManifest.DscResourcesToExport | Should -Be 'MyResource'
                $moduleManifest.PrivateData.PSData.Keys | Should -HaveCount 0
            }

            It 'Should have written the correct content to the resource manifest' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $resourceManifestPath = "$TestDrive\MyModuleDsc\1.1.0\DSCResources\MyResource\MyResource.psd1"

                $resourceManifest = Import-PowerShellDataFile -Path $resourceManifestPath
                $resourceManifest.GUID | Should -Be $mockGuid
                $resourceManifest.Author | Should -Be $env:USERNAME
                $resourceManifest.ModuleVersion | Should -Be '1.0'
                $resourceManifest.FunctionsToExport | Should -Be '*'
                $resourceManifest.VariablesToExport | Should -Be '*'
                $resourceManifest.CmdletsToExport  | Should -Be '*'
                $resourceManifest.AliasesToExport | Should -Be '*'
                $resourceManifest.RootModule | Should -Be 'MyResource.schema.psm1'
                $resourceManifest.PrivateData.PSData.Keys | Should -HaveCount 0
            }
        }

        Context 'When converting two configurations into the same module' {
            BeforeEach {
                $convertToCompositeResourceParameters1 = @{
                    ConfigurationName = 'Example'
                    ResourceName = 'MyResource1'
                    ModuleName = 'MyModuleDsc'
                    ModuleVersion = '1.0.0'
                    OutputPath = $TestDrive
                }

                $convertToCompositeResourceParameters2 = @{
                    ConfigurationName = 'Example2'
                    ResourceName = 'MyResource2'
                    ModuleName = 'MyModuleDsc'
                    ModuleVersion = '1.0.0'
                    OutputPath = $TestDrive
                }

                Mock -CommandName New-Guid -MockWith {
                    return @{
                        Guid = $mockGuid
                    }
                }
            }

            It 'Should have created the correct folder structure and correct files' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters1
                } | Should -Not -Throw

                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters2
                } | Should -Not -Throw

                "$TestDrive\MyModuleDsc" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0\MyModuleDsc.psd1" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0\DSCResources" | Should -Exist

                "$TestDrive\MyModuleDsc\1.0.0\DSCResources\MyResource1" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0\DSCResources\MyResource1\MyResource1.psd1" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0\DSCResources\MyResource1\MyResource1.schema.psm1" | Should -Exist

                "$TestDrive\MyModuleDsc\1.0.0\DSCResources\MyResource2" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0\DSCResources\MyResource2\MyResource2.psd1" | Should -Exist
                "$TestDrive\MyModuleDsc\1.0.0\DSCResources\MyResource2\MyResource2.schema.psm1" | Should -Exist
            }

            It 'Should have written the correct content to the module manifest' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters1
                } | Should -Not -Throw

                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters2
                } | Should -Not -Throw

                $moduleManifestPath = "$TestDrive\MyModuleDsc\1.0.0\MyModuleDsc.psd1"

                $moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
                $moduleManifest.DscResourcesToExport | Should -Be @('MyResource1','MyResource2')
            }
        }

        Context 'When converting a configuration from a script block' {
            BeforeEach {
                $convertToCompositeResourceParameters = @{
                    ScriptBlock = $configurationScriptBlock
                    ResourceName = 'MyResource'
                    ModuleName = 'MyScriptModuleDsc'
                    ModuleVersion = '1.0.0'
                    OutputPath = $TestDrive
                }

                Mock -CommandName New-Guid -MockWith {
                    return @{
                        Guid = $mockGuid
                    }
                }
            }

            It 'Should have created the correct folder structure and correct files' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                "$TestDrive\MyScriptModuleDsc" | Should -Exist
                "$TestDrive\MyScriptModuleDsc\1.0.0" | Should -Exist
                "$TestDrive\MyScriptModuleDsc\1.0.0\MyScriptModuleDsc.psd1" | Should -Exist
                "$TestDrive\MyScriptModuleDsc\1.0.0\DSCResources" | Should -Exist
                "$TestDrive\MyScriptModuleDsc\1.0.0\DSCResources\MyResource" | Should -Exist
                "$TestDrive\MyScriptModuleDsc\1.0.0\DSCResources\MyResource\MyResource.psd1" | Should -Exist
                "$TestDrive\MyScriptModuleDsc\1.0.0\DSCResources\MyResource\MyResource.schema.psm1" | Should -Exist
            }

            It 'Should have written the correct content to the module manifest' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $moduleManifestPath = "$TestDrive\MyScriptModuleDsc\1.0.0\MyScriptModuleDsc.psd1"

                $moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
                $moduleManifest.DscResourcesToExport | Should -Be @('MyResource')
            }

            It 'Should have written the correct content to the composite resource module file' {
                {
                    ConvertTo-CompositeResource @convertToCompositeResourceParameters
                } | Should -Not -Throw

                $resourceModulePath = "$TestDrive\MyScriptModuleDsc\1.0.0\DSCResources\MyResource\MyResource.schema.psm1"

                $parseErrors = $null
                $definitionAst = [System.Management.Automation.Language.Parser]::ParseFile($resourceModulePath, [ref] $null, [ref] $parseErrors)

                if ($parseErrors)
                {
                    throw $parseErrors
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst]
                }

                $configurationDefinition = $definitionAst.Find($astFilter, $true)

                <#
                    Each line must exist as it does in the actual output of the
                    definition, but the test will trim any existing white space
                    characters before and after each row. It will do this for
                    both the expected and the actual definition.
                #>
                $expectedDefinition = @"
Configuration MyResource
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node localhost
    {
        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
    }

}
"@

                $configurationDefinition.ConfigurationType | Should -Be 'Resource'

                <#
                    We remove carriage return character before splitting so we
                    always know the correct line-ending character.
                #>
                $definitionRows = ($configurationDefinition.Extent.Text -replace '\r') -split '\n'
                $expectedDefinitionRows = ($expectedDefinition -replace '\r') -split '\n'

                # Test so that we have equal number of rows.
                $definitionRows.Count | Should -Be $expectedDefinitionRows.Count

                for ($line = 0; $line -le $expectedDefinitionRows.Count - 1; $line++)
                {
                    # Trimming any white space characters before and after each line.
                    $definitionRows[$line].Trim() | Should -Be $expectedDefinitionRows[$line].Trim()
                }
            }
        }
    }

    Describe 'Cleanup' {
        It 'Should not contain an configuration in the session' {
            Get-Command Example -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            Get-Command Example2 -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
