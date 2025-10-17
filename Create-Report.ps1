param(
    $policyFile = 'policies.txt',
    $outputFolder = '/users/Jaxe/Downloads/testingg'
)
$policies = Get-Content $policyFile
$reportCount = 0
foreach ($file in $policies) {
    $policyName = ($file.split(' # '))[1]
    $policyId = ($file.Split(' # '))[0]
    $reportCount++
    Write-Output "Fetching $($reportCount) of $($policies.count): $($PolicyName)"
    try {
        # 1 - scripts/Get-IntuneDeviceConfigurationStatus.ps1
        $deviceStatusFileName = "$(get-date -format 'yyyy-MM-dd')-$($policyName)-DeviceStatus.csv"
        ./scripts/Get-IntuneDeviceConfigurationStatus.ps1 -policyId $policyId -policyName $policyName -outputFolder $outputFolder -outputFileName $deviceStatusFileName -ErrorAction Stop
        # 2 - scripts/Get-DeviceConfigrationSettingsReport.ps1
        # (skipped for now since finding out we can get userid from step 1)

        #3 - scripts/Get-DeviceConfigrationSettingsReport.ps1
        # load csv information from last
        try {
            $status = Import-Csv (Join-Path $outputFolder $deviceStatusFileName)
            foreach ($device in $status | Where-Object ReportStatus -ne 'Succeeded') {
                $userStatusFileName = "$(get-date -format 'yyyy-MM-dd')-$($device.intuneDeviceId)-$($device.userId).csv"
                ./scripts/Get-ConfigurationSettingNoncomplianceReport.ps1 -policyId $policyId `
                    -policyName $policyName `
                    -outputFolder $outputFolder `
                    -outputFileName $userStatusFileName `
                    -intuneDeviceId $device.intuneDeviceid `
                    -userId $device.UserId  `
                    -ErrorAction Stop
            }
        }
        catch { throw $_ }
    }
    catch {
        throw $_
    }
}
