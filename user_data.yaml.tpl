#cloud-config
users:
  - name: dev
    groups: users, admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_authorized_key}
package_update: true
package_upgrade: true
# apt:
#   sources:
#     tailscale.list:
#       source: "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu noble main"
#       keyid: 458CA832957F5868
#   keyring:
#     tailscale:
#       source: "https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg"
#       keyid: 458CA832957F5868
    # docker.list:
      # source: deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable
      # keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
packages:
  - nginx
  - fail2ban
  - ufw
  - jq
  # - tailscale
  # - docker-ce
  # - docker-ce-cli
  # - containerd.io
  # - docker-buildx-plugin
  # - docker-compose-plugin
runcmd:
  - mkdir -p /home/dev/code/
  - chown -R dev:dev /home/dev/code
  # - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  # - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
  # - /usr/local/bin/cleanup-tailscale.sh
  # - ['tailscale', 'up', '--auth-key=${tailscale_token}', '--hostname=${tailscale_hostname}', '--reset']
  # - curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  # - curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
  # - apt update
  # - apt install tailscale
  # - tailscale up --authkey=${tailscale_token}
  - systemctl enable nginx
  - ufw allow 'Nginx HTTP'
  - printf "[sshd]\nenabled = true\nbanaction = iptables-multiport" > /etc/fail2ban/jail.local
  - systemctl enable fail2ban
  - systemctl start fail2ban
  - ufw allow 'OpenSSH'
  - ufw enable
  - sed -ie '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  - sed -ie '/^PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
  - sed -ie '/^X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
  - sed -ie '/^#MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
  - sed -ie '/^#AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' /etc/ssh/sshd_config
  - sed -ie '/^#AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config
  - sed -ie '/^#AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh/authorized_keys/' /etc/ssh/sshd_config
  - sed -i '$a AllowUsers dev' /etc/ssh/sshd_config
  - systemctl restart ssh
  - rm /var/www/html/*
  - echo "Hello! I am Nginx @ $(curl -s ipinfo.io/ip)! This record added at $(date -u)." >>/var/www/html/index.html
