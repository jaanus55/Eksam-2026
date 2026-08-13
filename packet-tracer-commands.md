R1

R1#show running-config

Building configuration...



Current configuration : 2226 bytes

!

version 15.1

no service timestamps log datetime msec

no service timestamps debug datetime msec

service password-encryption

!

hostname R1

!

!

!

enable secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

ip dhcp excluded-address 192.168.10.1 192.168.10.20

ip dhcp excluded-address 192.168.20.1 192.168.20.20

ip dhcp excluded-address 192.168.5.101 192.168.5.126

ip dhcp excluded-address 192.168.6.101 192.168.6.126

ip dhcp excluded-address 192.168.5.1 192.168.5.10

ip dhcp excluded-address 192.168.6.1 192.168.6.10

!

ip dhcp pool LEFT-LAN

 network 192.168.10.0 255.255.255.0

 default-router 192.168.10.1

 dns-server 8.8.8.8

ip dhcp pool RIGHT-LAN

 network 192.168.20.0 255.255.255.0

 default-router 192.168.20.1

 dns-server 8.8.8.8

ip dhcp pool LAN

 network 192.168.5.0 255.255.255.128

 default-router 192.168.5.1

 dns-server 1.1.1.1

 domain-name too.net

ip dhcp pool LAN1

 network 192.168.6.0 255.255.255.128

 default-router 192.168.6.1

 dns-server 1.1.1.1

 domain-name too.net

!

!

!

no ip cef

no ipv6 cef

!

!

!

username admin privilege 15 secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

license udi pid CISCO1941/K9 sn FTX15241G93-

!

!

!

!

!

!

!

!

!

!

!

ip ssh version 2

no ip domain-lookup

ip domain-name too.net

!

!

spanning-tree mode pvst

!

!

!

!

!

!

interface Tunnel0

 ip address 172.16.12.1 255.255.255.252

 mtu 1476

 tunnel destination 10.0.23.2

!

!

interface Tunnel1

 ip address 10.0.0.2 255.255.255.252

 mtu 1476

 tunnel source Serial0/1/0

 tunnel destination 194.25.10.42

!

!

interface GigabitEthernet0/0

 description LAN-192.168.5.0

 ip address 192.168.5.1 255.255.255.128

 duplex auto

 speed auto

!

interface GigabitEthernet0/1

 ip address 192.168.10.1 255.255.255.0

 duplex auto

 speed auto

!

interface Serial0/1/0

 description UHENDUS-R3

 ip address 201.10.23.1 255.255.255.252

!

interface Serial0/1/1

 no ip address

 clock rate 2000000

!

interface Vlan1

 no ip address

 shutdown

!

ip classless

ip route 10.0.23.2 255.255.255.255 10.0.13.2 

ip route 0.0.0.0 0.0.0.0 201.10.23.2 

ip route 192.168.6.0 255.255.255.128 10.0.0.1 

!

ip flow-export version 9

!

!

!

banner motd ^Autoriseerimata sisselogimine on keelatud!







^C

!

!

!

!

line con 0

 login local

!

line aux 0

!

line vty 0 4

 login local

 transport input ssh

!

!

!

end



R2


R2#enable

R2#show running-config

Building configuration...



Current configuration : 1592 bytes

!

version 15.1

no service timestamps log datetime msec

no service timestamps debug datetime msec

service password-encryption

!

hostname R2

!

!

!

enable secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

!

!

!

!

ip cef

no ipv6 cef

!

!

!

username admin privilege 15 secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

license udi pid CISCO1941/K9 sn FTX1524Q99S-

!

!

!

!

!

!

!

!

!

!

!

ip ssh version 2

no ip domain-lookup

ip domain-name too.net

!

!

spanning-tree mode pvst

!

!

!

!

!

!

interface Tunnel0

 ip address 172.16.12.2 255.255.255.252

 mtu 1476

 tunnel source GigabitEthernet0/0

 tunnel destination 10.0.13.1

!

!

interface Tunnel1

 ip address 10.0.0.1 255.255.255.252

 mtu 1476

 tunnel source Serial0/1/1

 tunnel destination 201.10.23.1

!

!

interface GigabitEthernet0/0

 description LAN1-192.168.6.0

 ip address 192.168.6.1 255.255.255.128

 ip helper-address 10.0.0.2

 duplex auto

 speed auto

!

interface GigabitEthernet0/1

 ip address 192.168.20.1 255.255.255.0

 ip helper-address 172.16.12.1

 duplex auto

 speed auto

!

interface Serial0/1/0

 no ip address

 clock rate 2000000

!

interface Serial0/1/1

 description UHENDUS-R3

 ip address 194.25.10.42 255.255.255.252

!

interface Vlan1

 no ip address

 shutdown

!

ip classless

ip route 10.0.13.1 255.255.255.255 10.0.23.1 

ip route 192.168.10.0 255.255.255.0 172.16.12.1 

ip route 0.0.0.0 0.0.0.0 194.25.10.41 

ip route 192.168.5.0 255.255.255.128 10.0.0.2 

!

ip flow-export version 9

!

!

!

banner motd ^Autoriseerimata sisselogimine on keelatud!

^C

!

!

!

!

line con 0

 login local

!

line aux 0

!

