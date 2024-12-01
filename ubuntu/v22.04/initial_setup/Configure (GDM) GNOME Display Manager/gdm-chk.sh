#!/bin/bash

banner-chk(){
  l_pkgoutput=""
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  l_pcl="gdm gdm3" # Space separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\t - Package: \"$l_pn\" exists on the system"
  done
  if [ -n "$l_pkgoutput" ]; then
    l_output="" l_output2=""
    # Look for existing settings and set variables if they exist
    l_gdmfile="$(grep -Prils '^\h*banner-message-enable\b' /etc/dconf/db/*.d)"
    if [ -n "$l_gdmfile" ]; then
      # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
      l_gdmprofile="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_gdmfile")"
      # Check if banner message is enabled
      if grep -Pisq '^\h*banner-message-enable=true\b' "$l_gdmfile"; then
        l_output="$l_output\n\t - The \"banner-message-enable\" option is enabled in \"$l_gdmfile\""
      else
        l_output2="$l_output2\n\t - The \"banner-message-enable\" option is not enabled"
      fi
      l_lsbt="$(grep -Pios '^\h*banner-message-text=.*$' "$l_gdmfile")"
      if [ -n "$l_lsbt" ]; then
        l_output="$l_output\n\t - The \"banner-message-text\" option is set in \"$l_gdmfile\"\n - banner-message-text is set to:\n - \"$l_lsbt\""
      else
        l_output2="$l_output2\n\t - The \"banner-message-text\" option is not set"
      fi
      if grep -Pq "^\h*system-db:$l_gdmprofile" /etc/dconf/profile/"$l_gdmprofile"; then
        l_output="$l_output\n\t - The \"$l_gdmprofile\" profile exists"
      else
        l_output2="$l_output2\n\t - The \"$l_gdmprofile\" profile doesn't exist"
      fi
      if [ -f "/etc/dconf/db/$l_gdmprofile" ]; then
        l_output="$l_output\n\t - The \"$l_gdmprofile\" profile exists in the dconf database"
      else
        l_output2="$l_output2\n\t - The \"$l_gdmprofile\" profile doesn't exist in the dconf database"
      fi
    else
      l_output2="$l_output2\n\t - The \"banner-message-enable\" option isn't configured"
    fi
  else
    echo -e "\t- GNOME Desktop Manager isn't installed\n\t - Recommendation is Not Applicable\n\t# Audit Result: **PASS**"
  fi
  # Report results. If no failures output in l_output2, we pass
  echo -e "\n- Audit for GDM login banner check:"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [GDM login banner configuration] $l_output"
    echo -e "$l_pkgoutput"
  else
    echo -e "\t# Audit Result: **FAIL** [GDM login banner configuration]\n\t- Reason(s) for audit failure:$l_output2"
    echo -e "$l_pkgoutput"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:$l_output"
  fi
}

user-list-chk() {
  l_pkgoutput=""
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  l_pcl="gdm gdm3" # Space separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\t- Package:\"$l_pn\" exists on the system"
  done
  if [ -n "$l_pkgoutput" ]; then
    output="" output2=""
    l_gdmfile="$(grep -Pril '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db)"
    if [ -n "$l_gdmfile" ]; then
      output="$output\n\t - The \"disable-user-list\" option is enabled in \"$l_gdmfile\""
      l_gdmprofile="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_gdmfile")"
      if grep -Pq "^\h*system-db:$l_gdmprofile" /etc/dconf/profile/"$l_gdmprofile"
      then
        output="$output\n\t - The \"$l_gdmprofile\" exists"
      else
        output2="$output2\n\t - The \"$l_gdmprofile\" doesn't exist"
      fi
      if [ -f "/etc/dconf/db/$l_gdmprofile" ]; then
        output="$output\n\t - The \"$l_gdmprofile\" profile exists in the dconf database"
      else
        output2="$output2\n\t - The \"$l_gdmprofile\" profile doesn't exist in the dconf database"
      fi
    else
      output2="$output2\n\t - The \"disable-user-list\" option is not enabled"
    fi
    echo -e "\n- Audit for GDM disable-user-list option:"
    if [ -z "$output2" ]; then
      echo -e "$l_pkgoutput\n\t# Audit Result: **PASS** [GDM 'disable-user-list' option is enabled]$output"
    else
      echo -e "$l_pkgoutput\n\t# Audit Result: **FAIL** [GDM 'disable-user-list' option is disabled]$output2"
      [ -n "$output" ] && echo -e "$output"
    fi
  else
    echo -e "\t- GNOME Desktop Manager isn't installed\n Recommendation is Not Applicable\n\t# Audit Result: **PASS**"
  fi
}

