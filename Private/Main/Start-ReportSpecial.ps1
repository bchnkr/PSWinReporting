function Start-ReportSpecial {
    [CmdletBinding()]
    param (
        [System.Collections.IDictionary] $Dates,
        [System.Collections.IDictionary] $EmailParameters,
        [System.Collections.IDictionary] $FormattingParameters,
        [System.Collections.IDictionary] $ReportOptions,
        [System.Collections.IDictionary] $ReportDefinitions,
        [System.Collections.IDictionary] $Target
    )
    $Verbose = ($PSCmdlet.MyInvocation.BoundParameters['Verbose'] -eq $true)
    $Time = Start-TimeLog
    $EventIDs = New-GenericList
    $Dates = Get-ChoosenDates -ReportTimes $ReportTimes

    # Get Servers
    $ServersList = New-ArrayList
    if ($Target.Servers.Enabled) {
        $Logger.AddInfoRecord("Preparing servers list - defined list")
        [Array] $Servers = foreach ($Server in $Target.Servers.Keys | Where-Object { $_ -ne 'Enabled' }) {

            if ($Target.Servers.$Server -is [System.Collections.IDictionary]) {
                #$Target.Servers.$Server
                [ordered] @{
                    ComputerName = $Target.Servers.$Server.ComputerName
                    LogName      = $Target.Servers.$Server.LogName
                }

            } elseif ($Target.Servers.$Server -is [Array] -or $Target.Servers.$Server -is [string]) {
                $Target.Servers.$Server
            }
        }
        $null = $ServersList.AddRange($Servers)
    }
    if ($Target.DomainControllers.Enabled) {
        $Logger.AddInfoRecord("Preparing servers list - Domain Controllers autodetection")
        [Array] $Servers = (Get-WinADDomainControllers -SkipEmpty).HostName
        $null = $ServersList.AddRange($Servers)
    }
    if ($Target.LocalFiles.Enabled) {
        $Files = Get-EventLogFileList -Sections $Target.LocalFiles
    }

    # Get LogNames
    $LogNames = foreach ($Report in  $ReportDefinitions.Keys | Where-Object { $_ -ne 'Enabled' }) {
        if ($ReportDefinitions.$Report.Enabled) {
            foreach ($SubReport in $ReportDefinitions.$Report.Keys | Where-Object { $_ -ne 'Enabled'}) {
                if ($ReportDefinitions.$Report.$SubReport.Enabled) {
                    $ReportDefinitions.$Report.$SubReport.LogName

                }
            }
        }
    }

    # Prepare list of servers and files to scan and their relation to LogName and EventIDs and DataTimes
    <#
        Server                                                    LogName         EventID                     Type
        ------                                                    -------         -------                     ----
        AD1                                                       Security        {5136, 5137, 5141, 5136...} Computer
        AD2                                                       Security        {5136, 5137, 5141, 5136...} Computer
        EVO1                                                      ForwardedEvents {5136, 5137, 5141, 5136...} Computer
        AD1.ad.evotec.xyz                                         Security        {5136, 5137, 5141, 5136...} Computer
        AD2.ad.evotec.xyz                                         Security        {5136, 5137, 5141, 5136...} Computer
        C:\MyEvents\Archive-Security-2018-08-21-23-49-19-424.evtx Security        {5136, 5137, 5141, 5136...} File
        C:\MyEvents\Archive-Security-2018-09-08-02-53-53-711.evtx Security        {5136, 5137, 5141, 5136...} File
        C:\MyEvents\Archive-Security-2018-09-14-22-13-07-710.evtx Security        {5136, 5137, 5141, 5136...} File
        C:\MyEvents\Archive-Security-2018-09-15-09-27-52-679.evtx Security        {5136, 5137, 5141, 5136...} File
        AD1                                                       System          104                         Computer
        AD2                                                       System          104                         Computer
        EVO1                                                      ForwardedEvents 104                         Computer
        AD1.ad.evotec.xyz                                         System          104                         Computer
        AD2.ad.evotec.xyz                                         System          104                         Computer
        C:\MyEvents\Archive-Security-2018-08-21-23-49-19-424.evtx System          104                         File
        C:\MyEvents\Archive-Security-2018-09-08-02-53-53-711.evtx System          104                         File
        C:\MyEvents\Archive-Security-2018-09-14-22-13-07-710.evtx System          104                         File
        C:\MyEvents\Archive-Security-2018-09-15-09-27-52-679.evtx System          104                         File
    #>

    [Array] $ExtendedInput = foreach ($Log in $LogNames | Sort-Object -Unique) {
        $EventIDs = foreach ($Report in  $ReportDefinitions.Keys | Where-Object { $_ -ne 'Enabled' }) {
            if ($ReportDefinitions.$Report.Enabled) {
                foreach ($SubReport in $ReportDefinitions.$Report.Keys | Where-Object { $_ -ne 'Enabled'}) {
                    if ($ReportDefinitions.$Report.$SubReport.Enabled) {
                        if ($ReportDefinitions.$Report.$SubReport.LogName -eq $Log) {
                            $ReportDefinitions.$Report.$SubReport.Events
                        }
                    }
                }
            }
        }
        $Logger.AddInfoRecord("Scanning Events ID: $($EventIDs) ($Log)")

        $OutputServers = foreach ($Server in $ServersList) {
            if ($Server -is [System.Collections.IDictionary]) {
                [PSCustomObject]@{
                    Server   = $Server.ComputerName
                    LogName  = $Server.LogName
                    EventID  = $EventIDs
                    Type     = 'Computer'
                    DateFrom = $Dates.DateFrom
                    DateTo   = $Dates.DateTo
                }
            } elseif ($Server -is [Array] -or $Server -is [string]) {
                foreach ($S in $Server) {
                    [PSCustomObject]@{
                        Server   = $S
                        LogName  = $Log
                        EventID  = $EventIDs
                        Type     = 'Computer'
                        DateFrom = $Dates.DateFrom
                        DateTo   = $Dates.DateTo
                    }
                }
            }
        }
        $OutputFiles = foreach ($File in $FIles) {
            [PSCustomObject]@{
                Server   = $File
                LogName  = $Log
                EventID  = $EventIDs
                Type     = 'File'
                DateFrom = $Dates.DateFrom
                DateTo   = $Dates.DateTo
            }
        }
        $OutputServers
        $OutputFiles
    }

    # Scan all events and get everything at once
    $AllEvents = Get-Events `
        -ExtendedInput $ExtendedInput `
        -ErrorAction SilentlyContinue `
        -ErrorVariable AllErrors `
        -Verbose:$Verbose

    foreach ($Errors in $AllErrors) {
        $Logger.AddErrorRecord($Errors)
    }


    # Prepare the results based on chosen criteria
    $Results = @{}
    foreach ($Report in  $ReportDefinitions.Keys | Where-Object { $_ -ne 'Enabled' }) {
        if ($ReportDefinitions.$Report.Enabled) {
            #$ReportNameTitle = Format-AddSpaceToSentence -Text $Report -ToLowerCase
            $Logger.AddInfoRecord("Running $Report")
            $TimeExecution = Start-TimeLog
            foreach ($SubReport in $ReportDefinitions.$Report.Keys | Where-Object { $_ -ne 'Enabled'}) {
                if ($ReportDefinitions.$Report.$SubReport.Enabled) {
                    $Logger.AddInfoRecord("Running $Report with subsection $SubReport")
                    [string] $EventsType = $ReportDefinitions.$Report.$SubReport.LogName
                    [Array] $EventsNeeded = $ReportDefinitions.$Report.$SubReport.Events
                    [Array] $EventsFound = Find-EventsNeeded -Events $AllEvents -EventIDs $EventsNeeded -EventsType $EventsType
                    [Array] $EventsFound = Get-EventsTranslation -Events $EventsFound -EventsDefinition $ReportDefinitions.$Report.$SubReport
                    $Logger.AddInfoRecord("Ending $Report with subsection $SubReport events found $($EventsFound.Count)")
                    $Results.$Report = $EventsFound
                }
            }
            $ElapsedTimeReport = Stop-TimeLog -Time $TimeExecution -Option OneLiner
            $Logger.AddInfoRecord("Ending $Report - Time to run $ElapsedTimeReport")
        }
    }


    # Prepare email body
    $Logger.AddInfoRecord('Prepare email head and body')
    $HtmlHead = Set-EmailHead -FormattingOptions $FormattingParameters
    $HtmlBody = Set-EmailReportBranding -FormattingParameters $FormattingParameters
    $HtmlBody += Set-EmailReportDetails -FormattingParameters $FormattingParameters -Dates $Dates -Warnings $Warnings


    # Prepare email body - tables (real data)
    if ($ReportOptions.AsHTML.Enabled) {
        #$EmailBody += Export-ReportToHTML -Report $ReportDefinitions.ReportsAD.Custom.ServersData.Enabled -ReportTable $ServersAD -ReportTableText 'Following AD servers were detected in forest'
        #$EmailBody += Export-ReportToHTML -Report $ReportDefinitions.ReportsAD.Custom.FilesData.Enabled -ReportTable $TableEventLogFiles -ReportTableText 'Following files have been processed for events'
        #$EmailBody += Export-ReportToHTML -Report $ReportDefinitions.ReportsAD.Custom.EventLogSize.Enabled -ReportTable $EventLogTable -ReportTableText 'Following event log sizes were reported'
        foreach ($ReportName in $ReportDefinitions.Keys) {
            $ReportNameTitle = Format-AddSpaceToSentence -Text $ReportName -ToLowerCase
            $HtmlBody += Export-ReportToHTML -Report $ReportDefinitions.$ReportName.Enabled -ReportTable $Results.$ReportName -ReportTableText "Following $ReportNameTitle happened"

        }
    }
    # Do Cleanup of Emails
    $HtmlBody = Set-EmailWordReplacements -Body $HtmlBody -Replace '**TimeToGenerateDays**' -ReplaceWith $time.Elapsed.Days
    $HtmlBody = Set-EmailWordReplacements -Body $HtmlBody -Replace '**TimeToGenerateHours**' -ReplaceWith $time.Elapsed.Hours
    $HtmlBody = Set-EmailWordReplacements -Body $HtmlBody -Replace '**TimeToGenerateMinutes**' -ReplaceWith $time.Elapsed.Minutes
    $HtmlBody = Set-EmailWordReplacements -Body $HtmlBody -Replace '**TimeToGenerateSeconds**' -ReplaceWith $time.Elapsed.Seconds
    $HtmlBody = Set-EmailWordReplacements -Body $HtmlBody -Replace '**TimeToGenerateMilliseconds**' -ReplaceWith $time.Elapsed.Milliseconds
    $HtmlBody = Set-EmailFormatting -Template $HtmlBody -FormattingParameters $FormattingParameters -ConfigurationParameters $ReportOptions -Logger $Logger -SkipNewLines

    $EmailBody = $HtmlHead + $HtmlBody


    $Reports = @()

    if ($ReportOptions.AsDynamicHTML.Enabled) {
        $ReportFileName = Set-ReportFile -FileNamePattern $ReportOptions.AsDynamicHTML.FilePattern -DateFormat $ReportOptions.AsDynamicHTML.DateFormat

        $DynamicHTML = New-HTML -TitleText $ReportOptions.AsDynamicHTML.Title `
            -HideLogos:(-not $ReportOptions.AsDynamicHTML.Branding.Logo.Show) `
            -RightLogoString $ReportOptions.AsDynamicHTML.Branding.Logo.RightLogo.ImageLink `
            -UseCssLinks:$ReportOptions.AsDynamicHTML.EmbedCSS `
            -UseStyleLinks:$ReportOptions.AsDynamicHTML.EmbedJS {

            foreach ($ReportName in $ReportDefinitions.Keys) {
                $ReportNameTitle = Format-AddSpaceToSentence -Text $ReportName
                if ($ReportDefinitions.$ReportName.Enabled) {
                    New-HTMLContent -HeaderText $ReportNameTitle -CanCollapse {
                        New-HTMLColumn -ColumnNumber 1 -ColumnCount 1 {
                            if ($null -ne $Results.$ReportName) {
                                Get-HTMLContentDataTable -ArrayOfObjects $Results.$ReportName -HideFooter
                            }
                        }
                    }
                }

            }
        }
        if ($null -ne $DynamicHTML) {
            [string] $DynamicHTMLPath = Save-HTML -HTML $DynamicHTML -FilePath "$($ReportOptions.AsDynamicHTML.Path)\$ReportFileName"
            $Reports += $DynamicHTMLPath
        }
    }

    if ($ReportOptions.AsExcel) {
        $Logger.AddInfoRecord('Prepare XLSX files with Events')
        $ReportFilePathXLSX = Set-ReportFileName -ReportOptions $ReportOptions -ReportExtension "xlsx"
        #Export-ReportToXLSX -Report $ReportDefinitions.ReportsAD.Custom.ServersData.Enabled -ReportOptions $ReportOptions -ReportFilePath $ReportFilePathXLSX -ReportName "Processed Servers" -ReportTable $ServersAD
        #Export-ReportToXLSX -Report $ReportDefinitions.ReportsAD.Custom.EventLogSize.Enabled -ReportOptions $ReportOptions -ReportFilePath $ReportFilePathXLSX -ReportName "Event log sizes" -ReportTable $EventLogTable

        foreach ($ReportName in $ReportDefinitions.Keys) {
            $ReportNameTitle = Format-AddSpaceToSentence -Text $ReportName
            Export-ReportToXLSX -Report $ReportDefinitions.$ReportName.Enabled -ReportOptions $ReportOptions -ReportFilePath $ReportFilePathXLSX -ReportName $ReportNameTitle -ReportTable $Results.$ReportName
        }
        $Reports += $ReportFilePathXLSX
    }
    if ($ReportOptions.AsCSV) {
        $Logger.AddInfoRecord('Prepare CSV files with Events')
        #$Reports += Export-ReportToCSV -Report $ReportDefinitions.ReportsAD.Custom.ServersData.Enabled -ReportOptions $ReportOptions -Extension "csv" -ReportName "ReportServers" -ReportTable $ServersAD
        #$Reports += Export-ReportToCSV -Report $ReportDefinitions.ReportsAD.Custom.EventLogSize.Enabled -ReportOptions $ReportOptions -Extension "csv" -ReportName "ReportEventLogSize" -ReportTable $EventLogTable

        foreach ($ReportName in $ReportDefinitions.Keys) {
            $Reports += Export-ReportToCSV -Report $ReportDefinitions.$ReportName.Enabled -ReportOptions $ReportOptions -Extension "csv" -ReportName $ReportName -ReportTable $Results.$ReportName
        }
    }
    $Reports = $Reports |  Where-Object { $_ } | Sort-Object -Unique






    # Sending email - finalizing package
    if ($ReportOptions.SendMail.Enabled) {

        foreach ($Report in $Reports) {
            $Logger.AddInfoRecord("Following files will be attached to email $Report")
        }


        $TemporarySubject = $EmailParameters.EmailSubject -replace "<<DateFrom>>", "$($Dates.DateFrom)" -replace "<<DateTo>>", "$($Dates.DateTo)"
        $Logger.AddInfoRecord('Sending email with reports')
        if ($FormattingParameters.CompanyBranding.Inline) {
            $SendMail = Send-Email -EmailParameters $EmailParameters -Body $EmailBody -Attachment $Reports -Subject $TemporarySubject -InlineAttachments @{logo = $FormattingParameters.CompanyBranding.Logo} #-Verbose
        } else {
            $SendMail = Send-Email -EmailParameters $EmailParameters -Body $EmailBody -Attachment $Reports -Subject $TemporarySubject #-Verbose
        }
        if ($SendMail.Status) {
            $Logger.AddInfoRecord('Email successfully sent')
        } else {
            $Logger.AddInfoRecord("Error sending message: $($SendMail.Error)")
        }
    }
    if ($ReportOptions.AsHTML.Enabled) {
        $ReportHTMLPath = Set-ReportFileName -ReportOptions $ReportOptions -ReportExtension 'html'
        $EmailBody | Out-File -Encoding Unicode -FilePath $ReportHTMLPath
        $Logger.AddInfoRecord("Saving report to file: $ReportHTMLPath")
        if ($ReportHTMLPath -ne '' -and ($ReportOptions.AsHTML.OpenAsFile)) {
            if (Test-Path -LiteralPath $ReportHTMLPath) {
                Invoke-Item $ReportHTMLPath
            }
        }
    }
    if ($ReportOptions.AsDynamicHTML.Enabled -and $ReportOptions.AsDynamicHTML.OpenAsFile) {
        if ($DynamicHTMLPath -ne '' -and (Test-Path -LiteralPath $DynamicHTMLPath)) {
            Invoke-Item $DynamicHTMLPath
        }
    }

    foreach ($ReportName in $ReportDefinitions.ReportsAD.EventBased.Keys) {
        $ReportNameTitle = Format-AddSpaceToSentence -Text $ReportName
        Export-ReportToSql -Report $ReportDefinitions.ReportsAD.EventBased.$ReportName -ReportOptions $ReportOptions -ReportName $ReportNameTitle -ReportTable $Results.$ReportName
    }
    Remove-ReportsFiles -KeepReports $ReportOptions.KeepReports -AsExcel $ReportOptions.AsExcel -AsCSV $ReportOptions.AsCSV -ReportFiles $Reports

    $ElapsedTime = Stop-TimeLog -Time $Time
    $Logger.AddInfoRecord("Time to finish $ElapsedTime")
}