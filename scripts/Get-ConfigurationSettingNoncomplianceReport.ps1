[cmdletbinding()]
param(
    [parameter(Mandatory = $true)]
    $policyId = '136fe68b-ffcb-4af4-bfb9-e0c5522e9e83',
    [parameter(Mandatory = $true)]
    $policyName,
    [parameter(Mandatory = $true)]
    $outputFolder,
    [parameter(Mandatory=$true)]
    $outputFileName,
    [parameter(Mandatory = $true)]
    $intuneDeviceId = 'c9cc3b19-a386-4961-ad60-283da36d1213',
    [parameter(Mandatory = $true)]
    $userId = '8b7e239e-c017-41f4-a4a7-50f1fa4f5f08'
)

<#
    This requires a UserId ~ Recommend running the Get-DeviceConfigurationStatusByDeviceId.ps1 first to get a list of Policy Names, IDs, Usernames, & UserId's for this script
    use case in my latest effort.  want to build a dashboard of policies & their status's ( I can get that with DeviceConfigurationCompliance report)
    for systems that don't show success on that report, using device ids, call the Get-DeviceConfigurationStatusByDeviceId.ps1 to fetch the users & status's that aren't error/not applicable
    FINALLY for those error/not applicable, execute this report export to get the information on a per-setting, per-device, per-user.

#>
$graphsplat = @{
    uri         = 'https://graph.microsoft.com/beta/deviceManagement/reports/getConfigurationSettingNoncomplianceReport'
    method      = 'POST'
    body        = @{
        select = @(
            "SettingName",
            "SettingStatus",
            "ErrorCode",
            "SettingInstancePath",
            "SettingInstanceId"
        )
        skip   = 0
        top    = 50
        filter = "(PolicyId eq '$policyId') and (DeviceId eq '$intuneDeviceId') and (UserId eq '$userId')"
        #filter = "(PolicyId eq '136fe68b-ffcb-4af4-bfb9-e0c5522e9e83') and (DeviceId eq 'c9cc3b19-a386-4961-ad60-283da36d1213')"
    } | ConvertTo-Json
    ContentType = 'application/json'
    ErrorAction = 'STOP'
}

try {
    $r = Invoke-MgGraphRequest @graphsplat

    $bag = @()
    $schema = $r.schema
    foreach ($obj in $r.Values) {
        $pso = [pscustomobject]@{}
        for ($i = 0; $i -lt $obj.count; $i++) {
            Add-Member -InputObject $pso -MemberType NoteProperty -Name $schema[$i].column -Value $obj[$i] 
        }
        $bag += $pso
    }

    $bag | Export-Csv -Path (Join-Path $outputFolder $outputFileName) -NoTypeInformation
}
catch {
    throw $_
}