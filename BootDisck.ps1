## Extract from : https://p0w3rsh3ll.wordpress.com/2016/10/30/how-to-create-uefi-bootable-usb-media-to-install-windows-server-2016/

$iso_image = 'windows10.iso'

Get-Disk | Where BusType -eq 'USB' | Clear-Disk -RemoveData -Confirm:$true -PassThru

if ((Get-Disk | Where BusType -eq 'USB').PartitionStyle -eq 'RAW') {
    Get-Disk | Where BusType -eq 'USB' | Initialize-Disk -PartitionStyle GPT
} else {
    Get-Disk | Where BusType -eq 'USB' | Set-Disk -PartitionStyle GPT
}

$volume = Get-Disk | Where BusType -eq 'USB' | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem FAT32

if (Test-Path -Path "$($volume.DriveLetter):\") {
    $miso = Mount-DiskImage -ImagePath $iso_image -StorageType ISO -PassThru
    $dl = ($miso | Get-Volume).DriveLetter
}

if (Test-Path -Path "$($dl):\sources\install.wim") {
    & (Get-Command "$($env:systemroot)\system32\robocopy.exe") @(
        "$($dl):\",
        "$($volume.DriveLetter):\"
        ,'/S','/R:0','/Z','/XF','install.wim','/NP'
    )
    & (Get-Command "$($env:systemroot)\system32\dism.exe") @(
        '/split-image',
        "/imagefile:$($dl):\sources\install.wim",
        "/SWMFile:$($volume.DriveLetter):\sources\install.swm",
        '/FileSize:4096'
    )
}

(New-Object -comObject Shell.Application).NameSpace(17).ParseName("$($volume.DriveLetter):").InvokeVerb('Eject')

Dismount-DiskImage -ImagePath $iso_image
