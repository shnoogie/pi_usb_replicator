# pi_usb_replicator

A Raspberry Pi tool for replication of bulk USB devices.

* [Installation](#install)
  * [USB Automount](#usb)
  * [Nginx/PHP](#web)
  * [Tiny File Manager](#tfm)
  * [Device Syncing](#sync)
* [Usage](#usage)

## To-Do

- Clean up on boot and reboot ? may not be needed
- Debugging
- Logging
- LED Status

# Installation <a name="install"></a>

Before we start I must make it clear that security has been ignored in this setup and in some cases outright disabled. It is assumed this will only be hosted on a LAN. In some cases you can use a reverse proxy to expose to the internet, but even then there is risk in doing so.

Ensure everything is up to date.

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

`sudo nano /etc/nginx/sites-available/default`

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

Finally set the permissions for your web folder. Which will allow you to read and write as any user.

`sudo chmod -R 777 /var/www/html`

## Tiny File Manager <a name="tfm"></a>

First we'll make a directory we'll need later.

`sudo mkdir -p /var/usb/data`

Ensure you're at your users home directory, we'll use that as our working directory.

`cd ~`

For file managment we'll be using a web app called Tiny File Manager, which can be found at https://tinyfilemanager.github.io.

Download their release to your working directory.

`wget https://github.com/prasathmani/tinyfilemanager/archive/refs/tags/2.4.7.zip`

Now unzip the file that was downloaded.

`unzip 2.4.7.zip`

Then we'll move the contents of the zip to our web directory.

`cp -r tinyfilemanager-2.4.7/* /var/www/html`

Tiny File Manager has been installed. You can check it out by going to **http://\<pi ip\>/tinyfilemanager.php**, however, we still need to configure it.

Change to the web directory.

`cd /var/www/html`

Make Tiny File Manager the index.

`cp tinyfilemanager.php index.php`

Finally we'll need to configure Tiny File Manager. Start by opening the config file.

`nano config.php`

Make sure the config matches the following below. Don't copy and paste, scroll down the config and make changes to match what I have below.

```
$use_auth = false;
$use_highlightjs = false;
$edit_files = false;
$root_path = '/var/usb/data/';
$allowed_upload_extensions = 'gcode';
$online_viewer = false;
$max_upload_size_bytes = 5000000000000;
```

Awesome, we're done installing Tiny File Manager. You can check it out by going to **http://\<pi ip\>/**

## Device Syncing <a name="sync"></a>

Start by downloading the required dependencies.

`sudo apt install inotify-tools`

Next you'll need to add the firewatch script.

`sudo nano /usr/local/bin/filewatch.sh`

Copy the contents of **filewatch.sh** in the git repository. Make sure the file is flagged for execution.

`chmod +x /usr/local/bin/filewatch.sh`

Install the firewatch service.

`sudo nano /etc/systemd/system/filewatch-sync.service`

Copy the following to the script.

```
# /etc/systemd/system/filewatch-sync.service
[Unit]
Description=Filewatch Sync

[Service]
Type=simple
ExecStart=/usr/local/bin/filewatch.sh
Restart=on-failure
RestartSec=1

[Install]
WantedBy=multi-user.target
```

Run the following commands to activate the service.

`sudo systemctl daemon-reload`

`sudo systemctl enable filewatch-sync`

`sudo systemctl start filewatch-sync`

Check to see if the service is running without error.

`sudo systemctl status filewatch-sync`

Next you'll need to install the syncfiles script.

`sudo nano /usr/local/bin/syncfiles.sh`

Copy the contents of **syncfiles.sh** in the git repository. Make sure the file is flagged for execution.

`sudo chmod +x /usr/local/bin/syncfiles.sh`

Time to install syncwatch.sh. This will control the LED which provides feedback of the sync status.

`sudo nano /usr/local/bin/syncwatch.sh`

Copy the contents of **syncwatch.sh** in the git repository. Make sure the file is flagged for execution.

`sudo chmod +x /usr/local/bin/syncwatch.sh`

Install the syncwatch service.

`sudo nano /etc/systemd/system/syncwatch.service`

Copy the following

```
# /etc/systemd/system/syncwatch.service
[Unit]
Description=Syncwatch Sync

[Service]
Type=simple
ExecStart=/usr/local/bin/syncwatch.sh
Restart=on-failure
RestartSec=1

[Install]
WantedBy=multi-user.target
```

Now start the service.

`sudo systemctl daemon-reload`

`sudo systemctl enable syncwatch`

`sudo systemctl start syncwatch`

Ensure the service is in running state.

`sudo systemctl status syncwatch`

Now ensure to plug the positve side of your LED into GPIO pin 4 and negative into ground.

# Usage <a name="usage"></a>
All USBs are mounted to /media/\<uuid\> of partition. The folders are deleted when the device is removed, to keep things neat.

You can add files by visiting the hosted web service. **http://\<pi ip\>

Syncronization is triggered by two events.
 1. Changes in the source directory. (Main Sync)
 2. USB changes. (Targeted Sync)

The first trigger takes presidence over all other running sync jobs. It will kill all other running targeted syncs and run a sync on all connected devices. This is threaded and each devices will run it's own process to prevent overly long sync jobs.

The second trigger is targets a specific device when it's first plugged in.
