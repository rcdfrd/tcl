#! /bin/bash

_error() {
    printf '\033[0;31;31m%b\033[0m' "$1"
    exit 1
}
_exists() {
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else which "$cmd" >/dev/null 2>&1; fi
    local rt=$?
    return ${rt}
}
check_tools() {
    for i in "$@"; do
        if ! _exists "$i"; then _error "$i command not found.\n"; fi
    done
}

query(){
    # Ask whether to change the password
    read -rp "Do you want to change the password? (y/n default password is toor): " _bool
    if [ "$_bool" == "y" ]; then
        read -r -p "Please enter a new password: " password
    else
        password="toor"
    fi

    # Ask whether to use DHCP
    read -rp "Do you want to use DHCP? (y/n): " use_dhcp
    if [ ! "$use_dhcp" == "y" ]; then
        # If DHCP is needed, ask for related information
        read -rp "Please enter the host IP address: " ip
        read -rp "Please enter the subnet mask: " netmask
        read -rp "Please enter the gateway address: " gateway
    else
        # If DHCP is not used, set default values or customize as needed
        ip=
        netmask=
        gateway=
    fi

    echo "Password set to: $password"

    echo "Using DHCP: $use_dhcp"
    if [ "$use_dhcp" == "y" ]; then
        echo "Host IP address: $ip"
        echo "Subnet mask: $netmask"
        echo "Gateway address: $gateway"
    fi

    read -rp "Comfirm that the information above is correct? (y/n): " _bool
    if [ ! "$_bool" == "y" ]; then
        _error "the information above is not correct"
    fi
}

check_tools wget
corepure64="https://raw.githubusercontent.com/rcdfrd/tcl/main/bin/corepure64.gz"
vmlinuz64="https://raw.githubusercontent.com/rcdfrd/tcl/main/bin/vmlinuz64"

wget -q $corepure64 -O /boot/tcl_corepure64.gz
wget -q $vmlinuz64 -O /boot/tcl_vmlinuz64

if [ -d /boot/grub2 ]; then
    grubreboot=grub2-reboot
    cfg=/boot/grub2/custom.cfg
elif [ -d /boot/grub ]; then
    grubreboot=grub-reboot
    cfg=/boot/grub/custom.cfg
else
    _error "Unable to find the GRUB directory!\n"
fi

dev=$(df /boot | tail -1 | awk '{print $1}')
mountpoint=$(df /boot | tail -1 | awk '{print $NF}')
uuid=$(blkid -s UUID -o value "$dev")
[ -z "$uuid" ] && echo "Unable to find the boot partition!" && exit 1

query

echo "menuentry 'tcl' {
  search --no-floppy --fs-uuid --set=root $uuid
  linux /$(realpath --relative-to="$mountpoint" /boot/tcl_vmlinuz64) password=$password ip=$ip netmask=$netmask gateway=$gateway
  initrd /$(realpath --relative-to="$mountpoint" /boot/tcl_corepure64.gz)
}
" > $cfg
$grubreboot tcl

echo "Please reboot to enter tcl"
