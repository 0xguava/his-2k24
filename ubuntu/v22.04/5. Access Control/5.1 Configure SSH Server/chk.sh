#!/bin/bash

sshd-perm() {
  # Initialize variables for log storage
  l_output=""
  l_output2=""
  perm_mask='0177'
  maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"

  # Function to check file permissions, owner, and group ownership
  SSHD_FILES_CHK() {
    while IFS=: read -r l_mode l_user l_group; do
      l_out2=""

      # Check if mode is not 0600 or more restrictive
      [ $(($l_mode & $perm_mask)) -gt 0 ] && l_out2="$l_out2\n\t  - File: \"$l_file\" has mode: \"$l_mode\", should be: \"$maxperm\" or more restrictive"

      # Check if owner is not root
      [ "$l_user" != "root" ] && l_out2="$l_out2\n\t - File: \"$l_file\" is owned by: \"$l_user\", should be owned by \"root\""

      # Check if group is not root
      [ "$l_group" != "root" ] && l_out2="$l_out2\n\t - File: \"$l_file\" group owned by: \"$l_group\", should be group owned by \"root\""

      # Log the result
      if [ -n "$l_out2" ]; then
        l_output2="$l_output2\n\t - File: \"$l_file\":$l_out2"
      else
        l_output="$l_output\n\t - File: \"$l_file\":\n  - Correct: mode ($l_mode), owner ($l_user), and group owner ($l_group) configured"
      fi
    done < <(stat -Lc '%#a:%U:%G' "$l_file")
  }

  # Check /etc/ssh/sshd_config file
  if [ -e "/etc/ssh/sshd_config" ]; then
    l_file="/etc/ssh/sshd_config"
    SSHD_FILES_CHK
  fi

  # Check .conf files in /etc/ssh/sshd_config.d
  while IFS= read -r -d $'\0' l_file; do
    [ -e "$l_file" ] && SSHD_FILES_CHK
  done < <(find /etc/ssh/sshd_config.d -type f -name '*.conf' -perm /077 -o ! -user root -o ! -group root -print0 2>/dev/null)

  # Check if the /etc/ssh/sshd_config file includes other locations
  if grep -q 'Include' /etc/ssh/sshd_config; then
    included_files=$(grep 'Include' /etc/ssh/sshd_config | awk '{print $2}')
    for include in $included_files; do
      if [ -d "$include" ]; then
        while IFS= read -r -d $'\0' l_file; do
          [ -e "$l_file" ] && SSHD_FILES_CHK
        done < <(find "$include" -type f -name '*.conf' -perm /077 -o ! -user root -o ! -group root -print0 2>/dev/null)
      fi
    done
  fi

  # Output final audit result
  echo -e "\n- Permission check on /etc/ssh/sshd_config"
  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit result: **PASS** [Permissions on /etc/ssh/sshd_config are correct]\n\t- Correctly configured:$l_output"
  else
    echo -e "\t- Audit result: **FAIL** [Permissions on /etc/ssh/sshd_config are not correct]\n\t- Reasons for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly configured:$l_output"
  fi
}

pub-hostkey(){
  echo -e "\n\t Audit for permissions on SSH public host key files :"
  l_output="" l_output2=""
  l_pmask="0133" && l_maxperm="$(printf '%o' $((0777 & ~$l_pmask)))"
  FILE_CHK() {
    while IFS=: read -r l_file_mode l_file_owner l_file_group; do
      l_out2=""
      if [ $(($l_file_mode & $l_pmask)) -gt 0 ]; then
        l_out2="$l_out2\n - Mode: \"$l_file_mode\" should be mode:\"$l_maxperm\" or more restrictive"
      fi
      if [ "$l_file_owner" != "root" ]; then
        l_out2="$l_out2\n - Owned by: \"$l_file_owner\" should be owned by \"root\""
      fi
      if [ "$l_file_group" != "root" ]; then
        l_out2="$l_out2\n - Owned by group \"$l_file_group\" should be group owned by group: \"root\""
      fi
      if [ -n "$l_out2" ]; then
        l_output2="$l_output2\n\t- File: \"$l_file\"$l_out2"
      else
        l_output="$l_output\n\t - File: \"$l_file\"\n\t - Correct: mode:\"$l_file_mode\", owner: \"$l_file_owner\", and group owner:\"$l_file_group\" configured"
      fi
    done < <(stat -Lc '%#a:%U:%G' "$l_file")
  }
  while IFS= read -r -d $'\0' l_file; do
    if ssh-keygen -lf "$l_file" &>/dev/null; then
      file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?public\h+key\b' && FILE_CHK
    fi
  done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)
  if [ -z "$l_output2" ]; then
    [ -z "$l_output" ] && l_output="\n - No openSSH public keys found"
    echo -e "\n\t - Audit Result: ** PASS ** [permissions on SSH public host key files]\n\t - * Correctly configured * :$l_output"
  else
    echo -e "\n\t- Audit Result: ** FAIL ** [permissions on SSH public host key files]\n\t - * Reasons for audit failure * :$l_output2\n"
    [ -n "$l_output" ] && echo -e "\n\t - * Correctly configured *:\n$l_output\n"
  fi
}

