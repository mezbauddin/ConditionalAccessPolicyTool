### README.md for **Entra ID Conditional Access Policy Tool**

# Entra ID Conditional Access Policy Tool

## Overview

The **Entra ID Conditional Access Policy Tool** is a PowerShell script designed to retrieve, analyze, and export Conditional Access Policies from **Microsoft Entra ID**. It provides a comprehensive view of policy configurations, highlights potential improvements, and generates detailed reports for audit and compliance purposes.

## Features

- **Retrieve Policies**: Fetch all Conditional Access Policies from Microsoft Entra ID.
- **Analyze Configurations**: Identify potential gaps or improvements, such as disabled policies or missing exclusions.
- **Interactive Menu**:
  - View policies in the terminal.
  - Export policies to JSON for backup or reuse.
  - Generate an HTML report with recommendations.
- **Export Reports**:
  - Export all policies or selected policies.
  - Create professional HTML reports for audits.

## Requirements

### Modules
Install the required PowerShell modules:
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### Permissions
Ensure the account running the script has the following permissions:
- `Policy.Read.All`
- `Directory.Read.All`
- `Reports.Read.All`

### Environment
- Windows PowerShell or PowerShell Core.
- Connectivity to Microsoft Entra ID (Azure AD).

## How to Use

### Step 1: Connect to Microsoft Graph
Run the script and authenticate when prompted. The script uses `Connect-MgGraph` to establish a session with the required scopes.

### Step 2: Choose an Option
The interactive menu provides the following options:
1. **Display Policies in Terminal**: View a summary of Conditional Access Policies in the console.
2. **Generate HTML Report**: Create a detailed report with policy configurations and recommendations.
3. **Export Policies to JSON**: Save policies in a JSON format for backup or import.

### Example Usage
#### Terminal Display
```plaintext
Conditional Access Policies:

----------------------------------------
Name: Block Legacy Authentication
State: Enabled
Created: 2023-10-15
Modified: 2024-01-10
Include Users: All Users
Exclude Users: BreakGlassAdmin
----------------------------------------
Name: Require MFA for Admins
State: Enabled
Created: 2023-11-01
Modified: 2024-01-05
Include Users: Global Admins
```

#### HTML Report
The script generates a report that includes policy details and recommendations in a professional HTML format.

#### JSON Export
Export all or selected policies to JSON for reuse or archiving.

### Step 3: Review the Output
- **HTML Report**: The report is saved in the script's directory and automatically opens in a browser.
- **JSON Export**: Exported policies are saved in the `ExportedPolicies` folder within the script directory.

## Example Report

### HTML Report
| Policy Name             | State    | Recommendations                                                                 |
|-------------------------|----------|---------------------------------------------------------------------------------|
| Block Legacy Auth       | Enabled  | Consider adding break-glass account exclusions.                                |
| Require MFA for Admins  | Enabled  | Ensure all critical admin accounts are covered.                                |
| Test Policy             | Disabled | Policy is currently disabled - consider enabling or removing if not needed.    |

### JSON Export
```json
[
  {
    "displayName": "Block Legacy Authentication",
    "state": "Enabled",
    "conditions": {
      "users": {
        "includeUsers": ["All"],
        "excludeUsers": ["BreakGlassAdmin"]
      }
    },
    "grantControls": {
      "builtInControls": ["RequireMultiFactorAuthentication"]
    }
  }
]
```

## Common Use Cases

1. **Audit and Compliance**:
   - Review Conditional Access Policies for misconfigurations.
   - Generate reports for compliance audits.
2. **Backup and Restore**:
   - Export policies to JSON for backup or import to another tenant.
3. **Best Practices Validation**:
   - Identify policies with potential misconfigurations or missing exclusions.

## Author

**Mezba Uddin**  
🌐 [Website](https://mezbauddin.com)  
🔗 [LinkedIn](https://linkedin.com/in/mezbauddin)  
📧 contact@mezbauddin.com  

## Version

- **1.0**
- **Last Updated**: 2024-01-18

## License

This project is licensed under the **MIT License**.

## Feedback and Contributions

Your feedback and contributions are welcome! Feel free to submit issues or pull requests via GitHub.

---

### Acknowledgments

This tool leverages the **Microsoft Graph PowerShell SDK** to provide a seamless experience for managing and analyzing Conditional Access Policies.
```

This **README.md** is structured to provide clear instructions, features, examples, and use cases, making it user-friendly for anyone exploring the tool. Let me know if you need further refinements!
