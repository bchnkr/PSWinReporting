﻿#
# Module manifest for module 'PSWinReportingV2'
#
# Generated by: Przemyslaw Klys
#
# Generated on: 29.04.2019
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'PSWinReportingV2.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.8'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = 'ea2bd8d2-cca1-4dc3-9e1c-ff80b06e8fbe'

    # Author of this module
    Author = 'Przemyslaw Klys'

    # Company or vendor of this module
    CompanyName = 'Evotec'

    # Copyright statement for this module
    Copyright = '(c) 2011 - 2019 Przemyslaw Klys. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PSWinReportingV2 is fast and efficient Event Viewing, Event Reporting and Event Collecting tool. It''s version 2 of known PSWinReporting PowerShell module and can work next to it.'

    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @('PSEventViewer', 
        'PSSharedGoods', 
        'PSWriteExcel', 
        'PSWriteHTML')

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Add-EventsDefinitions', 'Add-WinTaskScheduledForwarder', 
    'Find-Events', 'New-WinSubscriptionTemplates', 
    'Remove-WinTaskScheduledForwarder', 'Start-WinNotifications', 
    'Start-WinReporting', 'Start-WinSubscriptionService'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    # VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = 'PSWinReporting', 'ActiveDirectory', 'Events', 'Reporting', 'Windows', 
            'EventLog'

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/EvotecIT/PSWinReporting'

            # A URL to an icon representing this module.
            IconUri = 'https://evotec.xyz/wp-content/uploads/2018/10/PSWinReporting.png'

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}