# Post-Boot Setup (via Linode LISH Console)

If your Linode boots into the custom image but you cannot connect via SSH or there's no networking, follow the steps below via LISH Console.

---

## 🔧 1. Bring up the network interface manually

First, identify the actual interface name:

```bash
ip a
```

Look for something like `enp0s4`, `ens3`, or similar. If it's not `eth0`, update your netplan config:

```bash
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

> ⚠️ Replace `enp0s4` with the actual interface name from `ip a`

---

## 🔐 2. Enable SSH root login (if blocked)

If you get `Permission denied` when trying to SSH in as root:

```bash
cat /etc/ssh/sshd_config | grep -iE 'PermitRootLogin|PasswordAuthentication'
```

Ensure the config allows root login with password:

```bash
sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Add them manually if they don't exist
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

systemctl restart ssh
```

---

## ✅ 3. Test connectivity

Once you've applied the netplan config and restarted SSH, try connecting via:

```bash
ssh root@<your-linode-ip>
```

You should now have full access to your deployed image.