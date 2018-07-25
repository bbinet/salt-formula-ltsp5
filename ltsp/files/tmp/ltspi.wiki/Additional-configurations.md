# Enable internet access for LTSP clients
Become root on the LTSP server
```
sudo su -
```
Install the iptables-persistent package to be able to make iptables configurations permanent
```
apt install iptables-persistent
```
Configure NAT for the LTSP LAN 192.168.67.0/24 and make the configuration permanent
```
iptables --table nat --append POSTROUTING --jump MASQUERADE --source 192.168.67.0/24
sudo netfilter-persistent save
```
Enable IP forwarding on the server and also make it permanent
```
echo 1 > /proc/sys/net/ipv4/ip_forward
echo “net.ipv4.ip_forward=1” >> /etc/sysctl.conf
```