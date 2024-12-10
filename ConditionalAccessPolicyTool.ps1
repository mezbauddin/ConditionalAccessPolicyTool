#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Authentication

<#
.SYNOPSIS
    Retrieves and analyzes Conditional Access Policies from Microsoft Entra ID.
.DESCRIPTION
    This script gets all Conditional Access Policies, analyzes their configuration,
    and generates an HTML report with policy details and potential recommendations.
.NOTES
    Version:        1.0
    Author:         Mezba Uddin
    Creation Date:  2024-01-18
    License:        MIT
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$NoMenu
)

# Banner and title definitions
$banner = @"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                         MEZBA UDDIN                              ║
║                                                                  ║
║              Microsoft Most Valuable Professional                ║
║                           (MVP)                                  ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║ 💡 Inspiring IT Innovation and Transformation                    ║
║ 🌐 Website:    mezbauddin.com                                   ║
║ 🔗 LinkedIn:   linkedin.com/in/mezbauddin                       ║
║ 📧 Email:      contact@mezbauddin.com                           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@

$title = @"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║             ENTRA ID CONDITIONAL ACCESS POLICY TOOL              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@

# Function to initialize Microsoft Graph connection
function Connect-ToGraph {
    try {
        $requiredScopes = @(
            "Policy.Read.All",
            "Directory.Read.All",
            "Reports.Read.All"
        )
        
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes $requiredScopes
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $_"
        exit 1
    }
}

# Function to get all Conditional Access Policies
function Get-AllCAPolicies {
    try {
        $policies = Get-MgIdentityConditionalAccessPolicy
        return $policies
    }
    catch {
        Write-Error "Failed to retrieve Conditional Access Policies: $_"
        return $null
    }
}

# Function to analyze policy configuration
function Analyze-CAPolicy {
    param (
        [Parameter(Mandatory = $true)]
        $Policy
    )

    $analysis = @{
        Name = $Policy.DisplayName
        State = $Policy.State
        Recommendations = @()
    }

    # Check for best practices
    if ($Policy.State -eq "disabled") {
        $analysis.Recommendations += "Policy is currently disabled - consider enabling or removing if not needed"
    }

    if ($null -eq $Policy.Conditions.Applications.IncludeApplications) {
        $analysis.Recommendations += "No applications specified in conditions - review policy scope"
    }

    if ($null -eq $Policy.Conditions.Users.ExcludeUsers -and $null -eq $Policy.Conditions.Users.ExcludeGroups) {
        $analysis.Recommendations += "Consider adding break-glass account exclusions"
    }

    return $analysis
}

# Function to display policies in terminal
function Show-PoliciesInTerminal {
    param (
        [Parameter(Mandatory = $true)]
        $Policies
    )
    
    Write-Host "`nConditional Access Policies:" -ForegroundColor Cyan
    foreach ($policy in $Policies) {
        Write-Host "`n----------------------------------------" -ForegroundColor Gray
        Write-Host "Name: $($policy.DisplayName)" -ForegroundColor Yellow
        Write-Host "State: $($policy.State)"
        Write-Host "Created: $($policy.CreatedDateTime)"
        Write-Host "Modified: $($policy.ModifiedDateTime)"
        
        if ($policy.Conditions.Users.IncludeUsers) {
            Write-Host "Include Users: $($policy.Conditions.Users.IncludeUsers -join ', ')"
        }
        if ($policy.Conditions.Users.ExcludeUsers) {
            Write-Host "Exclude Users: $($policy.Conditions.Users.ExcludeUsers -join ', ')"
        }
    }
}

# Function to show menu and get user selection
function Show-Menu {
    Clear-Host
    Write-Host $banner -ForegroundColor Cyan
    Write-Host $title -ForegroundColor Yellow
    Write-Host "1: Display policies in terminal"
    Write-Host "2: Generate HTML report"
    Write-Host "3: Export policies to JSON"
    Write-Host "Q: Quit"
    Write-Host
    
    do {
        $selection = Read-Host "Please make a selection"
        $selection = $selection.ToUpper()
    } until ($selection -match '^[123Q]$')
    
    return $selection
}

# Function to show export menu and get policy selection
function Show-ExportMenu {
    param (
        [Parameter(Mandatory = $true)]
        $Policies
    )
    
    Clear-Host
    Write-Host $banner -ForegroundColor Cyan
    Write-Host $title -ForegroundColor Yellow
    Write-Host "Available Policies:"
    Write-Host
    
    for ($i = 0; $i -lt $Policies.Count; $i++) {
        Write-Host "$($i + 1): $($Policies[$i].DisplayName)"
    }
    
    Write-Host
    Write-Host "A: Export all policies"
    Write-Host "B: Back to main menu"
    Write-Host
    
    do {
        $selection = Read-Host "Please select a policy to export (1-$($Policies.Count), A for All, B for Back)"
        $selection = $selection.ToUpper()
        
        if ($selection -eq 'A' -or $selection -eq 'B') {
            break
        }
        
        $num = 0
        if ([int]::TryParse($selection, [ref]$num)) {
            if ($num -ge 1 -and $num -le $Policies.Count) {
                break
            }
        }
    } until ($false)
    
    return $selection
}

