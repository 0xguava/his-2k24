#!/bin/bash

check_libpam_status(){
  echo -e "- Checking status and version of libpam-runtime:"

  # Check if the package is installed and extract its status and version
  pkg_status=$(dpkg-query -s libpam-runtime 2>/dev/null | grep -P -- '^(Status|Version)\b')

  if [[ -z "$pkg_status" ]]; then
    echo -e "\t- Audit result: **FAIL** [libpam-runtime is not installed or query failed]"
    echo -e "\t- Reason: The package 'libpam-runtime' is not installed or there was an issue with the query."
  else
    echo -e "\t- Audit result: **PASS** [libpam-runtime is installed]"
    echo -e "\t- Details: $pkg_status"
  fi
}


check_libpam_modules_status(){
  echo -e "- Checking status and version of libpam-modules:"

  # Check if the package is installed and extract its status and version
  pkg_status=$(dpkg-query -s libpam-modules 2>/dev/null | grep -P -- '^(Status|Version)\b')

  if [[ -z "$pkg_status" ]]; then
    echo -e "\t- Audit result: **FAIL** [libpam-modules is not installed or query failed]"
    echo -e "\t- Reason: The package 'libpam-modules' is not installed or there was an issue with the query."
  else
    version=$(echo "$pkg_status" | grep "Version" | awk '{print $2}')
    # Check if the version is 1.5.2-6 or later
    if dpkg --compare-versions "$version" ge "1.5.2-6"; then
      echo -e "\t- Audit result: **PASS** [libpam-modules is installed and version is $version]"
    else
      echo -e "\t- Audit result: **FAIL** [libpam-modules version is lower than 1.5.2-6]"
      echo -e "\t- Current version: $version. Required version: 1.5.2-6 or later."
    fi
  fi
}


check_libpam_pwquality_status(){
  echo -e "- Checking status and version of libpam-pwquality:"

  # Check if the package is installed and extract its status and version
  pkg_status=$(dpkg-query -s libpam-pwquality 2>/dev/null | grep -P -- '^(Status|Version)\b')

  if [[ -z "$pkg_status" ]]; then
    echo -e "\t- Audit result: **FAIL** [libpam-pwquality is not installed or query failed]"
    echo -e "\t- Reason: The package 'libpam-pwquality' is not installed or there was an issue with the query."
  else
    echo -e "\t- Audit result: **PASS** [libpam-pwquality is installed]"
    echo -e "\t- Details: $pkg_status"
  fi
}

check_libpam_status
check_libpam_modules_status
check_libpam_pwquality_status
