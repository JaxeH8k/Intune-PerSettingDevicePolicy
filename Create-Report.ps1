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
        $deviceStatusFileName = "$(get-date -format 'yyyy-MM-dd')_$($policyName)_DeviceStatus.csv"
        ./scripts/Get-IntuneDeviceConfigurationStatus.ps1 -policyId $policyId `
            -policyName $policyName `
            -outputFolder $outputFolder `
            -outputFileName $deviceStatusFileName `
            -ErrorAction Stop
  
        #3 - scripts/Get-DeviceConfigurationSettingsReport.ps1 / scripts/Get-DeviceConfigurationSettingNoncomplianceReport.ps1
        try {
            # load csv information from last
            $status = Import-Csv (Join-Path $outputFolder $deviceStatusFileName)
            <# API Selector 
            Intune has 2 (at least) api's for showing configuraiton status on an endpoint. 
            By defulault we'll use getConfigurationSettingsReport api
            If we get a zerobyte file in response, we will handle that locally in this foreach by switching
            to the getConfigurationSettingNoncomplianceReport api.

            $apiSelector is set outside of the below foreach scope with intent to only fetch 1 zerobyte file before using the other api.
            Resulting in less API calls.  
            Assuming you have 800 systems to check; you only really need to fail the first api before switching to the other.
            #>
            $apiSelector = 'getConfigurationSettingsReport' # 
            
            foreach ($device in $status | Where-Object ReportStatus -ne 'Succeeded') {
                # filename format to include policy name, device name, users' upn prefix. this will make adding it to the power bi easy based on filepath name.
                $userStatusFileName = "$(get-date -format 'yyyy-MM-dd')_$($policyName)_$($device.DeviceName)_$($device.UPN.Split('@')[0]).csv"
                if ($apiSelector = 'getConfigurationSettingsReport') {
                    ./scripts/Get-ConfigurationSettingsReport.ps1 -policyId $policyId `
                        -policyName $policyName `
                        -outputFolder $outputFolder `
                        -outputFileName $userStatusFileName `
                        -intuneDeviceId $device.intuneDeviceid `
                        -userId $device.UserId  `
                        -ErrorAction Stop
                    # check if response is 0 bytes, if so, switch $apiSelector to the other api and retry on this iteration.
                    if ((Get-ChildItem -Path (Join-Path $outputFolder $userStatusFileName)).Length -eq 0) {
                        $apiSelector = 'getConfigurationSettingNoncomplianceReport'
                        # delete the zero byte file and retry...
                        Remove-Item -Path (Join-Path $outputFolder $userStatusFileName)
                        ./scripts/Get-ConfigurationSettingNoncomplianceReport.ps1 -policyId $policyId `
                            -policyName $policyName `
                            -outputFolder $outputFolder `
                            -outputFileName $userStatusFileName `
                            -intuneDeviceId $device.intuneDeviceid `
                            -userId $device.UserId  `
                            -ErrorAction Stop
                    }
                }
                elseIf ($apiSelector -eq 'getConfigurationSettingNoncomplianceReport') {
                    ./scripts/Get-ConfigurationSettingNoncomplianceReport.ps1 -policyId $policyId `
                        -policyName $policyName `
                        -outputFolder $outputFolder `
                        -outputFileName $userStatusFileName `
                        -intuneDeviceId $device.intuneDeviceid `
                        -userId $device.UserId  `
                        -ErrorAction Stop
                }
                
            }
        }
        catch { throw $_ }
    }
    catch {
        throw $_
    }
}