sshd-acc() {
  echo -e "- SSHD configuration check for allowed/denied users/groups:"

  # Run the SSHD configuration check and store the result
  sshd_output=$(sshd -T | grep -Pi -- '^\h*(allow|deny)(users|groups)\h+\H+')

  # Check if any match was found
  if [[ -n "$sshd_output" ]]; then
    echo -e "\t- Audit result: **PASS** [Valid allow/deny users/groups configurations found]"
    echo -e "\t- Configuration details:"
    echo -e "$sshd_output"
  else
    echo -e "\t- Audit result: **FAIL** [No valid allow/deny users/groups configurations found]"
    echo -e "\t- Reason: No entries for 'allowusers', 'allowgroups', 'denyusers', or 'denygroups' found in the SSHD configuration."
  fi

  # If match set statements are used, check with user-specific parameters
  # Assuming you want to audit for a specific user (example: sshuser)
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -Pi -- '^\h*(allow|deny)(users|groups)\h+\H+')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **PASS** [Valid configuration for user '$user_check']"
    echo -e "\t  Configuration details:"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No valid configuration for user '$user_check']"
    echo -e "\t  Reason: No entries for 'allowusers', 'allowgroups', 'denyusers', or 'denygroups' found for user '$user_check'."
  fi
}

banner-chk() {
  echo -e "- SSH Banner configuration check:"

  # Run the SSHD configuration check and store the result for 'banner' setting
  banner_output=$(sshd -T | grep -Pi -- '^banner\h+\/\H+')

  # Check if any banner setting is found
  if [[ -n "$banner_output" ]]; then
    echo -e "\t- Audit result: **PASS** [Banner is set correctly]"
    echo -e "\t- Configuration details:"
    echo -e "$banner_output"
  else
    echo -e "\t- Audit result: **FAIL** [No Banner setting found]"
    echo -e "\t- Reason: Banner is not configured in the SSHD configuration."
  fi

  # If match set statements are used, check with user-specific parameters
  # Example user: sshuser
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -Pi -- '^banner\h+\/\H+')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **PASS** [Banner is set correctly for user '$user_check']"
    echo -e "\t  Configuration details:"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No Banner setting for user '$user_check']"
    echo -e "\t  Reason: Banner is not configured for user '$user_check'."
  fi
}

ciphers-chk() {
  echo -e "- SSH Ciphers configuration check:"

  # Run the SSHD configuration check for weak ciphers
  weak_ciphers_output=$(sshd -T | grep -Pi -- '^ciphers\h+' | grep -Pi -- '3des-cbc|aes128-cbc|aes192-cbc|aes256-cbc|blowfish|cast128|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se')

  # Check if any weak ciphers are found
  if [[ -n "$weak_ciphers_output" ]]; then
    echo -e "\t- Audit result: **FAIL** [Weak ciphers found in SSH configuration]"
    echo -e "\t- Weak ciphers detected:"
    echo -e "$weak_ciphers_output"
  else
    echo -e "\t- Audit result: **PASS** [No weak ciphers found in SSH configuration]"
  fi

  # Check for the presence of chacha20-poly1305@openssh.com and CVE-2023-48795
  chacha_check=$(sshd -T | grep -Pi -- '^ciphers\h+' | grep -Pi -- 'chacha20-poly1305@openssh\.com')

  if [[ -n "$chacha_check" ]]; then
    echo -e "\t  **WARNING**: The cipher 'chacha20-poly1305@openssh.com' is detected. Please review CVE-2023-48795 and ensure the system is patched."
  fi
}