lock-chk() {
  l_delay=$(gsettings get org.gnome.desktop.screensaver lock-delay | awk '{ print $2 }')
  i_delay=$(gsettings get org.gnome.desktop.session idle-delay | awk '{ print $2 }')
  output_p=''
  output_f=''
  logvr=1

  if [[ "$l_delay" -le 5 ]]; then
    output_p="$output_p\n\t - lock-delay is configured properly."
  else
    output_f="$output_f\n\t - lock-delay isn't configured properly."  
    logvr=0
  fi

  if [[ "$i_delay" -le 900 && "$i_delay" -ne 0 ]]; then
    output_p="$output_p\n\t - idle-delay is configured properly."
  else
    output_f="$output_f\n\t - idle-delay isn't configured properly."  
    logvr=0
  fi

  echo -e "\n- Audit for GDM screen lock delay:"
  if [[ "$logvr" -eq 0 ]]; then
    echo -e "\t# Audit Result: **FAIL** [GDM screen lock]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t# Audit Result: **PASS** [GDM screen lock]"
    echo -e "\t- Reason: $output_p"
  fi
}

lock-override-chk() {
  # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is
  # Determine system's package manager
  l_pkgoutput=""
  if command -v dpkg-query >/dev/null 2>&1; then
    l_pq="dpkg-query -s"
  elif command -v rpm >/dev/null 2>&1; then
    l_pq="rpm -q"
  fi
  # Check if GDM is installed
  l_pcl="gdm gdm3" # Space-separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" >/dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\t- Package:\"$l_pn\" exists on the system"
  done
  # Check configuration (If applicable)
  if [ -n "$l_pkgoutput" ]; then
    l_output="" l_output2=""
    # Check if the idle-delay is locked
    if grep -Psrilq '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/; then
      if grep -Prilq '\/org\/gnome\/desktop\/session\/idle-delay\b' /etc/dconf/db/*/locks; then
        l_output="$l_output\n\t - \"idle-delay\" is locked"
      else
        l_output2="$l_output2\n\t - \"idle-delay\" is not locked"
      fi
    else
      l_output2="$l_output2\n\t - \"idle-delay\" is not set so it cannot be locked"
    fi
    # Check if the lock-delay is locked
    if grep -Psrilq '^\h*lock-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/; then
      if grep -Prilq '\/org\/gnome\/desktop\/screensaver\/lock-delay\b' /etc/dconf/db/*/locks; then
        l_output="$l_output\n\t - \"lock-delay\" is locked"
      else
        l_output2="$l_output2\n\t - \"lock-delay\" is not locked"
      fi
    else
      l_output2="$l_output2\n\t - \"lock-delay\" is not set so it cannot be locked"
    fi
  else
    l_output="$l_output\n\t - GNOME Desktop Manager package is not installed on the system\n\t   Recommendation is not applicable"
  fi
  # Report results. If no failures output in l_output2, we pass
  echo -e "\n- Audit for GDM screen lock override:"
  [ -n "$l_pkgoutput" ] && echo -e "$l_pkgoutput"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [GDM screen lock override] $l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [GDM screen lock override]\n\t- Reason(s) for audit failure: $l_output2 "
    [ -n "$l_output" ] && echo -e "\n\t- Correctly set:$l_output"
  fi
}

