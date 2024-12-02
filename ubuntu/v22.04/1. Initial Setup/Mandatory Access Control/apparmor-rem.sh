#!/bin/bash

installed-rem() {
  echo -e "- Remidiation of apparmor installation:"
  if [[ -z "$(dpkg-query -s apparmor)" ]]; then
    apt install apparmor -y &>/dev/null && echo -e "\t- Remidiation: **SUCCESS**" || echo -e "\t- Remediation: Everything is **OK**"
  fi

  echo -e "- Remidiation of apparmor-utils installation:"
  if [[ -z "$(dpkg-query -s apparmor-utils 2>/dev/null)" ]]; then
    apt install apparmor-utils -y &>/dev/null && echo -e "\t- Remidiation: **SUCCESS**" || echo -e "\t- Remediation: Everything is **OK**" 
  fi
}

bootloader-rem() {
  GRUB_FILE="/etc/default/grub"
  BACKUP_FILE="/etc/default/grub.bak"

  if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "\t- Creating backup of $GRUB_FILE at $BACKUP_FILE"
    sudo cp -r "$GRUB_FILE" "$BACKUP_FILE"
  else
    echo -e "\t- Backup already exists at $BACKUP_FILE"
  fi

  CURRENT_CMDLINE=$(grep "^GRUB_CMDLINE_LINUX=" "$GRUB_FILE" | sed -e 's/^GRUB_CMDLINE_LINUX="//' -e 's/"$//')

  ADD_APPARMOR=1
  ADD_SECURITY=1

  if [[ "$CURRENT_CMDLINE" == *"apparmor=1"* ]]; then
    ADD_APPARMOR=0
  fi

  if [[ "$CURRENT_CMDLINE" == *"security=apparmor"* ]]; then
    ADD_SECURITY=0
  fi

  NEW_CMDLINE="$CURRENT_CMDLINE"
  if [[ $ADD_APPARMOR -eq 1 ]]; then
    NEW_CMDLINE="$NEW_CMDLINE apparmor=1"
  fi
  if [[ $ADD_SECURITY -eq 1 ]]; then
    NEW_CMDLINE="$NEW_CMDLINE security=apparmor"
  fi

  if [[ "$NEW_CMDLINE" != "$CURRENT_CMDLINE" ]]; then
    echo -e "\t  Updating GRUB_CMDLINE_LINUX in $GRUB_FILE"
    sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$NEW_CMDLINE\"|" "$GRUB_FILE"
    echo -e "\t  Updated GRUB_CMDLINE_LINUX to: $NEW_CMDLINE"
  else
    echo -e "\t  No changes needed. Both parameters are already present."
  fi

  echo -e "\t  Updating GRUB configuration..."
  update-grub && echo -e "\t- Remidiation: **SUCCESS**" || echo -e "\t- Remediation: Everything is **OK**" 

}

profiles-rem() {
  echo -e "- Remidiation for apparmor profiles:"
  if [[ "$p_loaded" -ne "$p_enforce" ]]; then
    aa-enforce /etc/apparmor.d/* && echo -e "\t- Remidiation: **SUCCESS**" || echo -e "\t- Remediation: Everything is **OK**" 
  fi
}

installed-rem
bootloader-rem
profiles-rem