clientalive-chk() {
  echo -e "- SSH ClientAlive settings check:"

  # Run the SSHD configuration check for ClientAliveInterval and ClientAliveCountMax
  clientalive_output=$(sshd -T | grep -Pi -- '(clientaliveinterval|clientalivecountmax)')

  # Check if both settings are present and greater than zero
  if [[ -n "$clientalive_output" ]]; then
    # Extract the values of ClientAliveInterval and ClientAliveCountMax
    clientalive_interval=$(echo "$clientalive_output" | grep -Pi -- 'clientaliveinterval' | awk '{print $2}')
    clientalive_countmax=$(echo "$clientalive_output" | grep -Pi -- 'clientalivecountmax' | awk '{print $2}')

    # Verify if both values are greater than zero
    if [[ "$clientalive_interval" -gt 0 && "$clientalive_countmax" -gt 0 ]]; then
      echo -e "\t- Audit result: **PASS** [ClientAlive settings are properly configured]"
      echo -e "\t  clientaliveinterval: $clientalive_interval"
      echo -e "\t  clientalivecountmax: $clientalive_countmax"
    else
      echo -e "\t- Audit result: **FAIL** [ClientAlive settings are not properly configured]"
      if [[ "$clientalive_interval" -le 0 ]]; then
        echo -e "\t  Reason: clientaliveinterval is set to $clientalive_interval (should be greater than 0)"
      fi
      if [[ "$clientalive_countmax" -le 0 ]]; then
        echo -e "\t  Reason: clientalivecountmax is set to $clientalive_countmax (should be greater than 0)"
      fi
    fi
  else
    echo -e "\t- Audit result: **FAIL** [ClientAlive settings not found in SSH configuration]"
    echo -e "\t  Reason: clientaliveinterval or clientalivecountmax not configured."
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -Pi -- '(clientaliveinterval|clientalivecountmax)')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No ClientAlive settings for user '$user_check']"
    echo -e "\t  Reason: clientaliveinterval or clientalivecountmax not configured for user '$user_check'."
  fi
}

disableforwarding-chk() {
  echo -e "- SSH DisableForwarding setting check:"

  # Run the SSHD configuration check for DisableForwarding
  disableforwarding_output=$(sshd -T | grep -i -- 'disableforwarding')

  # Check if the DisableForwarding is set to 'yes'
  if [[ -n "$disableforwarding_output" && "$disableforwarding_output" == *"yes"* ]]; then
    echo -e "\t- Audit result: **PASS** [DisableForwarding is set to 'yes']"
  else
    echo -e "\t- Audit result: **FAIL** [DisableForwarding is not set to 'yes']"
    if [[ -n "$disableforwarding_output" ]]; then
      echo -e "\t  Current setting: $disableforwarding_output"
    else
      echo -e "\t  Reason: DisableForwarding is not configured."
    fi
  fi
}

gssapiauthentication-chk() {
  echo -e "- SSH GSSAPIAuthentication setting check:"

  # Run the SSHD configuration check for GSSAPIAuthentication
  gssapiauthentication_output=$(sshd -T | grep -i -- 'gssapiauthentication')

  # Check if the GSSAPIAuthentication is set to 'no'
  if [[ -n "$gssapiauthentication_output" && "$gssapiauthentication_output" == *"no"* ]]; then
    echo -e "\t- Audit result: **PASS** [GSSAPIAuthentication is set to 'no']"
  else
    echo -e "\t- Audit result: **FAIL** [GSSAPIAuthentication is not set to 'no']"
    if [[ -n "$gssapiauthentication_output" ]]; then
      echo -e "\t  Current setting: $gssapiauthentication_output"
    else
      echo -e "\t  Reason: GSSAPIAuthentication is not configured."
    fi
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'gssapiauthentication')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No GSSAPIAuthentication setting for user '$user_check']"
    echo -e "\t  Reason: GSSAPIAuthentication not configured for user '$user_check'."
  fi
}

