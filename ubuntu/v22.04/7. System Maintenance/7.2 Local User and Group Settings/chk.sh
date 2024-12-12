#!/bin/bash

verify_shadowed_passwords() {
  echo -e "\n- Verifying if all users have shadowed passwords set:"

  local result=$(awk -F: '($2 != "x" ) { print "User: \"" $1 "\" is not set to shadowed passwords" }' /etc/passwd)

  if [[ -z "$result" ]]; then
    echo -e "\t- Audit result: **PASS** [All users are set to shadowed passwords]"
  else
    echo -e "\t- Audit result: **FAIL** [Some users do not have shadowed passwords set]:"
    echo -e "$result"
  fi
}

password-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- Password check for users without passwords:"
  result=$(awk -F: '($2 == "" ) { print $1 " does not have a password "}' /etc/shadow)

  if [[ -z "$result" ]]; then
    output_p="\t - No users without passwords found."
  else
    output_f="\t - Users without passwords: \n$result"
    logvr=0
  fi

  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [There are users without passwords]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [All users have passwords]"
    echo -e "\t- Reason: $output_p"
  fi
}

gid-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- GID check for users in /etc/passwd against /etc/group:"
  
  # Get unique GIDs from /etc/passwd and /etc/group
  a_passwd_group_gid=("$(awk -F: '{print $4}' /etc/passwd | sort -u)")
  a_group_gid=("$(awk -F: '{print $3}' /etc/group | sort -u)")
  
  # Find GIDs that are in /etc/passwd but not in /etc/group
  a_passwd_group_diff=("$(printf '%s\n' "${a_group_gid[@]}" "${a_passwd_group_gid[@]}" | sort | uniq -u)")
  
  # Check for any discrepancies
  result=$(printf '%s\n' "${a_passwd_group_gid[@]}" "${a_passwd_group_diff[@]}" | sort | uniq -D | uniq)
  
  if [[ -z "$result" ]]; then
    output_p="\t - All GIDs in /etc/passwd exist in /etc/group."
  else
    output_f="\t - The following GIDs from /etc/passwd do not exist in /etc/group: \n$result"
    logvr=0
  fi

  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Some GIDs in /etc/passwd do not exist in /etc/group]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [All GIDs in /etc/passwd exist in /etc/group]"
    echo -e "\t- Reason: $output_p"
  fi

  # Clean up variables
  unset a_passwd_group_gid
  unset a_group_gid
  unset a_passwd_group_diff
}

shadow-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- Check if 'shadow' group has no users assigned and if users with the 'shadow' group as primary group exist:"

  # Check if the 'shadow' group has any members
  shadow_group_users=$(awk -F: '($1=="shadow") {print $NF}' /etc/group)
  
  if [[ -z "$shadow_group_users" ]]; then
    output_p="\t - No users are assigned to the 'shadow' group."
  else
    output_f="\t - The following users are assigned to the 'shadow' group: $shadow_group_users"
    logvr=0
  fi

  # Check if any user has 'shadow' as their primary group
  shadow_gid=$(getent group shadow | awk -F: '{print $3}' | xargs)
  shadow_group_users_primary=$(awk -F: '($4 == '"$shadow_gid"') {print "  - User: \"" $1 "\" has 'shadow' as their primary group"}' /etc/passwd)

  if [[ -z "$shadow_group_users_primary" ]]; then
    output_p="$output_p\n\t - No user has 'shadow' as their primary group."
  else
    output_f="$output_f\n\t - The following users have 'shadow' as their primary group: $shadow_group_users_primary"
    logvr=0
  fi

  # Final audit result
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [The 'shadow' group is misconfigured]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [The 'shadow' group is properly configured]"
    echo -e "\t- Reason: $output_p"
  fi
}

uid-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- Duplicate UID check for users in /etc/passwd:"

  # Find duplicate UIDs
  while read -r l_count l_uid; do
    if [ "$l_count" -gt 1 ]; then
      users_with_duplicate_uid=$(awk -F: '($3 == n) {print $1}' n=$l_uid /etc/passwd | xargs)
      
      output_f="$output_f\n\t - Duplicate UID: \"$l_uid\" Users: \"$users_with_duplicate_uid\""
      logvr=0
    fi
  done < <(cut -f3 -d":" /etc/passwd | sort -n | uniq -c)

  # Check results and log accordingly
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Duplicate UIDs found]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [No duplicate UIDs found]"
    echo -e "\t- Reason: $output_p"
  fi
}

gid-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- Duplicate GID check for groups in /etc/group:"

  # Find duplicate GIDs
  while read -r l_count l_gid; do
    if [ "$l_count" -gt 1 ]; then
      groups_with_duplicate_gid=$(awk -F: '($3 == n) {print $1}' n=$l_gid /etc/group | xargs)
      
      output_f="$output_f\n\t - Duplicate GID: \"$l_gid\" Groups: \"$groups_with_duplicate_gid\""
      logvr=0
    fi
  done < <(cut -f3 -d":" /etc/group | sort -n | uniq -c)

  # Check results and log accordingly
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Duplicate GIDs found]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [No duplicate GIDs found]"
    echo -e "\t- Reason: $output_p"
  fi
}

