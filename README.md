# pi_usb_replicator

A Raspberry Pi tool for replication of bulk USB devices.

* [Installation](#install)
  * [USB Automount](#usb)
  * [Tiny File Manager](#tfm)
* [Usage](#usage)

# Installation <a name="install"></a>

## USB Automount <a name="usb"></a>

Raspberry PI does not have exFAT installed by default. Make sure to install it.

`sudo apt install exfat-fuse exfat-utils`

A simple udev rule will be used to detect when a usb with block storage is plugged in and start a systemd service.

`sudo nano /etc/udev/rules.d/usbstick.rules`

Add the following text to the file and save.

`ACTION=="add", KERNEL=="sd[a-z][0-9]", TAG+="systemd", ENV{SYSTEMD_WANTS}="usbstick-handler@%k%n"`

The systemd service for handling usb detected by our udev rule must be created. To start create the service.

`sudo nano /lib/systemd/system/usbstick-handler@.service`

Add the following text to the file and save.

```
[Unit]
Description=Mount USB sticks
BindsTo=dev-%i.device
After=dev-%i.device
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/automount.sh %I
ExecStop=/usr/local/bin/autoumount.sh %I
```

Now the service has been created you'll need 2 scripts to be run by the service. One script will be used when the USB is plugged in and the other script will be used when the USB is removed. 

First, create the script for when the USB is plugged in.

`sudo nano /usr/local/bin/automount.sh`

Copy the contents of **automount.sh** in the git repository. Make sure the file is flagged for execution.

`sudo chmod +x /usr/local/bin/automount.sh`

Next, create the script for when the USB is removed.

`sudo nano /usr/local/bin/autoumount.sh`

Copy the contents of **autoumount.sh** in the git repository. Make sure the file is flagged for execution.

`sudo chmod +x /usr/local/bin/autoumount.sh`

## Tiny File Manager <a name="tfm"></a>

https://tinyfilemanager.github.io

# Usage <a name="usage"></a>
All USBs are mounted to /media/\<uuid\> of partition. The folders are deleted when the device is removed, to keep things neat.
