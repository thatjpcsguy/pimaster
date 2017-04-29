#!/bin/sh

. /config/server-ip.config

PI_DC=`cat /etc/resolv.conf | grep domain | cut -d' ' -f2 | tr . -`

if grep -q domain /etc/resolv.conf; then 
  PI_DC=`cat /etc/resolv.conf | grep domain | cut -d' ' -f2 | tr . -`
else
  PI_DC=`cat /etc/resolv.conf | grep search | cut -d' ' -f2 | tr . -`
fi

# TODO: More robust method of getting network device name
if [ -f /sys/class/net/eth0/address ]; then
  PI_NODE=client-`cat /sys/class/net/eth0/address | tr -d ':'`
else
  PI_NODE=client-`cat /sys/class/net/eth1/address | tr -d ':'`
fi

PI_BASE=/var/lib/pimaster

mkdir -p $PI_BASE/config
mkdir -p $PI_BASE/data

if ! [ "`uname -m`" == "x86_64" ]; then 
  chown pi:pi -R $PI_BASE
else
  useradd freelancer sudo
fi

hostname $PI_NODE
echo "127.0.0.1   localhost $PI_NODE" > /etc/hosts
echo $PI_NODE > /etc/hostname

# Get consul binary
if ! [ -f /usr/bin/consul ]; then
  cd /tmp
  # TODO: Use latest vesrion of consul
  if [ "`uname -m`" == "x86_64" ]; then
    # wget -O consul.zip https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_amd64.zip
    wget -O consul.zip https://releases.hashicorp.com/consul/0.6.0/consul_0.6.0_linux_amd64.zip
  else
    # wget -O consul.zip https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_arm.zip
    wget -O consul.zip https://releases.hashicorp.com/consul/0.6.0/consul_0.6.0_linux_arm.zip
  fi
  unzip consul.zip
  mv /tmp/consul /usr/bin/consul
fi;

# TODO: Remove watch?
watch "/usr/bin/consul agent -retry-join=$SERVER_IP -config-dir $PI_BASE/config -data-dir $PI_BASE/data -dc=$PI_DC -node=$PI_NODE" &

if ! [ -f /usr/bin/dig ]; then
	apt-get update
	apt-get install dnsutils
fi;

curl -s http://`dig @127.0.0.1 -p 8600 consul.service.consul +short`:8500/ui/scripts/getconfig.sh | bash
