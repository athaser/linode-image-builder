#!/bin/bash
set -e

IMG=linode-fixed.img
MNT=/mnt/linode-fixed
SIZE_MB=6144
HOSTNAME=cryptovm
INTERFACE=eth0

echo "[+] Creating raw image file (${SIZE_MB}MB)..."
dd if=/dev/zero of=$IMG bs=1M count=$SIZE_MB

echo "[+] Formatting image with ext4 filesystem..."
mkfs.ext4 $IMG

echo "[+] Mounting image to $MNT..."
mkdir -p $MNT
mount -o loop $IMG $MNT

echo "[+] Bootstrapping minimal Ubuntu system (jammy)..."
debootstrap --arch=amd64 jammy $MNT http://archive.ubuntu.com/ubuntu

echo "[+] Binding /dev, /proc, /sys..."
mount --bind /dev $MNT/dev
mount --bind /proc $MNT/proc
mount --bind /sys $MNT/sys

echo "[+] Entering chroot to configure system..."
chroot $MNT /bin/bash -c "
    echo '[CHROOT] Setting root password...'
    passwd

    echo '[CHROOT] Setting hostname...'
    echo '$HOSTNAME' > /etc/hostname

    echo '[CHROOT] Writing /etc/fstab...'
    echo '/dev/sda  /  ext4  defaults  0 1' > /etc/fstab

    echo '[CHROOT] Creating netplan config with interface $INTERFACE...'
    mkdir -p /etc/netplan
    cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: true
EOF

    echo '[CHROOT] Generating netplan config...'
    netplan generate
    netplan try || true  # ignore systemd-related errors in chroot

    echo '[CHROOT] Installing packages...'
    apt update
    apt install -y systemd systemd-sysv openssh-server netplan.io python3 curl git nano vim htop

    echo '[CHROOT] Enabling SSH service and creating user...'
    systemctl enable ssh
    useradd -m -s /bin/bash cryptouser
    passwd cryptouser
"

echo "[+] Copying user files to image's /root/ (excluding system files)..."
rsync -av --exclude="*.img" --exclude="*.img.gz" --exclude=".cache/" --exclude=".*" /root/ $MNT/root/

echo "[+] Unmounting system directories..."
umount $MNT/dev
umount $MNT/proc
umount $MNT/sys
umount $MNT

echo "[+] Compressing final image..."
gzip -c $IMG > $IMG.gz

echo "[✓] Done! Upload $IMG.gz to Linode Custom Images."

echo "
[ℹ] After booting on Linode:
1. Check interface name (e.g. enp0s4) with: ip a
2. Update netplan config if needed:
   cat <<EOF > /etc/netplan/01-netcfg.yaml
   network:
     version: 2
     ethernets:
       enp0s4:
         dhcp4: true
   EOF
   netplan generate
   netplan apply
   ip link set enp0s4 up

3. If SSH login fails:
   sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
   sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
   systemctl restart ssh
"