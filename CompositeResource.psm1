function ConvertTo-CompositeResource
{
    [CmdletBinding()]
    param
    (
        # PowerShell DSC Configuration Name
        [Parameter(Mandatory = $true)]
        [string]
        $ConfigurationName,

        # PowerShell DSC Configuration Name
        # Defaults to the configuration name.
        [Parameter()]
        [string]
        $ResourceName = $ConfigurationName,

        # PowerShell DSC Configuration Name
        # Defaults to the configuration name, suffixed with 'DSC'.
        [Parameter()]
        [string]
        $ModuleName = "$($ConfigurationName)DSC",

        # Module Version
        [Parameter(Mandatory = $true)]
        [version]
        $ModuleVersion,

        # Author to list in module manifest
        [Parameter()]
        [string]
        $Author = 'Composite Resource Module',
        
        # Description to list in module manifest
        [Parameter()]
        [string]
        $Description = 'Automatically generated by the Composite Resource module.  http://github.com/microsoft/compositeresource',

        # File path to output module
        [Parameter()]
        [string]
        $OutputPath = '.\'
    )

    $configuration = Get-Command -Name $ConfigurationName -CommandType 'Configuration' -ErrorAction SilentlyContinue
    if (-not $configuration)
    {
        throw ('Could not find a configuration ''{0}'' loaded in the session.' -f $ConfigurationName)
    }

    $moduleFolder = Join-Path -Path $OutputPath -ChildPath $ModuleName
    $versionFolder = Join-Path -Path $moduleFolder -ChildPath $ModuleVersion.ToString()
    $dscResourcesFolder = Join-Path -Path $versionFolder -ChildPath 'DSCResources'
    $configurationFolder = Join-Path -Path $dscResourcesFolder -ChildPath $ResourceName

    # Creates the folder structure if any folder does not exist.
    if (-not (Resolve-Path -Path $configurationFolder -ErrorAction 'SilentlyContinue'))
    {
        New-Item -Path $configurationFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    $resourcePsm1 = Join-Path -Path $configurationFolder -ChildPath "$ResourceName.schema.psm1"
    $resourcePsd1 = Join-Path -Path $configurationFolder -ChildPath "$ResourceName.psd1"
    $modulePsd1 = Join-Path -Path $versionFolder -ChildPath "$ModuleName.psd1"

    Set-Content -Path $resourcePsm1 -Value @"
Configuration $ResourceName
{
$($Configuration.Definition)
}
"@

    $resourceNames = @()

    # If we already got a module manifest, then pick up any existing resource names.
    if (Test-Path -Path $modulePsd1)
    {
        $moduleManifest = Import-PowerShellDataFile -Path $modulePsd1
        $resourceNames = @($moduleManifest.DscResourcesToExport)
    }

    if ($resourceNames -notcontains $ResourceName)
    {
        $resourceNames += $ResourceName
    }

    New-ModuleManifest -Path $modulePsd1 `
        -Guid (New-Guid).Guid `
        -Author $Author `
        -Description $Description `
        -ModuleVersion $ModuleVersion `
        -DscResourcesToExport $resourceNames

    New-ModuleManifest -Path $resourcePsd1 `
        -RootModule "$ResourceName.schema.psm1" `
        -Guid (New-Guid).Guid
}
