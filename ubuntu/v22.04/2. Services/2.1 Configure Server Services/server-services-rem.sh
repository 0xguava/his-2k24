#!/bin/bash

service-rem() {
  local logvr=1

  if systemctl is-enabled "$@" 2>/dev/null | grep -q 'enabled'; then
    logvr=0
  fi

  if systemctl is-active "$@" 2>/dev/null | grep -q '^active'; then
    logvr=0
  fi

  echo -e "- Remediation for for $@:"
  if [[ $logvr -eq 0 ]]; then
    systemctl stop $@ &&
      systemctl mask $@ &&
      echo -e "\t# Remediation: **SUCCESS**" || echo -e "\t# Remediation: **FAIL**"
  else
    echo -e "\t# Remediation: Everything is **OK**"
  fi
}

mta-rem() {
  echo -e "- Remediation for for $@:"
  POSTFIX_CONF="/etc/postfix/main.cf"
  BACKUP_FILE="/etc/postfix/main.cf.bak"

  if ! command -v postfix &>/dev/null; then
    echo -e "# Remediation: Everything is **OK**"
    exit 1
  fi

  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Creating backup of $POSTFIX_CONF..."
    cp "$POSTFIX_CONF" "$BACKUP_FILE"
  else
    echo "Backup file already exists: $BACKUP_FILE"
  fi

  echo "Updating inet_interfaces in $POSTFIX_CONF..."
  if grep -q "^inet_interfaces" "$POSTFIX_CONF"; then
    sed -i 's/^inet_interfaces.*/inet_interfaces = loopback-only/' "$POSTFIX_CONF"
  else
    echo "inet_interfaces = loopback-only" >>"$POSTFIX_CONF"
  fi

  echo "Restarting Postfix..."
  if systemctl restart postfix; then
    echo "Postfix restarted successfully."
    echo -e "# Remediation: **SUCCESS**"
  fi
}

services=('autofs.service' 'avahi-daemon.socket avahi-daemon.service' 'isc-dhcp-server.service isc-dhcp-server6.service' 'bind9.service' 'dnsmasq.service' 'vsftpd.service' 'slapd.service' 'dovecot.socket dovecot.service' 'nfs-server.service' 'ypserv.service' 'cups.socket cups.service' 'rpcbind.socket rpcbind.service' 'rsync.service' 'smbd.service' 'snmpd.service' 'tftpd-hpa.service' 'squid.service' 'apache2.socket apache2.service nginx.service' 'xinetd.service')

for s in "${services[@]}"; do
  service-rem $s
done

mta-rem
