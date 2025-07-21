# Linode Image Builder

This project builds a **bootable Ubuntu Server image** from scratch using `debootstrap`, preconfigured for deployment on **Linode** as a custom image. It allows you to create a lightweight, reproducible, and portable system with preinstalled tools and custom files.

---

## ✅ Features

- Ubuntu 22.04 LTS (Jammy Jellyfish) base
- `systemd` and `openssh-server` pre-installed
- Netplan configured for DHCP (default interface: `eth0`)
- Root login via password enabled
- Optional non-root user with password
- Python 3, Git, Vim, Curl, Nano, Htop installed
- File injection into `/root/` from the host system
- Gzipped image ready for Linode upload

---

## 📦 Requirements

- Ubuntu or Debian host system
- Root access
- `debootstrap`, `rsync`, `gzip`, `mount`

Install dependencies (if missing):

```bash
sudo apt install debootstrap rsync gzip
```

---

## 🛠️ Usage

### 1. Run the builder script

```bash
sudo ./build-image.sh
```

This will:

- Create `linode-fixed.img` (6GB)
- Mount and install Ubuntu via `debootstrap`
- Configure hostname, fstab, netplan, ssh
- Create root and optional user
- Copy selected files from `/root/` into the image
- Compress the image into `linode-fixed.img.gz`

### 2. Upload to Linode

Go to the [Linode Cloud Manager → Images](https://cloud.linode.com/images) and upload `linode-fixed.img.gz`.

### 3. Deploy VM using the custom image

- Create a new Linode
- Choose "Custom Image"
- Select `linode-fixed.img.gz`
- Deploy the instance

---

## 🖥️ Post-boot setup (via LISH Console)

If networking doesn't come up:

```bash
ip a     # Identify interface (e.g. enp0s4)

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

If SSH login fails with “Permission denied”:

```bash
sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh
```

---

## 📁 File structure

```
linode-image-builder/
├── build-image.sh        # Main image creation script
├── post-boot-setup.md    # Console commands if network/ssh fails
├── README.md             # This file
└── files/                # (Optional) User files to be injected into image
```

---

## ⚠️ Notes

- This image does not include a bootloader (GRUB). Linode uses its own kernel.
- Make sure your root password and SSH config allow login after boot.
- Test everything via LISH before relying on SSH access.

---

## 🧑‍💻 Author

Made with ❤️ by Athanasios Sersemis

MIT License