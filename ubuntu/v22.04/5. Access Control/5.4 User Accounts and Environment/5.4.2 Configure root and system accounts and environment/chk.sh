#!/bin/bash

verify_root_user() {
  echo -e "- Verifying that only 'root' user has UID 0:"
  
  root_user_check=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd)

  if [[ "$root_user_check" == "root" ]]; then
    echo -e "\t- Audit result: **PASS** [Only 'root' has UID 0]"
  else
    echo -e "\t- Audit result: **FAIL** [Unexpected users with UID 0 found]"
    echo "$root_user_check"
  fi
}

# Check if root user has GID 0 and no other users have GID 0 as primary
verify_root_gid() {
  echo -e "- Verifying that root's primary GID is 0 and no other users have GID 0:"
  
  gid_check=$(awk -F: '($1 !~ /^(sync|shutdown|halt|operator)/ && $4=="0") {print $1":"$4}' /etc/passwd)

  if [[ "$gid_check" == "root:0" ]]; then
    echo -e "\t- Audit result: **PASS** [Only 'root' has GID 0]"
  else
    echo -e "\t- Audit result: **FAIL** [Other users have GID 0 as primary]"
    echo "$gid_check"
  fi
}

# Check if only 'root' has GID 0 and no other group has GID 0
verify_group_gid_zero() {
  echo -e "- Verifying that no group other than 'root' has GID 0:"
  
  group_check=$(awk -F: '$3=="0" {print $1":"$3}' /etc/group)

  if [[ "$group_check" == "root:0" ]]; then
    echo -e "\t- Audit result: **PASS** [Only 'root' has GID 0]"
  else
    echo -e "\t- Audit result: **FAIL** [Other groups have GID 0]"
    echo "$group_check"
  fi
}

# Check if the root user's password is set
verify_root_password() {
  echo -e "- Verifying that the root user's password is set:"
  
  root_password_status=$(passwd -S root | awk '$2 ~ /^P/ {print "User: \"" $1 "\" Password is set"}')

  if [[ -n "$root_password_status" ]]; then
    echo -e "\t- Audit result: **PASS** [$root_password_status]"
  else
    echo -e "\t- Audit result: **FAIL** [Root user's password is not set]"
  fi
}

{
  l_output2=""
  l_pmask="0022"
  l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"
  l_root_path="$(sudo -Hiu root env | grep '^PATH' | cut -d= -f2)"
  unset a_path_loc && IFS=":" read -ra a_path_loc <<< "$l_root_path"

  # Check for empty directories (::)
  grep -q "::" <<< "$l_root_path" && l_output2="$l_output2\n - root's path contains an empty directory (::)"

  # Check for trailing colons (:)
  grep -Pq ":\h*$" <<< "$l_root_path" && l_output2="$l_output2\n - root's path contains a trailing colon (:)"

  # Check for current working directory (.)
  grep -Pq '(\h+|:)\.(:|\h*$)' <<< "$l_root_path" && l_output2="$l_output2\n - root's path contains current working directory (.)"

  # Check each directory in root's PATH
  while read -r l_path; do
    if [ -d "$l_path" ]; then
      while read -r l_fmode l_fown; do
        [ "$l_fown" != "root" ] && l_output2="$l_output2\n - Directory: \"$l_path\" is owned by: \"$l_fown\", should be owned by \"root\""
        [ $(( $l_fmode & $l_pmask )) -gt 0 ] && l_output2="$l_output2\n - Directory: \"$l_path\" is mode: \"$l_fmode\", should be mode: \"$l_maxperm\" or more restrictive"
      done <<< "$(stat -Lc '%#a %U' "$l_path")"
    else
      l_output2="$l_output2\n - \"$l_path\" is not a directory"
    fi
  done <<< "$(printf "%s\n" "${a_path_loc[@]}")"

  # Final output based on audit results
  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n *** PASS ***\n - Root's path is correctly configured\n"
  else
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n"
  fi
}
# Check the root user's umask setting
verify_root_umask() {
  echo -e "- Verifying the root user's umask setting:"

  # Check if umask value is properly set
  umask_check=$(grep -Psi -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' /root/.bash_profile /root/.bashrc)

  if [[ -z "$umask_check" ]]; then
    echo -e "\t- Audit result: **PASS** [No issues with the root user's umask setting]"
  else
    echo -e "\t- Audit result: **FAIL** [Improper umask setting detected]"
  fi
}

verify_root_user
verify_root_gid
verify_group_gid_zero
verify_root_password
verify_root_umask