automount-chk() {
  echo -e "\n- Audit for GDM automounting of removable devices:"
  l_pkgoutput="" l_output="" l_output2=""
  # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is Not Applicable\n
  # determine system's package manager
  if command -v dpkg-query >/dev/null 2>&1; then
    l_pq="dpkg-query -s"
  elif command -v rpm >/dev/null 2>&1; then
    l_pq="rpm -q"
  fi
  # Check if GDM is installed
  l_pcl="gdm gdm3" # Space seporated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" >/dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\t- Package: \"$l_pn\" exists on the system"
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
    elif [ -f "$l_kfile2" ]; then
      l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile2")"
    fi
    # If the profile name exist, continue checks
    if [ -n "$l_gpname" ]; then
      l_gpdir="/etc/dconf/db/$l_gpname.d"
      # Check if profile file exists
      if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
        l_output="$l_output\n\t - dconf database profile file \"$(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\" exists"
      else
        l_output2="$l_output2\n\t - dconf database profile isn't set"
      fi
      # Check if the dconf database file exists
      if [ -f "/etc/dconf/db/$l_gpname" ]; then
        l_output="$l_output\n\t - The dconf database \"$l_gpname\" exists"
      else
        l_output2="$l_output2\n\t - The dconf database \"$l_gpname\" doesn't exist"
      fi
      # check if the dconf database directory exists
      if [ -d "$l_gpdir" ]; then
        l_output="$l_output\n\t - The dconf directory \"$l_gpdir\" exitst"
      else
        l_output2="$l_output2\n\t - The dconf directory \"$l_gpdir\" doesn't exist"
      fi
      # check automount setting
      if grep -Pqrs -- '^\h*automount\h*=\h*false\b' "$l_kfile"; then
        l_output="$l_output\n\t - \"automount\" is set to false in: \"$l_kfile\""
      else
        l_output2="$l_output2\n\t - \"automount\" is not set correctly"
      fi
      # check automount-open setting
      if grep -Pqs -- '^\h*automount-open\h*=\h*false\b' "$l_kfile2"; then
        l_output="$l_output\n\t - \"automount-open\" is set to false in: \"$l_kfile2\""
      else
        l_output2="$l_output2\n\t - \"automount-open\" is not set correctly"
      fi
    else
      # Setings don't exist. Nothing further to check
      l_output2="$l_output2\n\t - neither \"automount\" or \"automountopen\" is set"
    fi
  else
    l_output="$l_output\n\t - GNOME Desktop Manager package is not installed on the system\n\t - Recommendation is not applicable"
  fi
  # Report results. If no failures output in l_output2, we pass
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [gdm automounting configuring for removable devices] $l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [gdm automounting configuring for removable devices]\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:$l_output"
  fi
}