user-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- Duplicate User check for groups in /etc/group:"

  # Find duplicate users
  while read -r l_count l_user; do
    if [ "$l_count" -gt 1 ]; then
      users_with_duplicate_user=$(awk -F: '($1 == n) {print $1}' n=$l_user /etc/passwd | xargs)
      
      output_f="$output_f\n\t - Duplicate User: \"$l_user\" Users: \"$users_with_duplicate_user\""
      logvr=0
    fi
  done < <(cut -f1 -d":" /etc/group | sort -n | uniq -c)

  # Check results and log accordingly
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Duplicate users found]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [No duplicate users found]"
    echo -e "\t- Reason: $output_p"
  fi
}

group-chk(){
  local output_p=''
  local output_f=''
  local logvr=1

  echo -e "\n- Duplicate Group check in /etc/group:"

  # Find duplicate groups
  while read -r l_count l_group; do
    if [ "$l_count" -gt 1 ]; then
      groups_with_duplicate_group=$(awk -F: '($1 == n) {print $1}' n=$l_group /etc/group | xargs)
      
      output_f="$output_f\n\t - Duplicate Group: \"$l_group\" Groups: \"$groups_with_duplicate_group\""
      logvr=0
    fi
  done < <(cut -f1 -d":" /etc/group | sort -n | uniq -c)

  # Check results and log accordingly
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Duplicate groups found]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [No duplicate groups found]"
    echo -e "\t- Reason: $output_p"
  fi
}

home_dir_check(){
  echo -e "\n- Home directory checks for local interactive users:"

  local l_output=""
  local l_output2=""
  local l_heout2=""
  local l_hoout2=""
  local l_haout2=""

  local l_valid_shells="^($( awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\/,g;p}' | paste -s -d '|' - ))$"
  unset a_uarr && a_uarr=()

  # Populate array with users and user home location
  while read -r l_epu l_eph; do
    a_uarr+=("$l_epu $l_eph")
  done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " "  $(NF-1) }' /etc/passwd)"

  local l_asize="${#a_uarr[@]}"

  # Log if the user count is large
  if [ "$l_asize" -gt "10000" ]; then
    echo -e "\t- ** INFO **\n\t- "$l_asize" local interactive users found on the system.\n\t- This may be a long-running check."
  fi

  while read -r l_user l_home; do
    if [ -d "$l_home" ]; then
      local l_mask='0027'
      local l_max="$( printf '%o' $(( 0777 & ~$l_mask)) )"

      while read -r l_own l_mode; do
        if [ "$l_user" != "$l_own" ]; then
          l_hoout2="$l_hoout2\n\t- User: "$l_user" Home "$l_home" is owned by: "$l_own""
        fi

        if [ $(( $l_mode & $l_mask )) -gt 0 ]; then
          l_haout2="$l_haout2\n\t- User: "$l_user" Home "$l_home" is mode: "$l_mode" should be mode: "$l_max" or more restrictive"
        fi
      done <<< "$(stat -Lc '%U %#a' "$l_home")"
    else
      l_heout2="$l_heout2\n\t- User: "$l_user" Home "$l_home" Doesn't exist"
    fi
  done <<< "$(printf '%s\n' "${a_uarr[@]}")"

  [ -z "$l_heout2" ] && l_output="$l_output\n\t- Home directories exist" || l_output2="$l_output2$l_heout2"
  [ -z "$l_hoout2" ] && l_output="$l_output\n\t- Own their home directory" || l_output2="$l_output2$l_hoout2"
  [ -z "$l_haout2" ] && l_output="$l_output\n\t- Home directories are mode: "$l_max" or more restrictive" || l_output2="$l_output2$l_haout2"

  [ -n "$l_output" ] && l_output="\t- All local interactive users:$l_output"

  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit result: **PASS**\n\t- Correctly configured:\n$l_output"
  else
    echo -e "\t- Audit result: **FAIL**\n\t- Reasons for audit failure:\n$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly configured:\n$l_output"
  fi
}

