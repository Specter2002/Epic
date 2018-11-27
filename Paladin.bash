# !/bin/bash
# Paladin
# Specter2002

x=0

# Ensures that user is using sudo
if [$EUID -ne 0]
then
echo "You must be root to run this script."
exit 1
fi

function menubanner(){
	echo 'Paladin Script by Kyle Lennox'
	echo 'What do you want to do'
		echo '1.) UserMenuBanner'
		echo '2.) Installing'
		echo '3.) Firewall'
		echo '4.) UpdatesAndUpgrades'
		echo '5.) Servers'
		echo '6.) HackerTools'
		echo '7.) MediaFiles'
		echo '8.) Exit'
echo 'Choose an option 1-8:'
}

function UserMenuBanner(){
clear
		echo 'User Management Menu'
		echo '1.) UserManagement'
		echo '2.) Back'
		echo 'Choose an option 1-2:'
}

function Back(){
menubanner
}

function UserManagement(){
    cut -d: -f1,3 /etc/passwd | egrep ':[0-9]{4}$' | cut -d: -f1 | sort 
	echo Type in Username that you want to edit
    read -a users
    usersLength=${#users[@]} 
    for (( i=0;i<$usersLength;i++))
	do
	echo ${users[${@}]}
    done
	echo Delete ${users[${@}]}? yes or no
	read yn1
	if [ $yn1 == "yes" ]
		then
			 deluser ${users[${@}]}
			echo ${users[${@}]} "has been deleted."
		else
			echo Make ${users[${@}]} administrator? yes or no
			read yn2
			if [ $yn2 == yes ]
				then
				gpasswd -a ${users[${@}]} sudo
				echo ${users[${@}]} "has been made an administrator."
			else
				sudo gpasswd -d ${users[${@}]} sudo
				sudo gpasswd -d ${users[${@}]} root
				echo ${users[${@}]} "has been made a standard user."
fi
echo Make custom password -- ${users[${@}]}? yes or no
read yn3
if [ $yn3 == yes ]
	then
		echo Password:
		read pw
		echo -e S3cuR3\nS3cuR3 | passwd ${users[${@}]}
		print time ${users[${@}]} has been given the password S3cuR3.
	else
		echo -e S3cuR3\nS3cuR3 | passwd ${users[${@}]}
		echo ${users[${@}]} "has been given the password S3cuR3."
fi
passwd -x30 -n3 -w7 ${users[${@}]}

# Lock Out Root User
sudo passwd -l root

# Disable Guest Account
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf

# Configure Password Aging Controls
sudo sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS 90' /etc/login.defs
sudo sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS 10' /etc/login.defs
sudo sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE 7' /etc/login.defs

# Password Authentication
sudo sed -i '1 s/^/auth optional pam_tally.so deny=5 unlock_time=900 onerr=fail audit even_deny_root_account silent\n/' /etc/pam.d/common-auth

# Force Strong Passwords
sudo apt-get -y install libpam-cracklib
sudo sed -i '1 s/^/password requisite pam_cracklib.so retry=3 minlen=8 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1\n/' /etc/pam.d/common-password
fi
clear
}

function Installing(){
# Installing auditd

sudo apt-get install -y auditd

# Apparmor

sudo apparmor_status
sudo apt-get install -y apparmor-utils
sudo aa-enforce /etc/apparmor.d/usr.bin.firefox
}

function Firewall(){ 

# Installing UFW and GUFW

sudo apt-get install -y ufw
sudo apt-get install -y gufw

# Enabling Firewall

sudo ufw enable

# Denies Of Bad Programs
sudo ufw deny apache2
sudo ufw deny telnet
sudo ufw deny netbios-ssn
sudo ufw deny netbios-dgm
sudo ufw deny sftp
sudo ufw deny ftpd-data
sudo ufw deny ftps
sudo ufw deny apache
sudo ufw deny smtp
sudo ufw deny ms-sql-s
sudo ufw deny ms-sql-m
sudo ufw deny mysql
sudo ufw deny mysql-proxy

# Denies Ports
ufw deny 21 #FTP
ufw deny 23 #Telnet
ufw deny 25 #SMTP
ufw deny 587 #SMTP
ufw deny 3306 #MySQL

# Removing Bad Programs
sudo apt-get purge -y vsftpd
sudo apt-get purge -y mysql
sudo apt-get purge -y telnet
sudo apt-get purge -y apache
sudo apt-get purge -y apache2
sudo apt-get purge -y smtp
sudo apt-get purge -y tftpd-hpa
sudo apt-get purge -y rsh-server
sudo apt-get purge -y nis
sudo apt-get purge -y telnetd

# Firewall Status
sudo ufw status verbose
}

function UpdatesAndUpgrades(){
# Enable Automatic Updates

sudo dpkg-reconfigure -plow unattended-upgrades

# Update 1

sudo apt-get -y update

# upgrade

sudo apt-get -y upgrade

# update 2

sudo apt-get -y update

# autoclean

sudo apt-get -y autoclean

# autoremove

sudo apt-get -y autoremove

# Updates
sudo apt-get -y upgrade
sudo apt-get -y update
}

function Servers(){
# FTP 
	echo -n "FTP [Y/n] "
	read option
	if [[ $option =~ ^[Yy]$ ]]
	then
		sudo apt-get -y install ftpd
	else
		sudo apt-get -y purge ftpd
fi		
# MySQL
     echo -n "MySQL [Y/n] "
     read option
     if [[ $option =~ ^[Yy]$ ]]
     then
          sudo apt-get -y install mysql-server
          # Disable remote access
          sudo sed -i '/bind-address/ c\bind-address = 127.0.0.1' /etc/mysql/my.cnf
          sudo service mysql restart
     else
          sudo apt-get -y purge mysql*
     fi

# OpenSSH Server
echo -n "OpenSSH Server [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
sudo apt-get -y install openssh-server
# Disable root login
sudo sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
sudo service ssh restart
else
sudo apt-get -y purge openssh-server*
fi

# VSFTPD
echo -n "VSFTP [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
sudo apt-get -y install vsftpd
# Disable anonymous uploads
sudo sed -i '/^anon_upload_enable/ c\anon_upload_enable no' /etc/vsftpd.conf
sudo sed -i '/^anonymous_enable/ c\anonymous_enable=NO' /etc/vsftpd.conf
# FTP user directories use chroot
sudo sed -i '/^chroot_local_user/ c\chroot_local_user=YES' /etc/vsftpd.conf
sudo service vsftpd restart
else
sudo apt-get -y purge vsftpd*
fi
# Removing Samba or SMB/SMBD
apt-get purge samba
}

function HackerTools(){
# Hacker Tools
sudo apt-get -y purge hydra
sudo apt-get -y purge john
sudo apt-get -y purge nikto
sudo apt-get -y purge netcat
sudo apt-get -y purge nmap
sudo apt-get -y purge metasploit
sudo apt-get -y purge wireshark
sudo apt-get -y purge wine
sudo apt-get -y purge grup
sudo apt-get -y purge tftpd-hpa
}

function MediaFiles(){
 # Show media files
     find /home -name '.mp4'
	 find /home -name '.mp3'
	 find /home -name '.png'
	 find /home -name '.jpg'
	 find /home -name '.gif'
	 
# Remove Media Files
while true
do
	echo -n "Enter filepath/name to delete:"
	read answer
	if [$answer eq ""]
		then
		return # break out of loop if no answer
	fi
	rm -f $answer
done
}

function Exit(){
exit
sleep 2
clear
}

# Creates the Menu Banner
while x=0
do 
		clear
		menubanner
		read answer
	
		case "$answer" in
					  1)
					  echo "Going to the UserMenuBanner"
					  clear
					  UserMenuBanner
					  sleep 1
					  ;;
					  2)
					  echo "Starting Installing Phase"
					  clear
					  Installing
					  sleep 1
					  ;;
					  3)
					  echo "Starting Firewall Phase"
					  clear
					  Firewall
					  sleep 1
					  ;;
					  4)
					  echo "Starting UpdatesAndUpgrades Phase"
					  clear
					  UpdatesAndUpgrades
					  sleep 1
					  ;;
					  5)
					  echo "Starting Servers Phase"
					  clear
					  Servers
					  sleep 1
					  ;;
					  6)
					  echo "Starting HackerTools Phase"
					  clear
					  HackerTools
					  sleep 1
					  ;;
					  7)
					  echo "Starting MediaFiles Phase"
					  clear
					  MediaFiles
					  sleep 1
					  ;;
					  8)
					  echo "Exiting"
					  clear
					  Exit
					  x=1
					  sleep 1
					  ;;
esac
# Creates the user menu banner
clear
	UserMenuBanner
	read answer
	case "$answer" in
					1)
					echo "Starting UserManagement Phase"
					clear
					UserManagement
					sleep 1
					;;
					2)
					echo "Going back to the main menu"
					clear
					Back
					sleep 1
					;;
esac
done 
