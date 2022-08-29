#!/bin/sh

network="eth0"
ip=
netmask=
gateway=

parse_parameter() {
    while IFS="" read -r line
    do
        for x in $line; do
            key=$(echo "$x" | cut -d'=' -f1)
            value=$(echo "$x" | cut -d'=' -f2)
            case "$key" in
                password)
                echo "tc:$value" | chpasswd
                ;;
                ip)
                ip=$value
                ;;
                netmask)
                netmask=$value
                ;;
                gateway)
                gateway=$value
                ;;
                nameserver)
                echo "nameserver $value" >> /etc/resolv.conf
                ;;
            esac
        done
    done < /proc/cmdline
}

configure_network() {
    if [ -n "$ip" ]; then
        ifconfig $network "$ip" netmask "$netmask"
        ifconfig $network up
        route add default gw "$gateway" $network
        echo "IP: $ip"
    else
        ifconfig eth0 | grep "inet addr" | awk '{ print $2}' | awk -F: '{print "IP: "$2}'
    fi
    sleep 10
}

parse_parameter
configure_network
/usr/local/etc/init.d/openssh start >> /dev/null 2>&1
/bin/sh