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
write_files:
  - path: /etc/ssh/sshd_config
    permissions: '0644'
    content: |
      Include /etc/ssh/sshd_config.d/*.conf
      MaxAuthTries 2
      KbdInteractiveAuthentication no
      UsePAM yes

      PasswordAuthentication no
      PermitRootLogin no

      AllowAgentForwarding no
      AllowTcpForwarding no
      X11Forwarding no
      PrintMotd yes
      AcceptEnv LANG LC_*
      Subsystem       sftp    /usr/lib/openssh/sftp-server
      AllowUsers dev
  - path: /usr/local/bin/cleanup-tailscale.sh
    permissions: '0755'
    # There's no way to overwrite an existing hostname in tailscale, so we have to delete it
    # before starting tailscale. see https://github.com/tailscale/tailscale/issues/4778
    content: |
      #!/bin/bash
      set -e  # Exit on error
      set -x

      output=$(curl "https://api.tailscale.com/api/v2/tailnet/-/devices" \
        -u "${tailscale_api_key}:")
      echo $output
      # Get device ID if it exists
      DEVICE_IDS=$(curl "https://api.tailscale.com/api/v2/tailnet/-/devices" \
        -u "${tailscale_api_key}:" \
        | jq -r ".devices[] | select(.hostname == \"${tailscale_hostname}\") | .nodeId" || echo "")
      while IFS= read -r id; do
        if [[ ! -z "$id" ]]; then
          echo "deleting tailscale device: $id";
          curl -sSL -XDELETE  -u "${tailscale_api_key}:" "https://api.tailscale.com/api/v2/device/$id";
        fi
      done <<EOL
      $DEVICE_IDS
packages:
  - fail2ban
  - ufw
  - jq
# base image includes docker
runcmd:
  - sudo timedatectl set-timezone America/Vancouver
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
  - /usr/local/bin/cleanup-tailscale.sh
  - ['tailscale', 'up', '--auth-key=${tailscale_token}', '--hostname=${tailscale_hostname}', '--reset']
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw allow 443/udp  # For HTTPS/3 support
  - printf "[sshd]\nenabled = true\nbanaction = iptables-multiport" > /etc/fail2ban/jail.local
  - systemctl enable fail2ban
  - systemctl start fail2ban
  - ufw allow 'OpenSSH'
  - ufw enable
  - systemctl restart ssh
  - rm /var/www/html/*
  - chmod +x /home/dev/code/caddy.sh
  - docker compose -f /home/dev/code/docker-compose.yaml up -d
