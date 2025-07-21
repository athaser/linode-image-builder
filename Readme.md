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

This script automates the creation of a bootable image. It:

- Creates a 6GB raw image file
- Mounts and bootstraps Ubuntu with `debootstrap`
- Installs system packages, configures hostname, fstab, netplan, and SSH
- Adds a non-root user and root password
- Injects files from your `/root/` directory into the image
- Compresses the image to `linode-fixed.img.gz`

### 2. Upload to Linode

Go to the [Linode Cloud Manager → Images](https://cloud.linode.com/images) and upload `linode-fixed.img.gz`.

### 3. Deploy VM using the custom image

- Create a new Linode
- Choose "Custom Image"
- Select `linode-fixed.img.gz`
- Deploy the instance

---

## 📖 Included Files

### `build-image.sh`
A complete bash script that builds and configures the bootable image automatically. You can run it directly or use it as a base for your own variations.

### `manual-steps.md`
An alternative to the script above — a detailed step-by-step manual guide with command-by-command instructions. Ideal if you want to learn the process or debug.

### `post-boot-setup.md`
A quick reference for what to do **after** booting your image on Linode, especially if:
- Networking is not working
- You get `Permission denied` with SSH

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

# Add them manually if they don't exist
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

systemctl restart ssh


```

---

## 📁 File structure

```
linode-image-builder/
├── build-image.sh         # Main image creation script
├── manual-steps.md        # Step-by-step manual process
├── post-boot-setup.md     # Console recovery instructions
├── README.md              # This file
├── LICENSE                # MIT License
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