line vty 0 4

 login local

 transport input ssh

!

!

!

end



R3

R3#show running-config

Building configuration...



Current configuration : 1097 bytes

!

version 15.1

no service timestamps log datetime msec

no service timestamps debug datetime msec

service password-encryption

!

hostname R3

!

!

!

enable secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

!

!

!

!

ip cef

no ipv6 cef

!

!

!

username admin privilege 15 secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

license udi pid CISCO1941/K9 sn FTX1524K53T-

!

!

!

!

!

!

!

!

!

!

!

ip ssh version 2

no ip domain-lookup

ip domain-name too.net

!

!

spanning-tree mode pvst

!

!

!

!

!

!

interface GigabitEthernet0/0

 ip address 10.0.23.1 255.255.255.252

 duplex auto

 speed auto

!

interface GigabitEthernet0/1

 no ip address

 duplex auto

 speed auto

!

interface Serial0/1/0

 description UHENDUS-R1

 ip address 201.10.23.2 255.255.255.252

 clock rate 64000

!

interface Serial0/1/1

 description UHENDUS-R2

 ip address 194.25.10.41 255.255.255.252

 clock rate 64000

!

interface Vlan1

 no ip address

 shutdown

!

ip classless

!

ip flow-export version 9

!

!

!

banner motd ^Cutoriseerimata sisselogimine on keelatud!

^C

!

!

!

!

line con 0

 login local

!

line aux 0

!

line vty 0 4

 login local

 transport input ssh

!

!

!

end





R3#


S1

S1#show running-config

Building configuration...



Current configuration : 1555 bytes

!

version 15.0

no service timestamps log datetime msec

no service timestamps debug datetime msec

service password-encryption

!

hostname S1

!

enable secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

!

ip ssh version 2

no ip domain-lookup

ip domain-name too.net

!

username admin secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

!

spanning-tree mode pvst

spanning-tree extend system-id

!

interface FastEthernet0/1

 switchport mode access

 spanning-tree portfast

!

interface FastEthernet0/2

 switchport mode access

 spanning-tree portfast

!

interface FastEthernet0/3

!

interface FastEthernet0/4

!

interface FastEthernet0/5

!

interface FastEthernet0/6

!

interface FastEthernet0/7

!

interface FastEthernet0/8

!

interface FastEthernet0/9

!

interface FastEthernet0/10

!

interface FastEthernet0/11

!

interface FastEthernet0/12

!

interface FastEthernet0/13

!

interface FastEthernet0/14

!

interface FastEthernet0/15

!

interface FastEthernet0/16

!

interface FastEthernet0/17

!

interface FastEthernet0/18

!

interface FastEthernet0/19

!

interface FastEthernet0/20

!

interface FastEthernet0/21

!

interface FastEthernet0/22

!

interface FastEthernet0/23

!

interface FastEthernet0/24

!

interface GigabitEthernet0/1

 description UHENDUS-R1

 switchport mode access

!

interface GigabitEthernet0/2

!

interface Vlan1

 ip address 192.168.5.2 255.255.255.128

!

ip default-gateway 192.168.5.1

!

banner motd ^Cutoriseerimata sisselogimine on keelatud!

^C

!

!

!

line con 0

 login local

!

line vty 0 4

 login local

 transport input ssh

line vty 5 15

 login local

 transport input ssh

!

!

!

!

end





S1#



S2

S2#show running-config

Building configuration...



Current configuration : 1555 bytes

!

version 15.0

no service timestamps log datetime msec

no service timestamps debug datetime msec

service password-encryption

!

hostname S2

!

enable secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

!

ip ssh version 2

no ip domain-lookup

ip domain-name too.net

!

username admin secret 5 $1$mERr$m1slDCHhMX9jPOb98xavu.

!

!

!

spanning-tree mode pvst

spanning-tree extend system-id

!

interface FastEthernet0/1

 switchport mode access

 spanning-tree portfast

!

interface FastEthernet0/2

 switchport mode access

 spanning-tree portfast

!

interface FastEthernet0/3

!

interface FastEthernet0/4

!

interface FastEthernet0/5

!

interface FastEthernet0/6

!

interface FastEthernet0/7

!

interface FastEthernet0/8

!

interface FastEthernet0/9

!

interface FastEthernet0/10

!

interface FastEthernet0/11

!

interface FastEthernet0/12

!

interface FastEthernet0/13

!

interface FastEthernet0/14

!

interface FastEthernet0/15

!

interface FastEthernet0/16

!

interface FastEthernet0/17

!

interface FastEthernet0/18

!

interface FastEthernet0/19

!

interface FastEthernet0/20

!

interface FastEthernet0/21

!

interface FastEthernet0/22

!

interface FastEthernet0/23

!

interface FastEthernet0/24

!

interface GigabitEthernet0/1

 description UHENDUS-R2

 switchport mode access

!

interface GigabitEthernet0/2

!

interface Vlan1

 ip address 192.168.6.2 255.255.255.128

!

ip default-gateway 192.168.6.1

!

banner motd ^CAutoriseerimata sisselogimine on keelatud!^C

!

!

!

line con 0

 login local

!

line vty 0 4

 login local

 transport input ssh

line vty 5 15

 login local

 transport input ssh

!

!

!

!

end





S2#





