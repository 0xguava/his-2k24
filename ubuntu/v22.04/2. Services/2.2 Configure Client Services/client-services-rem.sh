#!/bin/bash

client-rem(){
  echo -e "- Remediation for $@ installation check:"

  if dpkg-query -s $@ &>/dev/null; then
    apt purge $@ -y &> /dev/null &&  
    echo -e "\t# Remediation: **SUCCESS**" || echo -e "\t# Remediation: **FAIL**"
  else 
    echo -e "\t# Remediation: Everything is **OK**"
  fi 
}

services=('nis' 'rsh-client' 'talk' 'telnet' 'ldap-utils' 'ftp')
echo -e "- Remediation for Client services Configuration:"
for s in "${services[@]}"; do 
  client-rem $s 
done
