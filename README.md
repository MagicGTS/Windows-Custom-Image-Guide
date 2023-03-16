# the Sysprep & NLite image preparation

## Content

There is pretty short instruction with examples howto prepare a custom windows image for further distribution.

## Concept

Generally all process looks like just install regular Windows image of selected edition and after install any necessary software and adjust any setting you like.
After this pretty straight part you must prepare this Windows instance to sealing and mastering with sysprep, dism and NLite.

## General part - Virtual Machine

For made all thing easy, it is recomended to do all next steps inside virtual Machine (VM). Using VM can simplify many other steps including create differents sets of software or tweaks for different targets of usage.

One of simple for usage VM Software is [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads). For extanding avaible feachures also recomended install [Oracle VM VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads)

### Create new VM

To create VM we just need to hit New button as it shown on the image below:

![New VM](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-01.png "New VM")

Switching to Expert Mode by hitting the Expert Mode button:

![Expert Mode](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-02-Expert.png "Expert Mode")

Setting VM Name, installation media, OS Type and OS Version

![Name](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-03-Name.png "Name")

Adjust Hardware options: For Windows 11 you must set 4Gb of RAM and enable EFI, also set at least two CPU Core

![Hardware](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-04-Hardware.png "Hardware")

Setting HDD, if you using Windows as your VM Host OS I have recommend to you choose VHD disk format as it can be mounted directly to host OS for further steps. Adjust size of VM HDD according your expectation of size of target software set.

![HDD](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-05-HDD.png "HDD")

Also for further usage we need to adjust addition setting inside VM. Select newly created VM and hit Setting button:

![Setting](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-06-Adjusting.png "Setting")

Inside System Tab on left part of setting screen, adjust boot order as it shown on image below, select ICH9 chipset, enable TPM 2.0 and secure boot

![System](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-07-System.png "System")

Inside Storage Tab on left part of setting screen, adjust SATA controller cache function, that is significantly encrease VM perfomance but can leed File System curruption inside VM if VM would be accidentally reset.

![Cache](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-08-Storage-1.png "Cache")

If you placed VM HDD file on SSD disk it would be better mention for VM System about it by checking Solid-state drive checkbox, this changing VM behavior to properly utilize that fact.

![SSD](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-08-Storage-2.png "SSD")

If your forget or changing your mind about installation media you can select proper one on the virtual DVD drive setting panel

![DVD](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-08-Storage-3.png "DVD")

Usually you don't need audio functions inside VM, that why it is disabled on the next image:

![Audio](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-09-Audio.png "Audio")

For better performance it is good to be adjusting some network options, on the next screen we chose paravirtualized adapter which work faster than emulated one

![Network](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-10-Network-1.png "Network")

By default VM working behind the NAT of VM Software does. But we can choose bridge mode and bring VM directly to LAN

![Network](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/1.New-VM-10-Network-2.png "Network")

Now we can just start your VM and proceed installation process as it happens with real PC.

### Installation tips for Windows 11

As your know Microsoft tries to force us to use a modern hardware and microsoft account to. To walkaround it please follow this links for instructions:

* [How to Bypass Windows 11's TPM, CPU and RAM Requirements](https://www.tomshardware.com/how-to/bypass-windows-11-tpm-requirement)
* [How to bypass the Microsoft Account requirement during Windows setup](https://www.ghacks.net/2023/01/26/how-to-bypass-the-microsoft-account-requirement-during-windows-setup/)

## Sysprep the image

After you have done with installation software inside virtual machine, customize windows appearance chosing default apps for file extention and so on, it is time to making snapshot of current state, before we can going to the next statge.

### Export Start Menu Layout

To export and save for future use Start menu layout you should issue Powershell command:
```
Export-StartLayout -Path "C:\LayoutModification.json"
```

This file will need on the one of next steps

### Exporting default apps for file extensions

To export and save for future use defaults apps for file extensions you should issue Powershell command:
```
dism /Online /Export-DefaultAppAssociations:"C:\AppAssociations.xml"
```

### Copying the reference user profile

You should have a preconfigured user profile which you want to use in your custom windows image as default one. To do so just configure all things you want to have as default in new system

### Sysprep first stage

The content of unattend.xml is:
```
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <CopyProfile>true</CopyProfile>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <CopyProfile>true</CopyProfile>
        </component>
    </settings>
</unattend>
```

To prepare image for further usage issue command through run menu or command line:
```
c:\Windows\System32\Sysprep\sysprep.exe /unattend:c:\unattend.xml
```
You will see the menu like on the image below:

![Sysprep-1](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/2.Systprep-1.PNG "syprep-1")

After sysprep finished its first step you fall into audit mode where you can remove unnecessary user accounts from system and doing final steps before allow sysprep to sealled up your custom image.

Finilize image with command from the next screen:

![Sysprep-2](https://github.com/MagicGTS/Windows-Custom-Image-Guide/blob/main/img/2.Systprep-2.PNG "syprep-2")

### Apply Start Menu Layout and Default Apps for file extensions

When VM went to Off state, you can mount VM hard drive from the disk manager mmc menu.
At this point you shuld issue two command:
```
Dism.exe /Image:F:\ /Import-DefaultAppAssociations:F:\AppAssociations.xml
Import-StartLayout -LayoutPath "F:\LayoutModification.json" -MountPath "F:\"
```

### Capturing image with DISM

When you have done with offline image adjustment, like remove unnecessary files and so on, just issue command:
```
DISM.exe /Capture-Image /ImageFile:D:\install.wim /CaptureDir:F:\ /Name:"Custom Windows fo Office"
```

At this stage you can doing anything adjustments with NLite

### Compile ISO Image

Before begin you should extract all content of original ISO image except install.* file from "source" folder.
After that place preveusly created wim file inside "source" folder, change current dir to: C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
and issue command:
```
oscdimg.exe -bootdata:2#p0,e,bEtfsboot.com#pEF,e,bEfisys.bin -u1 -udfver102 -lCustomWindows D:\ISO\CustomImage D:\ISO\CustomImage.iso
```