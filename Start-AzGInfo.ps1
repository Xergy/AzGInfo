<#
    .SYNOPSIS
        AzGInfo Synopsis

    .NOTES
        AzGInfo Notes         
#>
param (
    $ConfigLabel = "AllSubsAndRGs"
)

$NowStr = Get-Date -Format yyyy-MM-ddTHH.mm

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Starting..."
$VerbosePreference = "Continue"

$ScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
Set-Location $ScriptDir

#Reload AzGInfo Modules
If (get-module AzGInfo) {Remove-Module AzGInfo}
Import-Module .\Modules\AzGInfo -Force

If (get-module AzGInfoTask) {Remove-Module AzGInfoTask}
Import-Module .\Modules\AzGInfoTask -Force

Switch ($ConfigLabel) {
    All {
        # Set Flow Flags
    }
}

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Performing Tasks..."

# Perform Tasks
$Tasks = (Get-Command -verb "Invoke" -Noun "AzGInfo*").Name

$AzGInfoResults = @{
    Results = @()
    ConfigLabel = $ConfigLabel
    RunTime = $NowStr
    Reports = @{
        Detailed = @()
        Summary = @()
    }
    Stats = @()
}

Foreach ($Task in $Tasks) {
    $AzGInfoResults.Results += Invoke-Expression "$($Task)" 
}

$TaskResultSummary = $AzGInfoResults.Results | Select-Object -Property Title,Description,ShortName,ReportWeight,Total | Sort-Object Severity,Weight,Title

$Stats = @{
    Tasks = ($AzGInfoResults.Results).Count
    Rows = $AzGInfoResults.Results.Total | Measure-Object -sum | Select-Object -ExpandProperty Sum 
    TaskResultSummary = $TaskResultSummary
}

#Add in Stats
$AzGInfoResults.Stats = $Stats

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Building HTML Report..."
#Build HTML Reports

$AzGInfoResults.Reports.Detailed = Get-AzGInfoHTMLReport 
$AzGInfoResults.Reports.Summary = Get-AzGInfoHTMLReport -SummaryOnly

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Running Export-AzGInfo..."

$Params = @{
    AzGInfoResults = $AzGInfoResults
    LocalPath = "C:\Temp"    
}

Export-AzGInfo @Params

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Done!"
