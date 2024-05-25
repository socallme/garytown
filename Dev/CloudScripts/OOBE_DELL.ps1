$ScriptName = 'dell.garytown.com'
$ScriptVersion = '24.05.23.01'

#region Initialize

$Manufacturer = (Get-CimInstance -Class:Win32_ComputerSystem).Manufacturer
$Model = (Get-CimInstance -Class:Win32_ComputerSystem).Model
$SystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
if ($Manufacturer -match "Dell"){
    $Manufacturer = "Dell"
    $DellEnterprise = Test-DCUSupport
    if ($DellEnterprise -eq $true) {
        Write-Host -ForegroundColor Green "Dell System Supports Dell Command Update"
        Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/devicesdell.psm1')
    }
    if ($env:SystemDrive -eq 'X:') {
        $WindowsPhase = 'WinPE'
    }
    else {
        $ImageState = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -ErrorAction Ignore).ImageState
        if ($env:UserName -eq 'defaultuser0') {$WindowsPhase = 'OOBE'}
        elseif ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE') {$WindowsPhase = 'Specialize'}
        elseif ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_AUDIT') {$WindowsPhase = 'AuditMode'}
        else {$WindowsPhase = 'Windows'}
    }
    write-output "Running in Windows Phase: $WindowsPhase"
    #region OOBE
    if ($WindowsPhase -eq 'OOBE') {
        Write-Host -ForegroundColor Green "[+] Installing Dell Command Update"
        osdcloud-InstallDCU
        Write-Host -ForegroundColor Green "[+] Running Dell Command Update Drivers"
        osdcloud-RunDCU -UpdateType driver
        Write-Host -ForegroundColor Green "[+] Running Dell Command Update BIOS"
        osdcloud-RunDCU -UpdateType bios
        Write-Host -ForegroundColor Green "[+] Setting Dell Command Update to Auto Update"
        osdcloud-DCUAutoUpdate
    }
    #endregion

    #region Windows
    if ($WindowsPhase -eq 'Windows') {
        #Load OSD and Azure stuff
        Write-Host -ForegroundColor Green "[+] Installing Dell Command Update"
        osdcloud-InstallDCU
        Write-Host -ForegroundColor Green "[+] Running Dell Command Update Drivers"
        osdcloud-RunDCU -UpdateType driver
        Write-Host -ForegroundColor Green "[+] Running Dell Command Update BIOS"
        osdcloud-RunDCU -UpdateType bios
        Write-Host -ForegroundColor Green "[+] Setting Dell Command Update to Auto Update"
        osdcloud-DCUAutoUpdate
    }
    #endregion
}
