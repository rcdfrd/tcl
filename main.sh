#!/bin/bash

temp_dir="/tmp/tclxebY2XrKE6CGcH"
current_dir=$(pwd)
CorePure64_url="http://tinycorelinux.net/13.x/x86_64/release/CorePure64-13.1.iso"
CorePure64_name="CorePure64-13.1.iso"
tcz_version="13.x"

trap _exit INT QUIT TERM

_red() {
    printf '\033[0;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[0;31;32m%b\033[0m' "$1"
}

_blue() {
    printf '\033[0;31;36m%b\033[0m' "$1"
}

_exists() {
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

_error() {
    _red "[Error]: $1\n"
    rm -fr $temp_dir
    exit 1
}

check_tools() {
    for i in "$@"; do
        case "$i" in
        advdef)
            k="advancecomp"
            ;;
        unsquashfs)
            k="squashfs-tools"
            ;;
        *)
            k="$i"
            ;;
        esac

        if _exists "$i"; then
            _green "$k command is found\n"
        else
            _error "$k command not found.\n"
        fi
    done
}

create_dir() {
    mkdir -p "$temp_dir/mnt"
    mkdir -p "$temp_dir/down"
    mkdir -p "$temp_dir/ext"
    mkdir -p "$temp_dir/new/boot"
}
download_files() {
    pushd $temp_dir/down || _error "pushd $temp_dir/down\n"

    wget -q "$CorePure64_url" -O $CorePure64_name
    wget -q "$CorePure64_url.md5.txt" -O CorePure64.iso.md5.txt
    md5sum -c CorePure64.iso.md5.txt || _error "[Error]: md5 check error \n"
    popd || _error "popd $temp_dir/down\n"
    ls $temp_dir/down
    _green "files download succeeded\n"
}

install_package() {
    local pacakge_name="$1"
    pushd $temp_dir/down || _error "pushd $temp_dir/down\n"
    wget -q "http://tinycorelinux.net/${tcz_version}/x86_64/tcz/${pacakge_name}.tcz" -O "$pacakge_name".tcz
    wget -q "http://tinycorelinux.net/${tcz_version}/x86_64/tcz/${pacakge_name}.tcz.md5.txt" -O "$pacakge_name".tcz.md5.txt
    md5sum -c "$pacakge_name".tcz.md5.txt || _red "md5 check error \n"
    popd || _error "popd $temp_dir/down\n"
    _green "package $pacakge_name download succeeded\n"
    pushd $temp_dir/ext || _error "pushd $temp_dir/ext\n"
    unsquashfs -f -d . $temp_dir/down/"$pacakge_name".tcz
    popd || _error "popd $temp_dir/ext\n"
    _green "package $pacakge_name install succeeded\n"
}

extract_file() {
    7z x $temp_dir/down/CorePure64-13.1.iso -o$temp_dir/mnt
    cp -ar $temp_dir/mnt/boot/corepure64.gz $temp_dir/mnt/boot/vmlinuz64 $temp_dir/mnt/boot/isolinux $temp_dir
    pushd $temp_dir/ext || _error "pushd $temp_dir/ext\n"
    zcat $temp_dir/corepure64.gz | cpio -i -H newc -d
    popd || _error "popd $temp_dir/ext\n"
    install_package "openssh"
    install_package "openssl-1.1.1"
    install_package "e2fsprogs"
    install_package "dosfstools"
    # grub2
    install_package "ncursesw"
    install_package "udev-lib"
    install_package "libburn"
    install_package "libisofs"
    install_package "readline"
    install_package "libisoburn"
    install_package "mtools"
    install_package "glibc_gconv"
    install_package "liblzma"
    install_package "liblvm2"
    install_package "grub2-multi"
    # util-linux
    install_package "util-linux"
    # tar and xz
    install_package "tar"
    install_package "xz"
    # wget
    install_package "ca-certificates"
    install_package "wget"

    pushd $temp_dir/ext || _error "pushd $temp_dir/ext\n"
    cp -a usr/local/etc/ssh/sshd_config.orig usr/local/etc/ssh/sshd_config

    # prepare for chroot
    mount -t proc /proc proc/
    mount -t sysfs /sys sys/
    mount --bind /dev dev/
    mount --bind /run run/
    echo "nameserver 8.8.4.4" > etc/resolv.conf
    chroot . /bin/sh <<'EOF'
export PS1="(chroot) $PS1"
echo "tc:toor" | chpasswd # toor
for i in `ls -1 /usr/local/tce.installed`; do sudo /usr/local/tce.installed/$i ; done
exit
EOF
    umount -f proc sys dev run
    cp -f "$current_dir"/bootlocal.sh opt/bootlocal.sh
    chmod +x opt/bootlocal.sh
    find . | cpio -o -H newc | gzip -9 >$temp_dir/my_core.gz
    popd || _error "popd $temp_dir/ext\n"
    advdef -z4 $temp_dir/my_core.gz
    # change isolinux/isolinux.cfg  timeout 10
    sed -i 's/timeout 300/timeout 10/g' $temp_dir/isolinux/isolinux.cfg
    ls $temp_dir
}

create_iso() {
    cp -a $temp_dir/my_core.gz $temp_dir/new/boot/corepure64.gz
    cp -a $temp_dir/vmlinuz64 $temp_dir/new/boot/vmlinuz64
    cp -a $temp_dir/isolinux $temp_dir/new/boot/isolinux
    xorriso -as mkisofs -l -J -R -V TC-custom -no-emul-boot -boot-load-size 4 \
        -boot-info-table -b /boot/isolinux/isolinux.bin \
        -c /boot/isolinux/boot.cat -o /tmp/tcl.iso $temp_dir/new
    # xorriso -as mkisofs \
    #     -o $temp_dir/TC-remastered.iso \
    #     -isohybrid-mbr syslinux-6.03/bios/mbr/isohdpfx.bin \
    #     -c boot.cat \
    #     -b isolinux.bin \
    #     -no-emul-boot -boot-load-size 4 -boot-info-table \
    #     -eltorito-alt-boot \
    #     -e uefi.img \
    #     -no-emul-boot \
    #     -isohybrid-gpt-basdat \
    #     ./isobios
}

# check root account
[[ $EUID -ne 0 ]] && _error "This script must be run as root\n"
check_tools cpio tar gzip advdef xorriso wget unsquashfs 7z
create_dir
download_files
extract_file
create_iso
rm -fr $temp_dir
_blue "done iso_file: /tmp/tcl.iso\n"
exit 0
