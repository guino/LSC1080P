## LSC 1080P Indoor Camera root and customization

### TL;DR

You can jump to the **Conclusion** section all the way at the bottom if you just want to the steps to root the camera (and don't care about the details on how we got to them).

#### Summary

I created this repo to catalog information related to the LSC 1080P indoor camera since it cannot be rooted with information from my previous projects as it has different bootloader and rootfs. The firmware version is 7.6.32 at the time of writing this.

#### Hardware

This is what the device looks like (Other brand devices may look similar with the same hardware/software in them):
![LSC1080P](https://camo.githubusercontent.com/31a795202fd64f16ef4a880a7d721f8527bb8e645da4ef442168fe2a0f2fe03b/68747470733a2f2f616374696f6e2e636f6d2f686f737465646173736574732f434d5341727469636c65496d616765732f37322f39362f333230303031395f383731323837393135353036352d3131315f30312e706e67)

#### Initial work and Credits

I have to give credit to [OfficialDevvCat](https://github.com/OfficialDevvCat) for obtaining the firmware dump from the device and for finding out the telnet password -- one of many listed [here](https://github.com/mstanislav/phd-dissertation/blob/main/Camera%20Credentials.md). Most of my original findings were done with that information.

#### Root access

After review of the main application on the device we found that we can enable telnet by creating a file called 'product.cof' in the SD card with the following contents:
```
[DEFAULT_SETTING]
telnet=1
```
Then just boot the device with the SD card inserted and port 23 (telnet) should be open. 
The root login is `root` with password: `dgiot010`

#### Customization

I did not find any file, script or setting that we could adjust in the device to automatically startup a custom script, so most of the customization relies on running the start script from an outside machine (which you can do on a scheduled basis). Basically the script checks if port 8080 (busybox http) is closed in which case it logs in and executes the start script (see `initcheck.sh` in the repository).

Since RTSP is available out of the box, the only customizations done to this device are:
* Added motion notification support (MQTT/etc)
* Added download feature (download video files remotely)
* Added upload feature (upload files to SD card remotely)
* Added customized clean up of files in SD card

There's no 'fixed buffer' for JPEG images on this device, so there's no easy way to make mjped/snap functions as we have on other devices. If you're looking for that, you can check [this repository](https://github.com/guino/rtsp2jpeg) to obtain similar features from the RTSP stream.

#### Review

This is a quick review of pros and cons of this device:

##### Pros
* Recordings are in standard .mp4 file format
* RTSP is enabled by default (no changes needed) on rtsp://IP:8554/main and rtsp://IP:8554/sub -- both also available on port 80
* Easy way to enable telnet with known credentials (no changes needed)

##### Cons
* No RTSP Audio (Reported by user, I did not personally check it before my device died)
* No way to disable RTSP (potential security risk, though most users will see this as a benefit)
* No way to run startup script from SD card automatically without modifying flash firmware
* No current method for 'snapshot' (snap.cgi/mjpeg.cgi) -- look at rtsp2jpeg repo for as an alternative

#### Conclusion 

If you want any of the features listed in the 'Customization' (Motion notfication, download/upload, cleanup) that can be done in one of 3 ways:

##### Option 1

Run a script from a computer to detect if our tools are running on the device (over the network using telnet connection), if not, the script will connect by telnet and run our tools from the SD card.

The setup is simple:
1. Download the repository files (from the Code->Download ZIP button above) or clone it with git.
2. Extract the zip on a computer and copy the contents of the `mmc` directory into the SD card (it should have been FAT32 formatted).
3. SEPARATELY download busybox from this link to the SD card: https://github.com/guino/LSC1080P/blob/main/mmc/busybox?raw=true
4. On the SD card, adjust the log_parser.sh file to your needs (if using motion detection), and adjust cleanup.cgi to your needs.
5. On a computer of your choice, run the `initcheck.sh` script to start the tools on the device. This script will need to be executed every time the device is rebooted, so you could run it on a schedule to ensure the device is always running the tools.

NOTE: I have not made a windows version of the initcheck.sh script but it should be possible to make a similar script.

##### Option 2 (Still unverified -- my device got bricked before I could test this)

Modify the flash to run a script in the SD card when the device starts up without a need for anything to be running/monitoring the device from a separate machine.
There are risks involved with this approach and you should consider that custominzation usually involves integration with another machine -- that machine could be easily setup with option 1 that requires no changes in the flash, so that is what I recommend.

If you want to use Option 2 (modifying the flash) you should start by making sure everything is working with Option 1 first.

You will need:
* a linux machine with binwalk and mksquashfs
* a heat gun to remove and re-solder the flash chip back
* a hardware flash programmer such as CH341a

NOTE: If you are not familiar with the above tools I strongly discourage you to proceed with option 2.

Get a copy of your root partition:
* Login by telnet and execute `/mnt/busybox dd if=/dev/mtd4 of=/mnt/root bs=1024`
* Flush disk cash by executing: `sync`
* Unplug device and remove SD card
* On the computer run binwalk to extract the root partition: `binwalk -e root`
* Edit the startup script under _root.extracted/squashfs_root/usr/init/app_init.sh, modify the last lines of the file from this (make sure to use a linux compatible text editor):
```
if [ "$1" == "0" ];then
        echo "stop"
else
        echo "start"
        cd /usr/bin
        ./daemon&
        ./dgiot&
fi
```
To this:
```
mount /dev/mmcblk0p1 /mnt
/mnt/hack.sh
[ $? -eq 0 ] && exit 0
cd /usr/bin
./daemon&
./dgiot&
```
* Build a modified squashfs file by executing this command inside the _root.extracted directory: 
```
mksquashfs squashfs-root/ newroot -comp xz
```
* Using a heat gun remove the flash chip
* Dump the firmware using the hardware programmer. The chip on this device is not very known and flashrom (linux) failed to recognize it -- NeoProgrammer for Windows seemed to find it but under a different chip name, in the end I was able to read/write it with the XMC->XM25QH64A chip selected.
* Identify the address of the rootfs with `binwalk flash.bin`, it will look like this (find the Squashfs filesystem):
```
2490368       0x260000        Squashfs filesystem, little endian, version 4.0, compression:xz, size: 4671622 bytes, 222 inodes, blocksize: 131072 bytes, created: 2022-04-27 11:38:29
```
* Use this command to copy the new root into the flash file (make sure you make a backup first):
```
dd if=newroot of=flash.bin conv=notrunc bs=1 seek=2490368
```
NOTE: the seek= parameter should be the first number listed in binwalk for the Squashfs line.
* Write the modified flash.bin to the chip -- make sure to VERIFY it during the write (had I done that my device could still be working since I believe I damaged my board after successfully removing and soldering the chip back once, but my flash was corrupt because I didn't verify it).
* Solder the chip back with the heatgun

The device should automatically run the tools when booting up (no need for running a script from another machine).

##### Option 3 (Bricked my device trying to do it)

I was able to write some data to the flash chip in telnet, so I was hoping to flash changes in the same way, HOEWEVER, when attempting to apply the changes to my device I noticed the new root was not correctly written to the flash (corrupted data).
In my attempts to correctly write the new root or restore the orinal one, the device froze up (probably watchdog reset due to long calls during flash write) and it would no longer boot due to the corrupt root fs in the flash (bricked).

I then ordered a decent heat gun and removed the flash chip to fix with my programmer but I believe I damaged something else in the multiple attempts to get the flash corrected. I originally thought that disconnecting pin 6 of the chip was NOT enough to use the programmer on this device, but this may have worked had I know the flash chip was just not being recognized by linux flash rom (I thought it wasn't recognizing it because it was still soldered onto the board).

Since my device no longer works (despite the flash being correct and being recognized by the board), I have no way of trying to make this option work. I can tell my device recognizes the flash because it shows different errors with and without the flash chip in it, I know the data is correct because I verified it, but it isn't even getting to the point of trying to load the kernel anymore -- just fails after an 'initializing DDR mesage' with an error 216.

#### Serial Access Note

One thing to mention about this device: It is NOT worth trying to solder wires to get UART access to this device -- the bootloader has a zero delay setting that doesn't allow us to interact with it. The only benefit from having the serial port is to see the device boot messages (uboot/kernel).

It may be possible to adjust the boot delay setting in telnet (flash write command) and then use the bootloader by connecting to the serial port. I already have wires in place so I'll try it when/if my device is back in operation.
