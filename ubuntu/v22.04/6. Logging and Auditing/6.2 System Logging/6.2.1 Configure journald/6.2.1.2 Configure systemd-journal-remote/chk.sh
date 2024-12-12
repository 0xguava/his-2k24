#!/bin/bash

systemd_journal_remote_chk() {
  echo -e "- systemd-journal-remote installation check:"
  local l_output=""

  if dpkg-query -s systemd-journal-remote &>/dev/null; then
    l_output="systemd-journal-remote is installed"
    echo -e "\t- Audit result: **PASS** [systemd-journal-remote is installed]"
    echo -e "\t- Reason: $l_output"
  else
    l_output="systemd-journal-remote is not installed"
    echo -e "\t- Audit result: **FAIL** [systemd-journal-remote is not installed]"
    echo -e "\t- Reason: $l_output"
  fi
}

check_journal_upload_auth() {
  echo -e "- Verifying systemd-journal-upload authentication settings:"

  # Path to the configuration file
  config_file="/etc/systemd/journal-upload.conf"

  # Check if the configuration file exists
  if [[ ! -f "$config_file" ]]; then
    echo -e "\t- Audit result: **FAIL** [Configuration file $config_file does not exist]"
    return
  fi

  # Grep for required fields in the configuration file
  config_check=$(grep -P "^ *URL=|^ *ServerKeyFile=|^ *ServerCertificateFile=|^ *TrustedCertificateFile=" "$config_file")

  # Expected configuration values
  expected_config="URL=192.168.50.42
ServerKeyFile=/etc/ssl/private/journal-upload.pem
ServerCertificateFile=/etc/ssl/certs/journal-upload.pem
TrustedCertificateFile=/etc/ssl/ca/trusted.pem"

  # Compare the current configuration with the expected one
  if [[ "$config_check" == "$expected_config" ]]; then
    echo -e "\t- Audit result: **PASS** [Authentication configuration matches the expected values]"
  else
    echo -e "\t- Audit result: **FAIL** [Authentication configuration does not match the expected values]"
    echo -e "\t- Current configuration: $config_check"
  fi
}


check_journal_upload_enabled() {
  echo -e "- Verifying if systemd-journal-upload is enabled:"
  
  enabled_status=$(systemctl is-enabled systemd-journal-upload.service)
  
  if [[ "$enabled_status" == "enabled" ]]; then
    echo -e "\t- Audit result: **PASS** [systemd-journal-upload is enabled]"
  else
    echo -e "\t- Audit result: **FAIL** [systemd-journal-upload is not enabled]"
  fi
}

check_journal_upload_active() {
  echo -e "- Verifying if systemd-journal-upload is active:"
  
  active_status=$(systemctl is-active systemd-journal-upload.service)
  
  if [[ "$active_status" == "active" ]]; then
    echo -e "\t- Audit result: **PASS** [systemd-journal-upload is active]"
  else
    echo -e "\t- Audit result: **FAIL** [systemd-journal-upload is not active]"
  fi
}


# Check if systemd-journal-remote.socket and systemd-journal-remote.service are not enabled
check_journal_remote_enabled() {
  echo -e "- Verifying that systemd-journal-remote.socket and systemd-journal-remote.service are not enabled:"

  # Check if services are enabled
  enabled_status=$(systemctl is-enabled systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null)

  if [[ -z "$enabled_status" ]]; then
    echo -e "\t- Audit result: **PASS** [systemd-journal-remote.socket and systemd-journal-remote.service are not enabled]"
  else
    echo -e "\t- Audit result: **FAIL** [systemd-journal-remote.socket or systemd-journal-remote.service is enabled]"
    echo -e "\t- Enabled services: $enabled_status"
  fi
}

# Check if systemd-journal-remote.socket and systemd-journal-remote.service are not active
check_journal_remote_active() {
  echo -e "- Verifying that systemd-journal-remote.socket and systemd-journal-remote.service are not active:"

  # Check if services are active
  active_status=$(systemctl is-active systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null)

  if [[ -z "$active_status" ]]; then
    echo -e "\t- Audit result: **PASS** [systemd-journal-remote.socket and systemd-journal-remote.service are not active]"
  else
    echo -e "\t- Audit result: **FAIL** [systemd-journal-remote.socket or systemd-journal-remote.service is active]"
    echo -e "\t- Active services: $active_status"
  fi
}

# Run checks
systemd_journal_remote_chk
check_journal_upload_auth
check_journal_upload_enabled
check_journal_upload_active
check_journal_remote_enabled
check_journal_remote_active
