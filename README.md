<h1>Check SCIM Failure Notification Emails on Enterprise Apps</h1>

<h2>What it does</h2>

<p>This script is for auditing automatic user provisioning (SCIM) on your enterprise apps. It finds every app in your tenant that has a provisioning job, shows who owns it and whether the job is running, and reports whether failure notification emails are set up. The results are saved to a CSV.</p>

<h2>How it works</h2>

<ol>
  <li>Signs into Microsoft Graph with <code>Connect-MgGraph</code>, asking for <code>Application.Read.All</code> and <code>Directory.Read.All</code>. Nothing in your tenant is changed.</li>
  <li>Creates an empty <code>$results</code> list and pulls every service principal in the tenant with <code>Get-MgServicePrincipal -All</code>.</li>
  <li>Loops through each service principal and asks Graph for its provisioning (synchronization) jobs:
    <ul>
      <li>If the app has no jobs, or the call errors, it is silently skipped. Most apps don't support provisioning, so most of the tenant gets skipped this way.</li>
    </ul>
  </li>
  <li>For apps that do have jobs, looks up the owners and builds one string of their display names, de-duplicated and separated by <code>;</code>. If the owner lookup fails, the owners column is left blank.</li>
  <li>For each provisioning job on the app, adds one row to the results with:
    <ul>
      <li><code>EnterpriseAppName</code> (display name)</li>
      <li><code>AppId</code></li>
      <li><code>Owners</code></li>
      <li><code>ProvisioningStatus</code> (the job's schedule state, such as Active, Paused or Disabled)</li>
      <li><code>FailureEmailsConfigured</code> (<code>Yes</code> if any notification address was found, otherwise <code>No</code>)</li>
      <li><code>FailureNotificationEmails</code> (the addresses, separated by <code>;</code>)</li>
    </ul>
  </li>
  <li>Sorts the results by app name and saves them to <code>EnterpriseAppProvisioningAudit.csv</code> in whatever folder you ran the script from.</li>
  <li>Prints a message saying where the report was saved.</li>
</ol>

<h2>Prerequisites</h2>

<ul>
  <li>The Microsoft Graph PowerShell SDK, including the <code>Microsoft.Graph.Applications</code> module</li>
  <li>An account that can use <code>Application.Read.All</code> and <code>Directory.Read.All</code> and has a directory role that can read provisioning configuration</li>
</ul>

<h2>Notes / Limitations</h2>

<ul>
  <li><b>Check the email column before trusting it.</b> The script reads the addresses from the job's schedule, but as far as I know Graph stores provisioning notification settings separately (in the synchronization secrets), not on the schedule. If so, every row will show <code>No</code> and the email column will be empty. Test it against an app you know has notifications set.</li>
  <li><b>Permissions may be too narrow.</b> Reading provisioning jobs normally needs a synchronization-specific scope such as <code>Synchronization.Read.All</code>, which this script doesn't request. Because every error is silently swallowed, the result could be an empty or near-empty CSV with no warning. If that happens, add that scope to <code>Connect-MgGraph</code>.</li>
  <li>The blanket <code>catch { continue }</code> hides all errors, so you can't tell the difference between "this app has no provisioning" and "the call failed".</li>
  <li><code>ProvisioningStatus</code> is the job's schedule state only. It doesn't tell you whether recent runs have succeeded or failed.</li>
  <li>An app with several provisioning jobs gets one row per job, so the same app can appear more than once.</li>
  <li>Owners are shown as display names, not UPNs, so they're harder to match to accounts. Apps with no owners have a blank owners cell, which is worth reviewing.</li>
  <li>It makes at least one Graph call per service principal, so it can be slow, and may start throttling, in a large tenant.</li>
  <li>The CSV export doesn't set encoding. PowerShell 7 defaults to UTF-8, but Windows PowerShell 5.1 may mangle special characters in app names.</li>
  <li>Unlike the other scripts, it doesn't print a table or a count of apps found.</li>
</ul>
