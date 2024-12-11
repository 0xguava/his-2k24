#!/bin/bash

file-perm-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  file=$(echo "$@" | sed 's/.$//')
  fID=$(echo $@ | grep '[0-9]')

  userID=$(stat -Lc %u /etc/$file)
  groupID=$(stat -Lc %g /etc/$file)
  perm=$(stat -Lc %a /etc/$file)

  echo -e "\n- Access check for $file file:"
  if [[ "$userID" -eq 0 ]]; then
    output_p="$output_p\n\t - $file is owned by 'root' user."
  else
    output_f="$output_f\n\t - $file config file isn't owned by 'root' user."
    logvr=0
  fi

  if [[ "$groupID" -eq 0 ]]; then
    output_p="$output_p\n\t - $file is owned by 'root' group."
  else
    output_f="$output_f\n\t - $file isn't owned by 'root' group."
    logvr=0
  fi

  if [[ "$fID" -eq 1 ]]; then
    if [[ "$perm" -eq 644 ]]; then
      output_p="$output_p\n\t - Permissions on /etc/$file are configured correctly."
    else
      output_f="$output_f\n\t - Permissions on /etc/$file aren't configured correctly."
      logvr=0
    fi
  elif [[ "$fID" -eq 2 ]]; then
    if [[ "$perm" -eq 640 ]]; then
      output_p="$output_p\n\t - Permissions on /etc/$file are configured correctly."
    else
      output_f="$output_f\n\t - Permissions on /etc/$file aren't configured correctly."
      logvr=0
    fi
  fi

  if [[ "$logvr" -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Access to /etc/$file isn't configured properly]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [Access to /etc/$file is configured properly]"
    echo -e "\t- Reason: $output_p"
  fi
}

opasswd-chk(){
  local files=("/etc/security/opasswd" "/etc/security/opasswd.old")

  for file in "${files[@]}"; do
  echo -e "\n- Access check for $file file:"
    if [[ -e "$file" ]]; then
      userID=$(stat -Lc %u "$file")
      groupID=$(stat -Lc %g "$file")
      perm=$(stat -Lc %a "$file")

      if [[ "$userID" -eq 0 && "$groupID" -eq 0 && "$perm" -le 600 ]]; then
        echo -e "\t- Audit result: **PASS** [$file is owned by root and has correct permissions]"
      else
        echo -e "\t- Audit result: **FAIL** [$file does not meet ownership or permission requirements]"
        [[ "$userID" -ne 0 ]] && echo -e "\t  - Owner is not 'root'."
        [[ "$groupID" -ne 0 ]] && echo -e "\t  - Group is not 'root'."
        [[ "$perm" -gt 600 ]] && echo -e "\t  - Permissions are not restrictive enough."
      fi
    else
      echo -e "\t- Audit result: **PASS** [$file does not exist]"
    fi
  done
}

world-writable-chk(){
  local l_output="" l_output2=""
  local l_smask='01000'
  local a_file=() a_dir=() # Initialize arrays
  local a_path=( ! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/*" -a ! -path "/snap/*" )

  while IFS= read -r l_mount; do
    while IFS= read -r -d $'\0' l_file; do
      if [ -e "$l_file" ]; then
        [ -f "$l_file" ] && a_file+=("$l_file") # Add WR files
        if [ -d "$l_file" ]; then # Add directories w/o sticky bit
          l_mode="$(stat -Lc '%#a' "$l_file")"
          [ ! $(( $l_mode & $l_smask )) -gt 0 ] && a_dir+=("$l_file")
        fi
      fi
    done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2> /dev/null)
  done < <(findmnt -Dkerno fstype,target | awk '($1 !~  /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~  /^(\/run\/user\/|\/tmp|\/var\/tmp)/){print $2}')

  if ! (( ${#a_file[@]} > 0 )); then
    l_output="$l_output\n\t  - No world writable files exist on the local filesystem."
  else
    l_output2="$l_output2\n\t - There are \"$(printf '%s' "${#a_file[@]}")\" World writable files on the system.\n   - The following is a list of World writable files:\n$(printf '%s\n' "${a_file[@]}")\n   - end of list\n"
  fi

  if ! (( ${#a_dir[@]} > 0 )); then
    l_output="$l_output\n\t  - Sticky bit is set on world writable directories on the local filesystem."
  else
    l_output2="$l_output2\n\t - There are \"$(printf '%s' "${#a_dir[@]}")\" World writable directories without the sticky bit on the system.\n   - The following is a list of World writable directories without the sticky bit:\n$(printf '%s\n' "${a_dir[@]}")\n   - end of list\n"
  fi

  unset a_path; unset a_file; unset a_dir # Remove arrays

  # Logging results
  echo -e "\n- World Writable Files and Directories Check:"
  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit Result: **PASS** [No world writable files exists]\n\t- Correctly configured:$l_output"
  else
    echo -e "\t- Audit Result: **FAIL** [World writable files exists]\n\t- Reasons for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly configured:$l_output"
  fi
}

no-user-group-chk(){
  local l_output="" l_output2=""
  local a_nouser=() a_nogroup=() # Initialize arrays
  local a_path=( ! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/fs/cgroup/memory/*" -a ! -path "/var/*/private/*" )

  while IFS= read -r l_mount; do
    while IFS= read -r -d $'\0' l_file; do
      if [ -e "$l_file" ]; then
        while IFS=: read -r l_user l_group; do
          [ "$l_user" = "UNKNOWN" ] && a_nouser+=("$l_file")
          [ "$l_group" = "UNKNOWN" ] && a_nogroup+=("$l_file")
        done < <(stat -Lc '%U:%G' "$l_file")
      fi
    done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2> /dev/null)
  done < <(findmnt -Dkerno fstype,target | awk '($1 !~  /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~  /^\/run\/user\//){print $2}')

  if ! (( ${#a_nouser[@]} > 0 )); then
    l_output="$l_output\n\t  - No files or directories without an owner exist on the local filesystem."
  else
    l_output2="$l_output2\n\t  - There are \"$(printf '%s' "${#a_nouser[@]}")\" unowned files or directories on the system.\n   - The following is a list of unowned files and/or directories:\n$(printf '%s\n' "${a_nouser[@]}")"
  fi

  if ! (( ${#a_nogroup[@]} > 0 )); then
    l_output="$l_output\n\t  - No files or directories without a group exist on the local filesystem."
  else
    l_output2="$l_output2\n\t  - There are \"$(printf '%s' "${#a_nogroup[@]}")\" ungrouped files or directories on the system.\n   - The following is a list of ungrouped files and/or directories:\n$(printf '%s\n' "${a_nogroup[@]}")"
  fi

  echo -e "\n- No-User and No-Group Files Check:"
  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit Result: **PASS** [No unowned/ungrouped files or dirs exixts]\n\t- Correctly configured:$l_output"
  else
    echo -e "\t- Audit Result: **FAIL** [Unowned/Ungrouped files or dirs exixts]\n\t- Reasons for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly configured:$l_output"
  fi
}

suid_sgid_chk() {
  local l_output="" l_output2=""
  local a_suid=() a_sgid=() # Initialize arrays

  while IFS= read -r l_mount_point; do
    # Exclude specific paths and check for noexec option
    if ! grep -Pqs '[^\s]*/run/usr\b' <<< "$l_mount_point" && ! grep -Pqs '\bnoexec\b' <<< "$(findmnt -krn "$l_mount_point")"; then
      while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ]; then
          l_mode="$(stat -Lc '%#a' "$l_file")"
          [ $(( l_mode & 04000 )) -gt 0 ] && a_suid+=("$l_file")
          [ $(( l_mode & 02000 )) -gt 0 ] && a_sgid+=("$l_file")
        fi
      done < <(find "$l_mount_point" -xdev -type f \( -perm -2000 -o -perm -4000 \) -print0 2>/dev/null)
    fi
  done <<< "$(findmnt -Derno target)"

  if ! (( ${#a_suid[@]} > 0 )); then
    l_output="$l_output\n\t - [No executable SUID files exist on the system]"
  else
    l_output2="$l_output2\n\t - [List of \"$(printf '%s' "${#a_suid[@]}")\" SUID executable files]:\n$(printf '%s\n' "${a_suid[@]}")\n - [end of list] -\n"
  fi

  if ! (( ${#a_sgid[@]} > 0 )); then
    l_output="$l_output\n\t - [No SGID files exist on the system]"
  else
    l_output2="$l_output2\n\t - [List of \"$(printf '%s' "${#a_sgid[@]}")\" SGID executable files]:\n$(printf '%s\n' "${a_sgid[@]}")\n - [end of list] -\n"
  fi

  if [ -n "$l_output2" ]; then
    l_output2="$l_output2\n\t- [Review the preceding list(s) of SUID and/or SGID files to ensure that no rogue programs have been introduced onto the system.]\n"
  fi

  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit Result: **PASS** [MANUAL: No rouge SUID and SGID files are present]\n\t- Correctly configured:$l_output"
  else
    echo -e "\t- Audit Result: **FAIL** [MANUAL: SUID and SGID files are present *Verify it*]\n\t- Reasons for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly configured:$l_output"
  fi
}

files=('passwd1' 'passwd-1' 'group1' 'group-1' 'shadow2' 'shadow-2' 'gshadow2' 'gshadow-2' 'shells1')
for f in "${files[@]}"; do 
  file-perm-chk $f
done

opasswd-chk
world-writable-chk
no-user-group-chk
suid_sgid_chk
