# Manual Steps to Build a Linode-Compatible Ubuntu Image

This guide walks you step-by-step through the manual creation of a minimal Ubuntu image for Linode, with full root access, SSH, Python, and networking via Netplan.

---

## 🧱 Image Creation & Mounting

```bash
# Create a 6GB blank image file
dd if=/dev/zero of=linode-fixed.img bs=1M count=6144

# Format it with ext4 filesystem
mkfs.ext4 linode-fixed.img

# Create a mount point and mount the image
mkdir /mnt/linode-fixed
sudo mount -o loop linode-fixed.img /mnt/linode-fixed
```

---

## 🐧 Bootstrap Ubuntu Filesystem

```bash
# Use debootstrap to install a minimal Ubuntu base system (Jammy Jellyfish)
sudo debootstrap --arch=amd64 jammy /mnt/linode-fixed http://archive.ubuntu.com/ubuntu
```

---

## 🔗 Bind system directories

```bash
# Bind essential virtual filesystems for chrooted environment
sudo mount --bind /dev /mnt/linode-fixed/dev
sudo mount --bind /proc /mnt/linode-fixed/proc
sudo mount --bind /sys /mnt/linode-fixed/sys
```

---

## 🚪 Enter chroot

```bash
sudo chroot /mnt/linode-fixed
```

Now you're inside the chroot and can configure the OS manually.

---

## ⚙️ Basic System Setup (inside chroot)

```bash
# Set root password
passwd

# Set hostname
echo "cryptovm" > /etc/hostname

# Basic fstab
echo "/dev/sda  /  ext4  defaults  0 1" > /etc/fstab
```

---

## 🌐 Network Configuration (Netplan)

```bash
# Create Netplan config with eth0 as default interface
mkdir -p /etc/netplan

cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF

# Generate Netplan config (ignore errors in chroot)
netplan generate
netplan try || true
```

---

## 📦 Install essential packages

```bash
apt update
apt install -y systemd systemd-sysv openssh-server netplan.io python3
apt install -y curl git nano vim htop
```

---

## 👤 Create user and enable SSH

```bash
systemctl enable ssh
useradd -m -s /bin/bash cryptouser
passwd cryptouser
```

---

## 🔚 Exit chroot

```bash
exit
```

---

## 📁 Inject user files (outside chroot)

```bash
# Option 1: Copy specific folder
cp -r /root/myfiles /mnt/linode-fixed/root/

# Option 2: rsync while excluding system files
rsync -av --exclude="*.img" --exclude="*.img.gz" --exclude=".cache/" /root/ /mnt/linode-fixed/root/

# Option 3: exclude hidden files too
rsync -av --exclude="*.img" --exclude="*.img.gz" --exclude=".cache/" --exclude=".*" /root/ /mnt/linode-fixed/root/
```

---

## 🔻 Unmount system directories

```bash
sudo umount /mnt/linode-fixed/dev
sudo umount /mnt/linode-fixed/proc
sudo umount /mnt/linode-fixed/sys
sudo umount /mnt/linode-fixed
```

---

## 📦 Compress image

```bash
# Option 1: Overwrite original image
gzip -9 linode-fixed.img

# Option 2: Keep both
gzip -c linode-fixed.img > linode-fixed.img.gz
```

---

## 🖥️ Linode Post-Boot (LISH Console)

### 1. Networking Fix (if no IP):

```bash
ip a  # Find the correct interface (e.g. enp0s4)

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
```

---

### 2. SSH Permission Fix (if login fails):

```bash
cat /etc/ssh/sshd_config | grep -iE 'PermitRootLogin|PasswordAuthentication'

sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

systemctl restart ssh
```

---

✅ Your image is now fully bootable, network-ready, and accessible via SSH!