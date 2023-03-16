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

### Installation tips foe Windows 11

As your know Microsoft tries to force us to use a modern hardware and microsoft account to. To walkaround it please follow this links for instructions:

* [How to Bypass Windows 11's TPM, CPU and RAM Requirements](https://www.tomshardware.com/how-to/bypass-windows-11-tpm-requirement)
* [How to bypass the Microsoft Account requirement during Windows setup](https://www.ghacks.net/2023/01/26/how-to-bypass-the-microsoft-account-requirement-during-windows-setup/)