hostbasedauthentication-chk() {
  echo -e "- SSH HostbasedAuthentication setting check:"

  # Run the SSHD configuration check for HostbasedAuthentication
  hostbasedauthentication_output=$(sshd -T | grep -i -- 'hostbasedauthentication')

  # Check if the HostbasedAuthentication is set to 'no'
  if [[ -n "$hostbasedauthentication_output" && "$hostbasedauthentication_output" == *"no"* ]]; then
    echo -e "\t- Audit result: **PASS** [HostbasedAuthentication is set to 'no']"
  else
    echo -e "\t- Audit result: **FAIL** [HostbasedAuthentication is not set to 'no']"
    if [[ -n "$hostbasedauthentication_output" ]]; then
      echo -e "\t  Current setting: $hostbasedauthentication_output"
    else
      echo -e "\t  Reason: HostbasedAuthentication is not configured."
    fi
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'hostbasedauthentication')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No HostbasedAuthentication setting for user '$user_check']"
    echo -e "\t  Reason: HostbasedAuthentication not configured for user '$user_check'."
  fi
}

ignorerhosts-chk() {
  echo -e "- SSH IgnoreRhosts setting check:"

  # Run the SSHD configuration check for IgnoreRhosts
  ignorerhosts_output=$(sshd -T | grep -i -- 'ignorerhosts')

  # Check if the IgnoreRhosts is set to 'yes'
  if [[ -n "$ignorerhosts_output" && "$ignorerhosts_output" == *"yes"* ]]; then
    echo -e "\t- Audit result: **PASS** [IgnoreRhosts is set to 'yes']"
  else
    echo -e "\t- Audit result: **FAIL** [IgnoreRhosts is not set to 'yes']"
    if [[ -n "$ignorerhosts_output" ]]; then
      echo -e "\t  Current setting: $ignorerhosts_output"
    else
      echo -e "\t  Reason: IgnoreRhosts is not configured."
    fi
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'ignorerhosts')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No IgnoreRhosts setting for user '$user_check']"
    echo -e "\t  Reason: IgnoreRhosts not configured for user '$user_check'."
  fi
}

kexalgorithms-chk() {
  echo -e "- SSH Key Exchange Algorithms check:"

  # Run the SSHD configuration check for Key Exchange algorithms
  kexalgorithms_output=$(sshd -T | grep -Pi -- 'kexalgorithms\h+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b')

  # Check if any weak Key Exchange algorithms are present
  if [[ -n "$kexalgorithms_output" ]]; then
    echo -e "\t- Audit result: **FAIL** [Weak Key Exchange algorithms found]"
    echo -e "\t  Weak Key Exchange algorithms in use: $kexalgorithms_output"
  else
    echo -e "\t- Audit result: **PASS** [No weak Key Exchange algorithms are in use]"
  fi
}

logingracetime-chk() {
  echo -e "- SSH LoginGraceTime check:"

  # Run the SSHD configuration check for LoginGraceTime
  logingracetime_output=$(sshd -T | grep -i -- 'logingracetime')

  # Extract the value of LoginGraceTime
  if [[ -n "$logingracetime_output" ]]; then
    login_gracetime_value=$(echo "$logingracetime_output" | awk '{print $2}')

    # Check if the value is between 1 and 60 seconds
    if [[ "$login_gracetime_value" -ge 1 && "$login_gracetime_value" -le 60 ]]; then
      echo -e "\t- Audit result: **PASS** [LoginGraceTime is within the allowed range (1-60 seconds)]"
    else
      echo -e "\t- Audit result: **FAIL** [LoginGraceTime is outside the allowed range]"
      echo -e "\t  Current LoginGraceTime value: $login_gracetime_value seconds"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [LoginGraceTime is not configured]"
  fi
}

loglevel-chk() {
  echo -e "- SSH LogLevel check:"

  # Run the SSHD configuration check for LogLevel
  loglevel_output=$(sshd -T | grep -i -- 'loglevel')

  # Extract the LogLevel value and check if it matches "VERBOSE" or "INFO"
  if [[ -n "$loglevel_output" ]]; then
    loglevel_value=$(echo "$loglevel_output" | awk '{print $2}')

    # Check if the value is either VERBOSE or INFO
    if [[ "$loglevel_value" == "VERBOSE" || "$loglevel_value" == "INFO" ]]; then
      echo -e "\t- Audit result: **PASS** [LogLevel is set to '$loglevel_value']"
    else
      echo -e "\t- Audit result: **FAIL** [LogLevel is not set to 'VERBOSE' or 'INFO']"
      echo -e "\t  Current LogLevel value: $loglevel_value"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [LogLevel is not configured]"
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'loglevel')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No LogLevel setting for user '$user_check']"
    echo -e "\t  Reason: LogLevel not configured for user '$user_check'."
  fi
}

