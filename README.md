# pi_usb_replicator

A Raspberry Pi tool for replication of bulk USB devices.

* [Installation](#install)
  * [USB Automount](#usb)
  * [Nginx/PHP](#web)
  * [Tiny File Manager](#tfm)
  * [Device Syncing](#sync)
* [Usage](#usage)

# Installation <a name="install"></a>

Before you start ensure everything is up to date.

`sudo apt update`

`sudo apt upgrade`

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

## Nginx/PHP <a name="web"></a>

Files will be managed over the web, to do so you'll need to install nginx and php which is a web server and scripting languge.

We'll start with nginx.

`sudo apt install nginx`

Once it's finished check that's it's running by going to **http://\<pi ip\>**

Next we'll install PHP which will have a few more steps.

`sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg`

`sudo sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'`

`sudo apt update`

`sudo apt install php8.1-common php8.1-fpm`

Now you'll need to update nginx configuration to use php.

Make the following edits:

Under the following line

```
listen [::]:80 default_server;
```

Add the following line:

```
client_max_body_size 500M;
```

Change the line (or similar line):

```
index index.html index.htm index.nginx-debian.html;
```

to

```
index index.php index.html index.htm index.nginx-debian.html;
```

Uncomment the follow lines (remove the #):

```
location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
}
```

and

```
location ~ /\.ht {
        deny all;
}
```

Now need to make some changes to php.ini

`sudo nano /etc/php/8.1/fpm/php.ini`

Find the line **'upload_max_filesize'** and change it's value to 500M

Find the line **'post_max_size'** and change it's value to 0

Now restart nginx and php.

`sudo systemctl restart nginx`

`sudo systemctl restart php8.1-fpm`

## Tiny File Manager <a name="tfm"></a>

https://tinyfilemanager.github.io

## Device Syncing <a name="sync"></a>

sudo apt install inotify-tools

# Usage <a name="usage"></a>
All USBs are mounted to /media/\<uuid\> of partition. The folders are deleted when the device is removed, to keep things neat.
