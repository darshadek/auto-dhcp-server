#!/bin/bash
# dhcp-setup.sh

if [ "$EUID" -ne 0 ]; then
       echo "Run the file from root"
       exit 1
fi

echo "Install the server..."
apt update && apt install -y isc-dhcp-server || { echo "Installation failed!"; exit 1; }

echo "Please enter your network interface. You can view it using the 'ip a' command"
if [ -f /etc/dhcp/dhcpd.conf ]; then
    echo "Warning: /etc/dhcp/dhcpd.conf already exists, overwriting it."
fi
read INTERFACE
if ! ip a | grep -q "$INTERFACE"; then
    echo "Error: Interface $INTERFACE not found!"
    exit 1
fi
if [ "$INTERFACE" == "enp0s3" ]; then
	sed -i "s/^INTERFACEv4=.*/INTERFACEv4=\"$INTERFACE\"/" /etc/default/isc-dhcp-server
	cat > /etc/dhcp/dhcpd.conf <<EOF
	subnet 10.0.2.0 netmask 255.255.255.0 {
   	range 10.0.2.100 10.0.2.200;
  	option routers 10.0.2.1;
  	option domain-name-servers 8.8.8.8, 8.8.4.4;
        default-lease-time 600;
  	max-lease-time 7200;
}
EOF
else
	sed -i "s/^INTERFACEv4=.*/INTERFACEv4=\"$INTERFACE\"/" /etc/default/isc-dhcp-server
	cat > /etc/dhcp/dhcpd.conf <<EOF
	option domain-name "serv";
	option domain-name-servers 8.8.8.8, 8.8.4.4;
	subnet 192.168.100.0 netmask 255.255.255.0 {
	    range 192.168.100.100 192.168.100.200;
   	 option routers 192.168.100.1;
   	 option domain-name-servers 8.8.8.8, 8.8.4.4;
  	  default-lease-time 600;
  	  max-lease-time 7200;
}
EOF
fi
echo "The configuration file has been created"

systemctl restart isc-dhcp-server
echo "Want to see the server status? Tell me, y or n?"
read answer
if [ "$answer" == "y" ]; then
	systemctl status isc-dhcp-server
	echo "Do you want to listen on port 67? Tell me, y or n? "
	read ans
	if [ "$ans" == "y" ]; then
		ss -lunp | grep 67
	else
		echo "ok"
	fi
else
	echo "ok..."
	echo "Do you want to listen on port 67? Tell me, y or n? "
	read ans
	if [ "$ans" == "y" ]; then
		ss -lunp | grep 67
	else
		echo "ok"
	fi

fi
echo "Done! If everything went well, the server is configured and running!"