macs-chk() {
  echo -e "- SSH MACs check:"

  # Run the SSHD configuration check for MACs
  macs_output=$(sshd -T | grep -Pi -- 'macs\h+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b')

  # Check if any weak MACs are found
  if [[ -n "$macs_output" ]]; then
    echo -e "\t- Audit result: **FAIL** [Weak MACs found]"
    echo -e "\t  Weak MACs in use: $macs_output"
  else
    echo -e "\t- Audit result: **PASS** [No weak MACs are in use]"
  fi
}

maxauthtries-chk() {
  echo -e "- SSH MaxAuthTries check:"

  # Run the SSHD configuration check for MaxAuthTries
  maxauthtries_output=$(sshd -T | grep -i -- 'maxauthtries')

  # Extract the MaxAuthTries value
  if [[ -n "$maxauthtries_output" ]]; then
    maxauthtries_value=$(echo "$maxauthtries_output" | awk '{print $2}')

    # Check if the value is 4 or less
    if [[ "$maxauthtries_value" -le 4 ]]; then
      echo -e "\t- Audit result: **PASS** [MaxAuthTries is set to '$maxauthtries_value']"
    else
      echo -e "\t- Audit result: **FAIL** [MaxAuthTries is greater than 4]"
      echo -e "\t  Current MaxAuthTries value: $maxauthtries_value"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [MaxAuthTries is not configured]"
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'maxauthtries')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No MaxAuthTries setting for user '$user_check']"
    echo -e "\t  Reason: MaxAuthTries not configured for user '$user_check'."
  fi
}

maxsessions-chk() {
  echo -e "- SSH MaxSessions check:"

  # Run the SSHD configuration check for MaxSessions
  maxsessions_output=$(sshd -T | grep -i -- 'maxsessions')

  # Extract the MaxSessions value
  if [[ -n "$maxsessions_output" ]]; then
    maxsessions_value=$(echo "$maxsessions_output" | awk '{print $2}')

    # Check if the value is 10 or less
    if [[ "$maxsessions_value" -le 10 ]]; then
      echo -e "\t- Audit result: **PASS** [MaxSessions is set to '$maxsessions_value']"
    else
      echo -e "\t- Audit result: **FAIL** [MaxSessions is greater than 10]"
      echo -e "\t  Current MaxSessions value: $maxsessions_value"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [MaxSessions is not configured]"
  fi

  # Check for any MaxSessions values greater than 10 in the sshd config files
  grep_output=$(grep -Psi -- '^\h*MaxSessions\h+\"?(1[1-9]|[2-9][0-9]|[1-9][0-9][0-9]+)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf)

  if [[ -n "$grep_output" ]]; then
    echo -e "\t- Audit result: **FAIL** [MaxSessions is set to a value greater than 10 in the config files]"
    echo -e "\t  Config file(s) with MaxSessions > 10: $grep_output"
  else
    echo -e "\t- Audit result: **PASS** [No MaxSessions values greater than 10 found in the config files]"
  fi

  # If match set statements are used, check with user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'maxsessions')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No MaxSessions setting for user '$user_check']"
    echo -e "\t  Reason: MaxSessions not configured for user '$user_check'."
  fi
}

maxstartups-chk() {
  echo -e "- SSH MaxStartups check:"

  # Run the SSHD configuration check for MaxStartups and validate if it is set to 10:30:60 or more restrictive
  maxstartups_output=$(sshd -T | awk '$1 ~ /^\s*maxstartups/{split($2, a, ":");{if(a[1] > 10 || a[2] > 30 || a[3] > 60) print $0}}')

  if [[ -n "$maxstartups_output" ]]; then
    echo -e "\t- Audit result: **FAIL** [MaxStartups is not set to '10:30:60' or more restrictive]"
    echo -e "\t  Current MaxStartups value: $maxstartups_output"
  else
    echo -e "\t- Audit result: **PASS** [MaxStartups is set to '10:30:60' or more restrictive]"
  fi
}

permitemptypasswords-chk() {
  echo -e "- SSH PermitEmptyPasswords check:"

  # Run the SSHD configuration check for PermitEmptyPasswords
  permitemptypasswords_output=$(sshd -T | grep -i -- 'permitemptypasswords')

  # Check if the PermitEmptyPasswords is set to "no"
  if [[ -n "$permitemptypasswords_output" ]]; then
    if [[ "$permitemptypasswords_output" =~ "permitemptypasswords no" ]]; then
      echo -e "\t- Audit result: **PASS** [PermitEmptyPasswords is set to 'no']"
    else
      echo -e "\t- Audit result: **FAIL** [PermitEmptyPasswords is not set to 'no']"
      echo -e "\t  Current setting: $permitemptypasswords_output"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [PermitEmptyPasswords is not configured]"
  fi

  # If match set statements are used, check for user-specific parameters
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'permitemptypasswords')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No PermitEmptyPasswords setting for user '$user_check']"
    echo -e "\t  Reason: PermitEmptyPasswords not configured for user '$user_check'."
  fi
}

