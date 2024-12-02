#!/bin/bash

motd-rem(){
  echo -e "- Remediation for 'motd' configuration:"

  if [ -e /etc/motd ]; then
    rm -rf /etc/motd
    echo -e "\t- Remidiation: **SUCCESS**"
  else 
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

banner-rem(){
  local uID=$(stat -Lc '%u' $@)
  local gID=$(stat -Lc '%g' $@)
  local acc=$(stat -Lc '%a' $@)
  local name='remote'
  local fcot=''

  [[ "$@" = "/etc/issue" ]] && name='local'

  echo -e "- Remediation for $name warning banner configuration:"

  if [[ "$uID" -ne 0 || "$gID" -ne 0 || "$acc" -ne 644 ]]; then
    chown root:root $(readlink -e $@)
    chmod 644 $(readlink -e $@)
    fcot="fixed ownership and access permissions"
  fi

  if [[ -n "$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/"//g'))" $@ 2> /dev/null)" ]]; then
    echo "Authorized users only. All activity may be monitored and reported." > $@ 
    echo -e "\t- Remidiation: **SUCCESS** ['$@' $fcot]"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

motd-rem

names=('/etc/issue' '/etc/issue.net')
for n in "${names[@]}"; do 
  banner-rem $n
done
