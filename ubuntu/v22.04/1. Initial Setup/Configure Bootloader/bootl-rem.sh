#!/bin/bash

passwd-rem(){
  echo -e "- Remediation for Bootloader's password"
  echo -e "- Setting up bootloader's password"
  if [[ -z "$(grep "^set superusers" /boot/grub/grub.cfg)" ]] && [[ -z "$(awk -F. '/^\s*password/ {print $1"."$2"."$3}' /boot/grub/grub.cfg)" ]] ; then
    passwdHASH=$(echo -e "$2\n$2" | grub-mkpasswd-pbkdf2 --iteration-count=600000 --salt=64 | grep PBKDF2 | awk '{ print $NF }')
    cat << EOF >> /etc/grub.d/40_custom  
set superusers="${1}"
password_pbkdf2 ${1} $passwdHASH
EOF

update-grub 
echo -e "\t- Remediation: **SUCCESS**"
else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

access-rem(){
  local chk=1
  userID=$(stat -Lc %u /boot/grub/grub.cfg)
  groupID=$(stat -Lc %g /boot/grub/grub.cfg)
  perm=$(stat -Lc %a /boot/grub/grub.cfg)

  [[ "$userID" -ne 0 ]] && chk=0  
  [[ "$groupID" -ne 0 ]] && chk=0  
  [[ "$perm" -ne 600 ]] && chk=0  
  
  echo -e "- Remediation for Bootloader's config access"
  if [[ "$chk" -eq 0 ]]; then
    chown root:root /boot/grub/grub.cfg
    chmod 600 /boot/grub/grub.cfg
    echo -e "\t- Remediation: **SUCCESS**"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

access-rem

if [[ "$#" -eq 0 ]]; then
  echo -e "**** Username and password are required for grub-password remidiation. ****"
  exit 1
fi

uname=''
pswd=''
while getopts 'u:p:' opt; do 
  case ${opt} in 
    u) uname="${OPTARG}" ;;
    p) paswd="${OPTARG}" ;;
  esac
done

# echo $uname
# echo $paswd
passwd-rem "$uname" "$pswd"
