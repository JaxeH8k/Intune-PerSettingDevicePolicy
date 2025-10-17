[cmdletbinding()]
param(
    [parameter(Mandatory = $true)]
    $policyName,
    [parameter(Mandatory = $true)]
    $policyId,
    [parameter(Mandatory = $true)]
    $outputFolder,
    [parameter(Mandatory=$true)]
    $outputFileName,
    $deleteZip = $true
)

if (! (Test-Path $outputFolder)) {
    try {
        New-Item $outputFolder -ItemType Directory -ErrorAction Stop
    } 
    catch {
        Write-Output "$_"
        Write-Output "Failed to create director $($outputFolder) ... Param should be a folder path. Exit 1"
        Exit 1
    }
}

# test path is writeable // basic touch test, exit if fail
try {
    New-Item -Name 'TestFile.txt' -Path $outputFolder -ErrorAction Stop | out-null
    Remove-Item (join-path $outputFolder 'TestFile.txt')
}
catch {
    Write-Output "$_"
    Write-Output "Failed to write test file at location.  Exit 1"
    Exit 1
}

$graphSplat = @{
    URI         = 'https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs'
    Method      = 'POST'
    Body        = @{
        reportName = "DeviceStatusesByConfigurationProfile"
        filter     = "((PolicyBaseTypeName eq 'Microsoft.Management.Services.Api.DeviceConfiguration') or (PolicyBaseTypeName eq 'DeviceManagementConfigurationPolicy') or (PolicyBaseTypeName eq 'DeviceConfigurationAdmxPolicy')) and (PolicyId eq '$policyId')"
        select     = @(
            "DeviceName",
            'IntuneDeviceId',
            "UPN",
            'UserId'
            "ReportStatus",
            "AssignmentFilterIds",
            "PspdpuLastModifiedTimeUtc"
        )
        format     = 'csv'
        snapshotId = ''
    } | ConvertTo-Json -Depth 4
    ErrorAction = "STOP"
}

try {
    $req = Invoke-MgGraphRequest @graphSplat 
    Write-Output "Requestion Made Succesfully... proceed to query and wait for report to become available."
}
catch {
    Write-Output "Graph Request No Bueno!"
    throw "$_"
}

Start-Sleep 15
$graphSplat = @{ 
    uri    = "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('$($req.id)')"
    method = 'GET'
}
$reqStatus = Invoke-MgGraphRequest @graphSplat

while ( $reqStatus.status -ne 'completed') {
    Start-Sleep 30
    Write-Output 'Checking report status...'
    $reqStatus = Invoke-MgGraphRequest @graphSplat
}

Write-Output 'Report generation complete and ready for download'

$graphSplat = @{
    method         = 'get'
    uri            = $reqStatus.url
    outputFilePath = (join-path $outputFolder "$policyId.zip")
    ErrorAction    = 'STOP'
    ProgressAction = "SilentlyContinue"
}

try { 
    Invoke-MgGraphRequest @graphSplat
    # unpack zip file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($graphSplat.outputFilePath)
    $compressedFileName = $zip.Entries[0].Name
    Expand-Archive -Path $graphSplat.outputFilePath -DestinationPath $outputFolder
    Rename-Item (Join-Path $outputFolder $compressedFileName) $outputFileName
    if ($deleteZip) {
        Remove-Item $graphSplat.outputFilePath
    }
}
catch {
    throw $_
}