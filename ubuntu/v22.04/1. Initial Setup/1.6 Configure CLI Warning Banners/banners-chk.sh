#!/bin/bash

motd-chk(){
  echo -e "- 'motd' configuration check:"
  
  if [ -e /etc/motd ]; then
    ex="exists and configured properly"
    [[ "$(stat -Lc '%a' /etc/motd)" -ne 644 ]] && con=" and access is not configure"
  else 
    ex="doesn't exists"
  fi

  if [[ -n "$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/"//g'))" /etc/motd  2> /dev/null)" ]]; then
    echo -e "\t- Audit result: **FAIL** ['/etc/motd' $ex, not configured properly$con]"
  else
    echo -e "\t- Audit result: **PASS** ['/etc/motd' $ex]"
  fi
}

banner-chk(){
  local uID=$(stat -Lc '%u' $@)
  local gID=$(stat -Lc '%g' $@)
  local acc=$(stat -Lc '%a' $@)
  local fcot="isn't configured properly"
  local pcot="is configured properly"
  local name='remote'

  if [[ "$uID" -ne 0 || "$gID" -ne 0 || "$acc" -ne 644 ]]; then
    fcot="and access aren't configured properly"
  else
    pcot="and access are configured properly"
  fi

  [[ "$@" = "/etc/issue" ]] && name='local'

  echo -e "- $name login warning banner configuration check:"
  if [[ -n "$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/"//g'))" $@ 2> /dev/null)" ]]; then
    echo -e "\t- Audit result: **FAIL** ['$@' $fcot]"
  else
    echo -e "\t- Audit result: **PASS** ['$@' $pcot]"
  fi
}

motd-chk

names=('/etc/issue' '/etc/issue.net')
for n in "${names[@]}"; do 
  banner-chk $n
done