automount-override-chk(){
  # Check if GNOME Desktop Manager is installed.
  l_pkgoutput=""
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  l_pcl="gdm gdm3" # space-separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\t- Package: \"$l_pn\" exists on the system"
  done
  # Check for GDM configuration (If applicable)
  if [ -n "$l_pkgoutput" ]; then
    l_output=""
    l_output2=""
    # Search /etc/dconf/db/local.d/ for automount settings
    l_automount_setting=$(grep -Psir -- '^\h*automount=false\b' /etc/dconf/db/local.d/*)
    l_automount_open_setting=$(grep -Psir -- '^\h*automount-open=false\b' /etc/dconf/db/local.d/*)
    # Check for automount setting
    if [[ -n "$l_automount_setting" ]]; then
      l_output="$l_output\n\t - \"automount\" setting found"
    else
      l_output2="$l_output2\n\t - \"automount\" setting not found"
    fi
    # Check for automount-open setting
    if [[ -n "$l_automount_open_setting" ]]; then
      l_output="$l_output\n\t - \"automount-open\" setting found"
    else
      l_output2="$l_output2\n\t - \"automount-open\" setting not found"
    fi
  else
    l_output="$l_output\n\t - GNOME Desktop Manager package is not installed on the system\n\t - Recommendation is not applicable"
  fi
  # Report results. If no failures in l_output2, we pass
  echo -e "\n- Audit for GDM automount override of removable devices:"
  [ -n "$l_pkgoutput" ] && echo -e "$l_pkgoutput"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [gdm automount overridden for removable devices]$l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [gdm automount overridden for removable devices]\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:$l_output"
  fi
}

autorun-chk() {
  l_pkgoutput="" l_output="" l_output2=""
  # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is Not Applicable\n
  # determine system's package manager
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  # Check if GDM is installed
  l_pcl="gdm gdm3" # Space separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\t- Package:\"$l_pn\" exists on the system"
  done
  # Check configuration (If applicable)
  echo -e "\n- Audit for GDM autorun-never option:"
  if [ -n "$l_pkgoutput" ]; then
    echo -e "$l_pkgoutput"
    # Look for existing settings and set variables if they exist
    l_kfile="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d)"
    # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
    if [ -f "$l_kfile" ]; then
      l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<<"$l_kfile")"
    fi
    # If the profile name exist, continue checks
    if [ -n "$l_gpname" ]; then
      l_gpdir="/etc/dconf/db/$l_gpname.d"
      # Check if profile file exists
      if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
        l_output="$l_output\n\t - dconf database profile file \"$(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\" exists"
      else
        l_output2="$l_output2\n\t - dconf database profile isn't set"
      fi
      # Check if the dconf database file exists
      if [ -f "/etc/dconf/db/$l_gpname" ]; then
        l_output="$l_output\n\t - The dconf database \"$l_gpname\" exists"
      else
        l_output2="$l_output2\n\t - The dconf database \"$l_gpname\" doesn't exist"
      fi
      # check if the dconf database directory exists
      if [ -d "$l_gpdir" ]; then
        l_output="$l_output\n\t - The dconf directory \"$l_gpdir\" exitst"
      else
        l_output2="$l_output2\n\t - The dconf directory \"$l_gpdir\" doesn't exist"
      fi
      # check autorun-never setting
      if grep -Pqrs -- '^\h*autorun-never\h*=\h*true\b' "$l_kfile"; then
        l_output="$l_output\n\t - \"autorun-never\" is set to true in: \"$l_kfile\""
      else
        l_output2="$l_output2\n\t - \"autorun-never\" is not set correctly"
      fi
    else
      # Settings don't exist. Nothing further to check
      l_output2="$l_output2\n\t - \"autorun-never\" is not set"
    fi
  else
    l_output="$l_output\n\t - GNOME Desktop Manager package is not installed on the system\n\t - Recommendation is not applicable"
  fi
  # Report results. If no failures output in l_output2, we pass
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [gdm autorun-never]$l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [gdm autorun-never]\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:$l_output"
  fi
}

autorun-override-chk() {
  # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is Not Applicable\n
  # determine system's package manager
  l_pkgoutput=""
  if command -v dpkg-query &>/dev/null; then
    l_pq="dpkg-query -s"
  elif command -v rpm &>/dev/null; then
    l_pq="rpm -q"
  fi
  # Check if GDM is installed
  l_pcl="gdm gdm3" # Space separated list of packages to check
  for l_pn in $l_pcl; do
    $l_pq "$l_pn" &>/dev/null && l_pkgoutput="$l_pkgoutput\t- Package: \"$l_pn\" exists on the system"
  done
  # Search /etc/dconf/db/ for [org/gnome/desktop/media-handling] settings)
  l_desktop_media_handling=$(grep -Psir -- '^\h*\[org/gnome/desktop/mediahandling\]' /etc/dconf/db/*)
  if [[ -n "$l_desktop_media_handling" ]]; then
    l_output="" l_output2=""
    l_autorun_setting=$(grep -Psir -- '^\h*autorun-never=true\b' /etc/dconf/db/local.d/*)
    # Check for auto-run setting
    if [[ -n "$l_autorun_setting" ]]; then
      l_output="$l_output\n\t - \"autorun-never\" setting found"
    else
      l_output2="$l_output2\n\t - \"autorun-never\" setting not found"
    fi
  else
    l_output="$l_output\n\t - [org/gnome/desktop/media-handling] setting not found in /etc/dconf/db/*"
  fi
  # Report results. If no failures output in l_output2, we pass
  echo -e "\n- Audit for GDM autorun-never override option:"
  [ -n "$l_pkgoutput" ] && echo -e "$l_pkgoutput"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [gdm autorun-never overridden]$l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [gdm autorun-never overridden]\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:$l_output"
  fi
}

xdmcp-chk(){
  # while getopts 'n' flag;do 
  #   case ${flag} in 
  #     n) set -v; set -n ;;
  #   esac
  # done
  lol=$(while IFS= read -r l_file; do
    awk '/\[xdmcp\]/{ f = 1;next } /\[/{ f = 0 } f {if (/^\s*Enable\s*=\s*true/) print "The file: \"'"$l_file"'\" includes: \"" $0 "\" in the \"[xdmcp]\" block"}' "$l_file"
  done < <(grep -Psil -- '^\h*\[xdmcp\]' /etc/{gdm3,gdm}/{custom,daemon}.conf))

  echo -e "\n- Audit for GDM XDMCP option:"
  if [[ "$lol" -eq 0 ]]; then
    echo -e "\t# Audit Result: **PASS** [gdm XDMCP]"
  else 
    echo -e "\t# Audit Result: **FAIL** [gdm XDMCP]"
    echo -e "\t - Reason: $lol"
  fi
}

# while getopts 'n' flag;do 
#   case ${flag} in 
#     n) set -v; set -n ;;
#   esac
# done

echo -e "\n\nGDM Audits:"
banner-chk
user-list-chk
lock-chk
lock-override-chk
automount-chk
automount-override-chk
autorun-chk 
autorun-override-chk
xdmcp-chk