# Function to export policies for import
function Export-CAPolicies {
    param (
        [Parameter(Mandatory = $true)]
        $Policies,
        
        [Parameter(Mandatory = $true)]
        [string]$Selection
    )
    
    try {
        $exportPath = Join-Path $PSScriptRoot "ExportedPolicies"
        if (-not (Test-Path $exportPath)) {
            New-Item -ItemType Directory -Path $exportPath | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        # Determine which policies to export
        $policiesToExport = switch ($Selection) {
            'A' { $Policies }
            'B' { return }
            default {
                $index = [int]$Selection - 1
                @($Policies[$index])
            }
        }
        
        if ($null -eq $policiesToExport) { return }
        
        # Generate export filename
        $filenamePart = if ($Selection -eq 'A') {
            "All_ConditionalAccessPolicies"
        } else {
            $policy = $policiesToExport[0]
            $sanitizedName = $policy.DisplayName -replace '[^\w\-]', '_'
            "ConditionalAccessPolicy_$sanitizedName"
        }
        
        $exportFile = Join-Path $exportPath "$filenamePart`_$timestamp.json"
        
        # Convert policies to exportable format
        $exportPolicies = $policiesToExport | ForEach-Object {
            $policy = $_
            @{
                displayName = $policy.DisplayName
                state = $policy.State
                conditions = $policy.Conditions
                grantControls = $policy.GrantControls
                sessionControls = $policy.SessionControls
            }
        }
        
        $exportPolicies | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportFile -Encoding UTF8
        
        # Verify export was successful
        if (Test-Path $exportFile) {
            Write-Host "`n✅ Export Successful!" -ForegroundColor Green
            Write-Host "📄 Exported policy file: $filenamePart" -ForegroundColor Cyan
            Write-Host "📂 Location: $exportFile" -ForegroundColor Cyan
            return $true
        } else {
            Write-Host "`n❌ Export Failed: File was not created" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "`n❌ Export Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to generate HTML report
function Generate-HTMLReport {
    param (
        [Parameter(Mandatory = $true)]
        $PolicyAnalysis
    )

    $reportPath = Join-Path $PSScriptRoot "ConditionalAccessReport.html"
    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Conditional Access Policy Analysis</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <h1>Conditional Access Policy Analysis</h1>
        <p class="text-muted">Report generated on $reportDate</p>
        
        <div class="table-responsive">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Policy Name</th>
                        <th>State</th>
                        <th>Recommendations</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($analysis in $PolicyAnalysis) {
        $html += @"
                    <tr>
                        <td>$($analysis.Name)</td>
                        <td>$($analysis.State)</td>
                        <td>
                            <ul>
"@
        foreach ($recommendation in $analysis.Recommendations) {
            $html += @"
                                <li>$recommendation</li>
"@
        }
        $html += @"
                            </ul>
                        </td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
"@

    $html | Out-File -FilePath $reportPath -Encoding UTF8
    return $reportPath
}

# Function to prompt for continuation
function Show-ContinuePrompt {
    Write-Host
    do {
        $response = Read-Host "Would you like to perform another operation? (Y/N)"
        $response = $response.ToUpper()
    } until ($response -match '^[YN]$')
    
    return $response -eq 'Y'
}

# Main script execution
try {
    # Connect to Microsoft Graph
    Connect-ToGraph

    # Get and analyze policies
    $policies = Get-AllCAPolicies
    if ($null -ne $policies) {
        do {
            # Determine output format
            if (-not $NoMenu) {
                $selection = Show-Menu
                if ($selection -eq 'Q') { break }
                
                switch ($selection) {
                    '1' { 
                        Show-PoliciesInTerminal -Policies $policies
                    }
                    '2' {
                        $policyAnalysis = $policies | ForEach-Object { Analyze-CAPolicy -Policy $_ }
                        $reportPath = Generate-HTMLReport -PolicyAnalysis $policyAnalysis
                        Write-Host "`nHTML report generated at: $reportPath" -ForegroundColor Green
                        Start-Process $reportPath
                    }
                    '3' {
                        do {
                            $exportSelection = Show-ExportMenu -Policies $policies
                            if ($exportSelection -ne 'B') {
                                $exportSuccess = Export-CAPolicies -Policies $policies -Selection $exportSelection
                                if ($exportSuccess) {
                                    Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                                }
                            }
                        } while ($exportSelection -ne 'B')
                    }
                }
            } else {
                Show-PoliciesInTerminal -Policies $policies
                break
            }

            if ($NoMenu) { break }
        } while (Show-ContinuePrompt)
    }
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
finally {
    Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Cyan
    Disconnect-MgGraph
    Write-Host "Done!" -ForegroundColor Green
}
