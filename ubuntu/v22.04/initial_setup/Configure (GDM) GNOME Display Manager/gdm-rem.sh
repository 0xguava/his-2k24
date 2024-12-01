#!/bin/bash

banner-rem() {
  echo -e "\n- Remediation for GDM login banner:"
  l_pkgoutput=""
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  l_pcl="gdm gdm3" # Space separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
  done
  if [ -n "$l_pkgoutput" ]; then
    l_gdmprofile="gdm"                                                              # Set this to desired profile name IaW Local site policy
    l_bmessage="'Authorized uses only. All activity may be monitored and reported'" # Set to
    desired banner message
    if [ ! -f "/etc/dconf/profile/$l_gdmprofile" ]; then
      echo "Creating profile \"$l_gdmprofile\""
      echo -e "user-db:user\nsystem-db:$l_gdmprofile\nfiledb:/usr/share/$l_gdmprofile/greeter-dconf-defaults" > /etc/dconf/profile/$l_gdmprofile
    fi
    if [ ! -d "/etc/dconf/db/$l_gdmprofile.d/" ]; then
      echo "Creating dconf database directory \"/etc/dconf/db/$l_gdmprofile.d/\""
      mkdir /etc/dconf/db/$l_gdmprofile.d/
    fi
    if ! grep -Piq '^\h*banner-message-enable\h*=\h*true\b' /etc/dconf/db/$l_gdmprofile.d/*; then
      echo "creating gdm keyfile for machine-wide settings"
      if ! grep -Piq -- '^\h*banner-message-enable\h*=\h*' /etc/dconf/db/$l_gdmprofile.d/*; then
        l_kfile="/etc/dconf/db/$l_gdmprofile.d/01-banner-message"
        echo -e "\n[org/gnome/login-screen]\nbanner-message-enable=true" >> "$l_kfile"
      else
        l_kfile="$(grep -Pil -- '^\h*banner-message-enable\h*=\h*' /etc/dconf/db/$l_gdmprofile.d/*)"
        ! grep -Pq '^\h*\[org\/gnome\/login-screen\]' "$l_kfile" && sed -ri '/^\s*bannermessage-enable/ i\[org/gnome/login-screen]' "$l_kfile"
        ! grep -Pq '^\h*banner-message-enable\h*=\h*true\b' "$l_kfile" && sed -ri
        's/^\s*(banner-message-enable\s*=\s*)(\S+)(\s*.*$)/\1true \3//' "$l_kfile"
        #
        sed -ri '/^\s*\[org\/gnome\/login-screen\]/ a\\nbanner-message-enable=true' "$l_kfile"
      fi
    fi
    if ! grep -Piq "^\h*banner-message-text=[\'\"]+\S+" "$l_kfile"; then
      sed -ri "/^\s*banner-message-enable/ a\banner-message-text=$l_bmessage" "$l_kfile"
    fi
    dconf update
  else
    echo -e "\n\n - GNOME Desktop Manager isn't installed\n - Recommendation is Not Applicable\n - No remediation required\n"
  fi
}

user-list-rem() {
  l_gdmprofile="gdm"
  if [ ! -f "/etc/dconf/profile/$l_gdmprofile" ]; then
    echo "Creating profile \"$l_gdmprofile\""
    echo -e "user-db:user\nsystem-db:$l_gdmprofile\nfiledb:/usr/share/$l_gdmprofile/greeter-dconf-defaults" >/etc/dconf/profile/$l_gdmprofile
  fi
  if [ ! -d "/etc/dconf/db/$l_gdmprofile.d/" ]; then
    echo "Creating dconf database directory \"/etc/dconf/db/$l_gdmprofile.d/\""
    mkdir /etc/dconf/db/$l_gdmprofile.d/
  fi
  if ! grep -Piq '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db/$l_gdmprofile.d/*
  then
    echo "creating gdm keyfile for machine-wide settings"
    if ! grep -Piq -- '^\h*\[org\/gnome\/login-screen\]' /etc/dconf/db/$l_gdmprofile.d/*
    then
      echo -e "\n[org/gnome/login-screen]\n# Do not show the user list\ndisable-user-list=true" >>/etc/dconf/db/$l_gdmprofile.d/00-loginscreen
    else
      sed -ri '/^\s*\[org\/gnome\/login-screen\]/ a\# Do not show the user list\ndisable-user-list=true' $(grep -Pil -- '^\h*\[org\/gnome\/loginscreen\]' /etc/dconf/db/$l_gdmprofile.d/*)
    fi
  fi
  dconf update
}

lock-rem(){
  l_delay=$(gsettings get org.gnome.desktop.screensaver lock-delay | awk '{ print $2 }')
  i_delay=$(gsettings get org.gnome.desktop.session idle-delay | awk '{ print $2 }')
  logvr=0

  if [[ "$l_delay" -le 5 ]]; then 
    logvr=1 
  else 
    gsettings set org.gnome.desktop.screensaver lock-delay 5
  fi

  if [[ "$i_delay" -le 900 && "$i_delay" -ne 0 ]]; then 
    logvr=1 
  else 
    gsettings set org.gnome.desktop.session idle-delay 900
    logvr=0
  fi

  echo -e "\n- Remediation for GDM screen lock delay:"
  if [[ "$logvr" -eq 0 ]]; then
    dconf update && echo -e "\t- Remediation: **SUCCESS**"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

lock-override-rem() {
  # Variables 
  LOCKS_DIR="/etc/dconf/db/local.d/locks"
  LOCKS_FILE="$LOCKS_DIR/screensaver"
  CONTENT="# Lock desktop screensaver settings
/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/screensaver/lock-delay"

  # Create the directory if it doesn't exist
  if [ ! -d "$LOCKS_DIR" ]; then
    echo "Directory $LOCKS_DIR does not exist. Creating it..."
    mkdir -p "$LOCKS_DIR"
    echo "Directory created: $LOCKS_DIR"
  else
    echo "Directory $LOCKS_DIR already exists."
  fi

  # Create or overwrite the locks file with the required content
  if [ ! -f "$LOCKS_FILE" ]; then
    echo "File $LOCKS_FILE does not exist. Creating it..."
  else
    echo "File $LOCKS_FILE exists. Overwriting content..."
  fi
  echo "$CONTENT" > "$LOCKS_FILE"
  echo "Content written to $LOCKS_FILE"

  # Update dconf system databases
  echo "Updating dconf system databases..."
  dconf update
  echo "dconf system databases updated."

  echo "Remediation completed."
}

automount-rem() {
  l_pkgoutput=""
  l_gpname="local" # Set to desired dconf profile name (default is local)
  # Check if GNOME Desktop Manager is installed. If package isn't
  installed, recommendation is Not Applicable\n
  # determine system's package manager
  if command -v dpkg-query >/dev/null 2>&1; then
    l_pq="dpkg-query -s"
  elif command -v rpm >/dev/null 2>&1; then
    l_pq="rpm -q"
  fi
  # Check if GDM is installed
  l_pcl="gdm gdm3" # Space seporated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" >/dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n Package: \"$l_pn\" exists on the system\n - checking configuration"
  done
  # Check configuration (If applicable)
  if [ -n "$l_pkgoutput" ]; then
    echo -e "$l_pkgoutput"
    # Look for existing settings and set variables if they exist
    l_kfile="$(grep -Prils -- '^\h*automount\b' /etc/dconf/db/*.d)"
    l_kfile2="$(grep -Prils -- '^\h*automount-open\b' /etc/dconf/db/*.d)"
    # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
    if [ -f "$l_kfile" ]; then
      l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile")"
      echo " - updating dconf profile name to \"$l_gpname\""
    elif [ -f "$l_kfile2" ]; then
      l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile2")"
      echo " - updating dconf profile name to \"$l_gpname\""
    fi
    # check for consistency (Clean up configuration if needed)
    if [ -f "$l_kfile" ] && [ "$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile")" != "$l_gpname" ]; then
      sed -ri "/^\s*automount\s*=/s/^/# /" "$l_kfile"
      l_kfile="/etc/dconf/db/$l_gpname.d/00-media-automount"
    fi
    if [ -f "$l_kfile2" ] && [ "$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile2")" != "$l_gpname" ]; then
      sed -ri "/^\s*automount-open\s*=/s/^/# /" "$l_kfile2"
    fi
    [ -z "$l_kfile" ] && l_kfile="/etc/dconf/db/$l_gpname.d/00-mediaautomount"
    # Check if profile file exists
    if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
      echo -e "\n - dconf database profile exists in: \"$(grep -Pl -"^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\""
    else
      if [ ! -f "/etc/dconf/profile/user" ]; then
        l_gpfile="/etc/dconf/profile/user"
      else
        l_gpfile="/etc/dconf/profile/user2"
      fi
      echo -e " - creating dconf database profile"
      {
        echo -e "\nuser-db:user"
        echo "system-db:$l_gpname"
      } >>"$l_gpfile"
    fi
    # create dconf directory if it doesn't exists
    l_gpdir="/etc/dconf/db/$l_gpname.d"
    if [ -d "$l_gpdir" ]; then
      echo " - The dconf database directory \"$l_gpdir\" exists"
    else
      echo " - creating dconf database directory \"$l_gpdir\""
      mkdir "$l_gpdir"
    fi
    # check automount-open setting
    if grep -Pqs -- '^\h*automount-open\h*=\h*false\b' "$l_kfile"; then
      echo " - \"automount-open\" is set to false in: \"$l_kfile\""
    else
      echo " - creating \"automount-open\" entry in \"$l_kfile\""
      ! grep -Psq -- '\^\h*\[org\/gnome\/desktop\/media-handling\]\b' "$l_kfile" && echo '[org/gnome/desktop/media-handling]' >> "$l_kfile"
      sed -ri '/^\s*\[org\/gnome\/desktop\/media-handling\]/a\\nautomount-open=false' "$l_kfile"
    fi
    # check automount setting
    if grep -Pqs -- '^\h*automount\h*=\h*false\b' "$l_kfile"; then
      echo " - \"automount\" is set to false in: \"$l_kfile\""
    else
      echo " - creating \"automount\" entry in \"$l_kfile\""
      ! grep -Psq -- '\^\h*\[org\/gnome\/desktop\/media-handling\]\b' "$l_kfile" && echo '[org/gnome/desktop/media-handling]' >> "$l_kfile"
      sed -ri '/^\s*\[org\/gnome\/desktop\/media-handling\]/a\\nautomount=false' "$l_kfile"
    fi
    # update dconf database
    dconf update
  else
    echo -e "\n - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
  fi
}

automount-override-rem() {
  # Variables
  LOCKS_DIR="/etc/dconf/db/local.d/locks"
  LOCKS_FILE="$LOCKS_DIR/00-media-automount"
  CONTENT="[org/gnome/desktop/media-handling]
  automount=false
  automount-open=false"

  # Ensure the directory exists
  if [ ! -d "$LOCKS_DIR" ]; then
    echo "Directory $LOCKS_DIR does not exist. Creating it..."
    mkdir -p "$LOCKS_DIR"
    echo "Directory created: $LOCKS_DIR"
  else
    echo "Directory $LOCKS_DIR already exists."
  fi

  # Create or overwrite the locks file with the required content
  if [ ! -f "$LOCKS_FILE" ]; then
    echo "File $LOCKS_FILE does not exist. Creating it..."
  else
    echo "File $LOCKS_FILE exists. Overwriting content..."
  fi
  echo "$CONTENT" > "$LOCKS_FILE"
  echo "Content written to $LOCKS_FILE"

  # Update dconf system databases
  echo "Updating dconf system databases..."
  dconf update
  echo "dconf system databases updated."

  echo "Script execution completed."
}

autorun-rem() {
  l_pkgoutput="" l_output="" l_output2=""
  l_gpname="local" # Set to desired dconf profile name (default is local)
  # Check if GNOME Desktop Manager is installed. If package isn't
  installed, recommendation is Not Applicable\n
  # determine system's package manager
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  # Check if GDM is installed
  l_pcl="gdm gdm3" # Space separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
  done
  echo -e "$l_pkgoutput"
  # Check configuration (If applicable)
  if [ -n "$l_pkgoutput" ]; then
    echo -e "$l_pkgoutput"
    # Look for existing settings and set variables if they exist
    l_kfile="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d)"
    # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
    if [ -f "$l_kfile" ]; then
      l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile")"
      echo " - updating dconf profile name to \"$l_gpname\""
    fi
    [ ! -f "$l_kfile" ] && l_kfile="/etc/dconf/db/$l_gpname.d/00-mediaautorun"
    # Check if profile file exists
    if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
      echo -e "\n - dconf database profile exists in: \"$(grep -Pl -"^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\""
    else
      [ ! -f "/etc/dconf/profile/user" ] &&
        l_gpfile="/etc/dconf/profile/user" || l_gpfile="/etc/dconf/profile/user2"
      echo -e " - creating dconf database profile"
      {
        echo -e "\nuser-db:user"
        echo "system-db:$l_gpname"
      } >>"$l_gpfile"
    fi
    # create dconf directory if it doesn't exists
    l_gpdir="/etc/dconf/db/$l_gpname.d"
    if [ -d "$l_gpdir" ]; then
      echo " - The dconf database directory \"$l_gpdir\" exists"
    else
      echo " - creating dconf database directory \"$l_gpdir\""
      mkdir "$l_gpdir"
    fi
    # check autorun-never setting
    if grep -Pqs -- '^\h*autorun-never\h*=\h*true\b' "$l_kfile"; then
      echo " - \"autorun-never\" is set to true in: \"$l_kfile\""
    else
      echo " - creating or updating \"autorun-never\" entry in \"$l_kfile\""
      if grep -Psq -- '^\h*autorun-never' "$l_kfile"; then
        sed -ri 's/(^\s*autorun-never\s*=\s*)(\S+)(\s*.*)$/\1true \3/' "$l_kfile"
      else
        ! grep -Psq -- '\^\h*\[org\/gnome\/desktop\/media-handling\]\b' "$l_kfile" && echo '[org/gnome/desktop/media-handling]' >>"$l_kfile"
        sed -ri '/^\s*\[org\/gnome\/desktop\/media-handling\]/a \\nautorun-never=true' "$l_kfile"
      fi
    fi
  else
    echo -e "\n - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
  fi
  # update dconf database
  dconf update
}

autorun-override-rem() {
  # Variables
  LOCKS_DIR="/etc/dconf/db/local.d/locks"
  LOCKS_FILE="$LOCKS_DIR/00-media-autorun"
  CONTENT="[org/gnome/desktop/media-handling]
  autorun-never=true"

  # Ensure the directory exists
  if [ ! -d "$LOCKS_DIR" ]; then
    echo "Directory $LOCKS_DIR does not exist. Creating it..."
    mkdir -p "$LOCKS_DIR"
    echo "Directory created: $LOCKS_DIR"
  else
    echo "Directory $LOCKS_DIR already exists."
  fi

  # Create or overwrite the locks file with the required content
  if [ ! -f "$LOCKS_FILE" ]; then
    echo "File $LOCKS_FILE does not exist. Creating it..."
  else
    echo "File $LOCKS_FILE exists. Overwriting content..."
  fi
  echo "$CONTENT" > "$LOCKS_FILE"
  echo "Content written to $LOCKS_FILE"

  # Update dconf system databases
  echo "Updating dconf system databases..."
  dconf update
  echo "dconf system databases updated."

  echo "Script execution completed."
}


banner-rem
user-list-rem
lock-rem
lock-override-rem
automount-rem 
automount-override-rem
autorun-rem
autorun-override-rem
