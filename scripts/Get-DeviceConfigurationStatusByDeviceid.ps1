param(
    $deviceId = '11707913-538d-486e-87ff-cf639248fd0a'
)

$graphSplat = @{
    uri    = 'https://graph.microsoft.com/beta/deviceManagement/reports/getConfigurationPoliciesReportForDevice'
    method = 'POST'
    body   = @{
        select  = @(
            'IntuneDeviceId',
            'PolicyBaseTypeName',
            'PolicyId',
            'PolicyStatus',
            'UPN',
            'UserId',
            'PspdpuLastModifiedTimeUtc',
            'PolicyName',
            'UnifiedPolicyType'
        )
        filter  = "((PolicyBaseTypeName eq 'Microsoft.Management.Services.Api.DeviceConfiguration') or (PolicyBaseTypeName eq 'DeviceManagementConfigurationPolicy') or (PolicyBaseTypeName eq 'DeviceConfigurationAdmxPolicy') or (PolicyBaseTypeName eq 'Microsoft.Management.Services.Api.DeviceManagementIntent')) and (IntuneDeviceId eq '$deviceid')"
        skip    = 0
        top     = 50
        orderBy = @(
            'PolicyName'
        )
    } | ConvertTo-Json -Depth 3
}

$r = Invoke-MgGraphRequest @graphSplat

$rObject = ConvertFrom-Json -InputObject $r
$schema = $rObject.schema

$bag = @()
foreach($obj in $rObject.Values){
    $pso = [pscustomobject]@{}
    for ($i = 0; $i -lt $obj.count; $i++){
        Add-Member -InputObject $pso -MemberType NoteProperty -Name $schema[$i].column -Value $obj[$i] 
    }
    $bag+= $pso
}

<#  status map 
    1 = not applicable
    2 = succeeded
    5 = error
#>