dotfiles-chk(){
# Initialize variables for log storage
l_output=""
l_output2=""
l_output3=""
l_bf=""
l_df=""
l_nf=""
l_hf=""
l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

# Clear and initialize array
unset a_uarr
a_uarr=()

# Populate array with users and their home directory
while read -r l_epu l_eph; do
    [[ -n "$l_epu" && -n "$l_eph" ]] && a_uarr+=("$l_epu $l_eph")
done <<< "$(awk -v pat="$l_valid_shells" -F: '$NF ~ pat { print $1 " "  $(NF-1) }' /etc/passwd)"

# Number of users to check
l_asize="${#a_uarr[@]}"
l_maxsize="1000"

# If there are more than 1000 users, output a message
if [ "$l_asize" -gt "$l_maxsize" ]; then
    echo -e "\t- ** INFO **\n\t -  \"$l_asize\" Local interactive users found on the system\n\t - This may be a long running check"
fi

# File access check function
file_access_chk() {
    l_facout2=""
    l_max="$(printf '%o' $((0777 & ~$l_mask)))"
    if [ $(( $l_mode & $l_mask )) -gt 0 ]; then
        l_facout2="$l_facout2\n\t  - File: \"$l_hdfile\" is mode: \"$l_mode\"  and should be mode: \"$l_max\" or more restrictive"
    fi
    if [[ ! "$l_owner" =~ ($l_user) ]]; then
        l_facout2="$l_facout2\n\t  - File: \"$l_hdfile\" owned by: \"$l_owner\" and should be owned by \"${l_user//|/ or }\""
    fi
    if [[ ! "$l_gowner" =~ ($l_group) ]]; then
        l_facout2="$l_facout2\n\t  - File: \"$l_hdfile\" group owned by: \"$l_gowner\" and should be group owned by \"${l_group//|/ or }\""
    fi
}

# Check each user's home directory and associated files
while read -r l_user l_home; do
    l_fe="" l_nout2="" l_nout3="" l_dfout2="" l_hdout2="" l_bhout2=""
    if [ -d "$l_home" ]; then
        l_group="$(id -gn "$l_user" | xargs)"
        l_group="${l_group// /|}"
        
        while IFS= read -r -d $'\0' l_hdfile; do
            while read -r l_mode l_owner l_gowner; do
                case "$(basename "$l_hdfile")" in
                    .forward | .rhost )
                        l_fe="Y" && l_bf="Y"
                        l_dfout2="$l_dfout2\n  - File: \"$l_hdfile\" exists"
                        ;;
                    .netrc )
                        l_mask='0177'
                        file_access_chk
                        if [ -n "$l_facout2" ]; then
                            l_fe="Y" && l_nf="Y"
                            l_nout2="$l_facout2"
                        else
                            l_nout3="   - File: \"$l_hdfile\" exists"
                        fi
                        ;;
                    .bash_history )
                        l_mask='0177'
                        file_access_chk
                        if [ -n "$l_facout2" ]; then
                            l_fe="Y" && l_hf="Y"
                            l_bhout2="$l_facout2"
                        fi
                        ;;
                    * )
                        l_mask='0133'
                        file_access_chk
                        if [ -n "$l_facout2" ]; then
                            l_fe="Y" && l_df="Y"
                            l_hdout2="$l_facout2"
                        fi
                        ;;
                esac
            done <<< "$(stat -Lc '%#a %U %G' "$l_hdfile")"
        done < <(find "$l_home" -xdev -type f -name '.*' -print0)
    fi
    
    # If issues are found for the user, log them
    if [ "$l_fe" = "Y" ]; then
        l_output2="$l_output2\n\t - User: \"$l_user\" Home Directory:  \"$l_home\""
        [ -n "$l_dfout2" ] && l_output2="$l_output2$l_dfout2"
        [ -n "$l_nout2" ] && l_output2="$l_output2$l_nout2"
        [ -n "$l_bhout2" ] && l_output2="$l_output2$l_bhout2"
        [ -n "$l_hdout2" ] && l_output2="$l_output2$l_hdout2"
    fi
    [ -n "$l_nout3" ] && l_output3="$l_output3\n\t - User: \"$l_user\" Home Directory: \"$l_home\"\n$l_nout3"
done <<< "$(printf '%s\n' "${a_uarr[@]}")"

# Remove array
unset a_uarr

# Log any .netrc issues as warnings
[ -n "$l_output3" ] && l_output3="\n\t- ** Warning ** - \".netrc\" files should be removed unless deemed necessary\n and in accordance with local site policy:$l_output3"

# Log issues for various files
[ -z "$l_bf" ] && l_output="$l_output\n\t - \".forward\" or \".rhost\" files"
[ -z "$l_nf" ] && l_output="$l_output\n\t - \".netrc\" files with incorrect access configured"
[ -z "$l_hf" ] && l_output="$l_output\n\t - \".bash_history\" files with incorrect access configured"
[ -z "$l_df" ] && l_output="$l_output\n\t - \"dot\" files with incorrect access configured"

# Final audit result
echo -e "\n- Local interactive user dot files access check:"
if [ -n "$l_output" ]; then
    echo -e "\t- Audit Result: **FAIL** [local interactive user dot files access isn't configured]\n\t- * Reasons for audit failure * :$l_output"
else
    echo -e "\t- Audit Result: **PASS** [local interactive user dot files access is configured]\n\t - * Correctly configured *  :$l_output"
fi

# Output warnings
echo -e "$l_output3"
}


verify_shadowed_passwords
password-chk
gid-chk
shadow-chk
uid-chk
gid-chk
user-chk
group-chk
home_dir_check
dotfiles-chk
