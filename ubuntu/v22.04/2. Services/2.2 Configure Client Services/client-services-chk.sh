#!/bin/bash

client-chk(){
  echo -e "- Audit for $@ installation check:"

  if dpkg-query -s $@ &>/dev/null; then
    echo -e "\t- $@ is installed"
    echo -e "\t# Audit result: **FAIL** [$@ shouldn't be installed]"
  else 
    echo -e "\t- $@ isn't installed"
    echo -e "\t# Audit result: **PASS** [$@]"
  fi 
}

services=('nis' 'rsh-client' 'talk' 'telnet' 'ldap-utils' 'ftp')
echo -e "- Client services Configuration check:"
for s in "${services[@]}"; do 
  client-chk $s 
done