permitrootlogin-chk() {
  echo -e "- SSH PermitRootLogin check:"

  # Run the SSHD configuration check for PermitRootLogin
  permitrootlogin_output=$(sshd -T | grep -i -- 'permitrootlogin')

  # Check if PermitRootLogin is set to "no"
  if [[ -n "$permitrootlogin_output" ]]; then
    if [[ "$permitrootlogin_output" =~ "permitrootlogin no" ]]; then
      echo -e "\t- Audit result: **PASS** [PermitRootLogin is set to 'no']"
    else
      echo -e "\t- Audit result: **FAIL** [PermitRootLogin is not set to 'no']"
      echo -e "\t  Current setting: $permitrootlogin_output"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [PermitRootLogin is not configured]"
  fi

  # Check for Match block statements for a specific user
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'permitrootlogin')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No PermitRootLogin setting for user '$user_check']"
    echo -e "\t  Reason: PermitRootLogin not configured for user '$user_check'."
  fi
}

permituserenvironment-chk() {
  echo -e "- SSH PermitUserEnvironment check:"

  # Run the SSHD configuration check for PermitUserEnvironment
  permituserenvironment_output=$(sshd -T | grep -i -- 'permituserenvironment')

  # Check if PermitUserEnvironment is set to "no"
  if [[ -n "$permituserenvironment_output" ]]; then
    if [[ "$permituserenvironment_output" =~ "permituserenvironment no" ]]; then
      echo -e "\t- Audit result: **PASS** [PermitUserEnvironment is set to 'no']"
    else
      echo -e "\t- Audit result: **FAIL** [PermitUserEnvironment is not set to 'no']"
      echo -e "\t  Current setting: $permituserenvironment_output"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [PermitUserEnvironment is not configured]"
  fi

  # Check for Match block statements for a specific user
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'permituserenvironment')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No PermitUserEnvironment setting for user '$user_check']"
    echo -e "\t  Reason: PermitUserEnvironment not configured for user '$user_check'."
  fi
}

usepam-chk() {
  echo -e "- SSH UsePAM check:"

  # Run the SSHD configuration check for UsePAM
  usepam_output=$(sshd -T | grep -i -- 'usepam')

  # Check if UsePAM is set to "yes"
  if [[ -n "$usepam_output" ]]; then
    if [[ "$usepam_output" =~ "usepam yes" ]]; then
      echo -e "\t- Audit result: **PASS** [UsePAM is set to 'yes']"
    else
      echo -e "\t- Audit result: **FAIL** [UsePAM is not set to 'yes']"
      echo -e "\t  Current setting: $usepam_output"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [UsePAM is not configured]"
  fi

  # Check for Match block statements for a specific user
  user_check="sshuser"
  match_check=$(sshd -T -C user="$user_check" | grep -i -- 'usepam')

  if [[ -n "$match_check" ]]; then
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  Configuration for user '$user_check':"
    echo -e "$match_check"
  else
    echo -e "\t- Additional audit for user '$user_check':"
    echo -e "\t  **FAIL** [No UsePAM setting for user '$user_check']"
    echo -e "\t  Reason: UsePAM not configured for user '$user_check'."
  fi
}


sshd-perm
pub-hostkey
sshd-acc
banner-chk
ciphers-chk
clientalive-chk
gssapiauthentication-chk
hostbasedauthentication-chk
ignorerhosts-chk
kexalgorithms-chk
logingracetime-chk
loglevel-chk
macs-chk
maxauthtries-chk
maxsessions-chk
maxstartups-chk
permitemptypasswords-chk
permitrootlogin-chk
permituserenvironment-chk
usepam-chk
