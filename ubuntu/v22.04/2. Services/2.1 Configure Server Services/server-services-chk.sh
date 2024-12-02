#!/bin/bash

service-chk() {
  local pkg_output=''
  local output_p=''
  local output_f=''
  local logvr=1
  local pkg_name=$(echo $1 | cut -d\. -f1)

  if [[ "$pkg_name" = "dovecot" ]]; then
    dpkg-query -s dovecot-imapd &>/dev/null && pkg_output="$pkg_output\t- dovecot-imapd is installed." || pkg_output="$pkg_output\t- dovecot-imapd isn't installed."
    dpkg-query -s dovecot-pop3d &>/dev/null && pkg_output="$pkg_output\t- dovecot-pop3d is installed." || pkg_output="$pkg_output\t- dovecot-pop3d isn't installed."
  elif [[ "$pkg_name" = "nfs-server" ]]; then
    dpkg-query -s nfs-kernel-server &>/dev/null && pkg_output="$pkg_output\t- nfs-kernel-server is installed." || pkg_output="$pkg_output\t- nfs-kernel-server isn't installed."
  else 
    dpkg-query -s "$pkg_name" &>/dev/null && pkg_output="$pkg_output\t- $pkg_name is installed." || pkg_output="$pkg_output\t- $pkg_name isn't installed."
  fi

  if systemctl is-enabled "$1" 2>/dev/null | grep -q 'enabled'; then
    output_f="$output_f\n\t - $1 is enabled."
    logvr=0
  else
    output_p="$output_p\n\t - $1 is NOT enabled."
  fi

  if systemctl is-active "$1" 2>/dev/null | grep -q '^active'; then
    output_f="$output_f\n\t - $1 is active."
    logvr=0
  else
    output_p="$output_p\n\t - $1 is NOT active."
  fi

  echo -e "- Audit for $pkg_name:"
  echo -e "$pkg_output"
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t# Audit result: **FAIL** [$1]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t# Audit result: **PASS** [$1]"
    echo -e "\t- Reason: $output_p"
  fi
}

services=('autofs.service' 'avahi-daemon.socket avahi-daemon.service' 'isc-dhcp-server.service isc-dhcp-server6.service' 'bind9.service' 'dnsmasq.service' 'vsftpd.service' 'slapd.service' 'dovecot.socket dovecot.service' 'nfs-server.service')

for s in "${services[@]}"; do 
  service-chk $s 
done
