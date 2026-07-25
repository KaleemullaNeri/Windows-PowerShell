try {

    $TPM = Get-Tpm

    if (($TPM.TpmPresent -ne $true) -or ($TPM.TpmReady -ne $true)) {
        Write-Output "TPM not ready."
        exit 0
    }

    # Process C Drive
    $CDrive = Get-BitLockerVolume -MountPoint "C:"

    if ($CDrive.ProtectionStatus -ne "On") {

        Write-Output "Encrypting C:"

        Enable-BitLocker `
            -MountPoint "C:" `
            -EncryptionMethod XtsAes256 `
            -UsedSpaceOnly `
            -TpmProtector `
            -SkipHardwareTest
    }
    else {
        Write-Output "C: already encrypted."
    }

    # Process D Drive if available
    if (Test-Path "D:\") {

        $DDrive = Get-BitLockerVolume -MountPoint "D:"

        if ($DDrive.ProtectionStatus -ne "On") {

            Write-Output "Encrypting D:"

            Enable-BitLocker `
                -MountPoint "D:" `
                -EncryptionMethod XtsAes256 `
                -UsedSpaceOnly `
                -RecoveryPasswordProtector `
                -SkipHardwareTest
        }
        else {
            Write-Output "D: already encrypted."
        }
    }
    else {
        Write-Output "D: drive not present."
    }

    exit 0
}
catch {
    Write-Output $_.Exception.Message
    exit 0
}