Connect-MgGraph -Scopes `
    "Application.Read.All",
    "Directory.Read.All"

$results = @()

$servicePrincipals = Get-MgServicePrincipal -All

foreach ($sp in $servicePrincipals) {

    try {
        # Get provisioning jobs for the Enterprise App
        $jobs = Get-MgServicePrincipalSynchronizationJob `
            -ServicePrincipalId $sp.Id `
            -ErrorAction Stop

        if (-not $jobs) {
            continue
        }

        # Get owners
        try {
            $owners = Get-MgServicePrincipalOwner `
                -ServicePrincipalId $sp.Id `
                -All

            $ownerString = ($owners |
                ForEach-Object {
                    $_.AdditionalProperties.displayName
                } |
                Sort-Object -Unique) -join "; "
        }
        catch {
            $ownerString = ""
        }

        foreach ($job in $jobs) {

            $emails = $job.Schedule.NotificationEmailAddresses

            $results += [PSCustomObject]@{
                EnterpriseAppName     = $sp.DisplayName
                AppId                 = $sp.AppId
                Owners                = $ownerString
                ProvisioningStatus    = $job.Schedule.State
                FailureEmailsConfigured = if ($emails.Count -gt 0) { "Yes" } else { "No" }
                FailureNotificationEmails = $emails -join "; "
            }
        }
    }
    catch {
        continue
    }
}

$results |
    Sort-Object EnterpriseAppName |
    Export-Csv ".\EnterpriseAppProvisioningAudit.csv" -NoTypeInformation

Write-Host "Report exported to EnterpriseAppProvisioningAudit.csv"