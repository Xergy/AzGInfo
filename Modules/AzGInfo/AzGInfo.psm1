Function Export-AzGInfo {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzGInfoResults,
        [parameter(mandatory = $true)]
        $LocalPath
    )
    
    Process {

        $RootFolderStr = $AzGInfoResults.RunTime.substring(0,7)
        Write-Verbose "RootFolderStr = $RootFolderStr"
        $RunTime = $AzGInfoResults.RunTime
        Write-Verbose "RunTime = $RunTime"
        $ReportFolderStr = "$($RunTime)_AzGInfo"
        Write-Verbose "ReportFolderStr = $ReportFolderStr"

        $ReportLocalFolderFullPath = "$($LocalPath)\$($AzGInfoResults.ConfigLabel)\$($RootFolderStr)\$($ReportFolderStr)"
        Write-Verbose "ReportLocalFolderFullPath = $ReportLocalFolderFullPath"

        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Saving Data to $ReportLocalFolderFullPath"

        md $ReportLocalFolderFullPath | Out-Null
        
        Foreach ($TestResult in $AzGInfoResults.Results) {
            $TestResult.Results | Export-Csv -Path "$($ReportLocalFolderFullPath)\$($TestResult.ShortName).csv" -NoTypeInformation 
        }
        $AzGInfoResults | Export-Clixml -Path "$($ReportLocalFolderFullPath)\AzGInfoResults.xml" 

        # Save the report out to a file in the current path
        $AzGInfoResults.Reports.Detailed | Out-File -Force ("$($ReportLocalFolderFullPath)\AzGInfoDetailedReport.html")
        $AzGInfoResults.Reports.Summary | Out-File -Force ("$($ReportLocalFolderFullPath)\AzGInfoSummaryReport.html")
        
        # Email our report out
        # send-mailmessage -from $fromemail -to $users -subject "Systems Report" -Attachments $ListOfAttachments -BodyAsHTML -body $HTMLmessage -priority Normal -smtpServer $server

        #endregion

        #region Zip Results
        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Creating Archive ""$($ReportLocalFolderFullPath).zip"""
        Add-Type -assembly "system.io.compression.filesystem"

        [io.compression.zipfile]::CreateFromDirectory($ReportLocalFolderFullPath, "$($ReportLocalFolderFullPath)_$($AzInfoResults.ConfigLabel).zip") | Out-Null
        Move-Item "$($ReportLocalFolderFullPath)_$($AzInfoResults.ConfigLabel).zip" "$($ReportLocalFolderFullPath)"

    }
}

Function Get-AzGInfoHTMLReport {
    [CmdletBinding()]
    param (
        # [parameter(mandatory = $true)]
        # $AzGInfoResults,
        [Parameter(Mandatory=$false)]
        [Switch]
        $SummaryOnly
    )
    
    Process {


Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Building HTML Report" 
$Report = @()
$HTMLHeader = ""
$HTMLmessage = ""
$HTMLEnd = ""
$HTMLMiddle = @()
$CurrentHTML = @()

Function Addh1($h1Text){
    # Create HTML Report for the current System being looped through
    $CurrentHTML = @"
<hr noshade size=3 width="100%">

<p><h1>$h1Text</p></h1>
"@
return $CurrentHTML
}

Function Addh2($h2Text){
    # Create HTML Report for the current System being looped through
    $CurrentHTML = @"
<hr noshade size=3 width="75%">

<p><h2>$h2Text</p></h2>
"@
return $CurrentHTML
}

function GenericTable ($TableInfo,$TableHeader,$TableComment ) {
$MyTableInfo = $TableInfo | ConvertTo-HTML -fragment

    # Create HTML Report for the current System being looped through
    $CurrentHTML += @"
<h3>$TableHeader</h3>
<p>$TableComment</p>
<table class="normal">$MyTableInfo</table>	
"@

return $CurrentHTML
}

function ReportSummary ($ReportStats ) {
$CurrentHTML += @"
<h3>AzGInfo Summary</h3>
<table class="list">
<tr>
<td>Total Tasks</td>
<td>$($ReportStats.Tasks)</td>
</tr>
<tr>
<td>Item Rows</td>
<td>$($ReportStats.Rows)</td>
</tr>
</table>
"@
return $CurrentHTML
}
function GenericTestResult ($TestResult ) {
    $MyTableInfo = $TestResult.Results | ConvertTo-HTML -fragment
    $CurrentHTML += @"
<h3>$($TestResult.Title)</h3>
<p>$($TestResult.Description)</p>
<table class="normal">$MyTableInfo</table>	
"@

    return $CurrentHTML
    }

If (!$SummaryOnly) {
    $HTMLMiddle = AddH1 "AzGInfo Report"
} Else {
    $HTMLMiddle = AddH1 "AzGInfo Summary Report"
}

$HTMLMiddle += ReportSummary $AzGInfoResults.Stats 

$HTMLMiddle += GenericTable ($AzGInfoResults.Stats.TaskResultSummary | Sort-Object ReportWeight,Title) "Result Summary by Task" "Vital Stats on all Tasks"

If(!$SummaryOnly) {
    foreach ($TestResult in $AzGInfoResults.Results | Sort-Object Severity,ReportWeight,Title) {
        $HTMLMiddle += GenericTestResult $TestResult
    }
}

# Assemble the HTML Header and CSS for our Report
$HTMLHeader = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>AzGInfo Report</title>
<style type="text/css">
<!--
body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

#report { width: 835px; }

table{
border-collapse: collapse;
border: none;
font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
color: black;
margin-bottom: 10px;
}

table td{
font-size: 12px;
padding-left: 0px;
padding-right: 20px;
text-align: left;
}

table th {
font-size: 12px;
font-weight: bold;
padding-left: 0px;
padding-right: 20px;
text-align: left;
}

h2{ clear: both; font-size: 130%; }

h3{
clear: both;
font-size: 115%;
margin-left: 20px;
margin-top: 30px;
}

p{ margin-left: 20px; font-size: 12px; }

table.list{ float: left; }

table.list td:nth-child(1){
font-weight: bold;
border-right: 1px grey solid;
text-align: right;
}

table.list td:nth-child(2){ padding-left: 7px; }
table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }
table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
div.column { width: 320px; float: left; }
div.first{ padding-right: 20px; border-right: 1px  grey solid; }
div.second{ margin-left: 30px; }
table{ margin-left: 20px; }
-->
</style>
</head>
<body>

"@

# Assemble the closing HTML for our report.
$HTMLEnd = @"
</div>
</body>
</html>
"@

# Assemble the final HTML report from all our HTML sections
$HTMLmessage = $HTMLHeader + $HTMLMiddle + $HTMLEnd

#endregion

#$HTMLmessage | Out-File -Force (".\AzGInfo.html") 
#. .\AzGInfo.html

Return $HTMLmessage

        } # End Process Block for HTML Report
} # End Function for HTML Report


