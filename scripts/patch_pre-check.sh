#!/bin/bash
# ==========================================
# Prechecks Script
# ==========================================

ERR_LOG="./err"
> "$ERR_LOG"

log_fail() {
  echo "[FAIL] $1"
  echo "[$(date '+%F %T')] $1" >> "$ERR_LOG"
}

log_pass() {
  echo "[PASS] $1"
}

separator() {
  echo "---------"
}

get_ilo_ip() {
  ipmitool lan print 1 2>/dev/null | awk -F: '/IP Address[ ]+:/ {print $2}' | xargs
}

echo "===== PRECHECKS START ====="
echo

# === UPTIME CHECK ===
echo "Performing uptime check..."
uptime
separator
echo

# === FILESYSTEM CHECK ===
echo "Performing filesystem usage checks (/ibus, /mysql)..."

check_fs() {
  local mount=$1

  if df -hP "$mount" &>/dev/null; then
    usage=$(df -hP "$mount" | awk 'NR==2 {gsub("%","",$5); print $5}')
    if (( usage <= 80 )); then
      log_pass "Filesystem $mount usage is ${usage}%"
    else
      log_fail "Filesystem $mount usage is ${usage}% (>80%)"
    fi
  else
    log_fail "Filesystem $mount not found"
  fi
}

check_fs /ibus
check_fs /mysql
separator
echo

# === MYSQL REPLICATION CHECK ===
echo "Performing MySQL replication health check..."

check_mysql_replication() {
  if ! command -v mysql &>/dev/null; then
    log_fail "MySQL client not found"
    return
  fi

  status=$(mysql -u root -p@dmin1 -h 127.0.0.1 -e "SHOW SLAVE STATUS\G" 2>/dev/null)
  if [[ -z "$status" ]]; then
    log_fail "Unable to fetch MySQL slave status"
    return
  fi

  io=$(echo "$status" | awk '/Slave_IO_Running/ {print $2}')
  sql=$(echo "$status" | awk '/Slave_SQL_Running/ {print $2}')
  errno=$(echo "$status" | awk '/Last_Errno/ {print $2}')

  if [[ "$io" == "Yes" && "$sql" == "Yes" && "$errno" == "0" ]]; then
    log_pass "MySQL replication healthy (IO & SQL running, no slave errors)"
  else
    log_fail "MySQL replication issue detected (IO=$io SQL=$sql ErrNo=$errno)"
  fi
}

check_mysql_replication
separator
echo

# === OS VERSION CHECK ===
echo "Performing Oracle Linux version check..."

if [[ -f /etc/oracle-release ]]; then
  ver=$(awk '{print $5}' /etc/oracle-release | cut -d. -f1)
  if [[ "$ver" == "7" ]]; then
    log_pass "Oracle Linux 7.x detected"
  else
    log_fail "Oracle Linux version is ${ver}.x (expected 7.x)"
  fi
else
  log_fail "Not an Oracle Linux system"
fi
separator
echo

# === PHYSICAL / VM CHECK ===
echo "Determining if system is physical or virtual..."

IS_VM=false
if command -v systemd-detect-virt &>/dev/null; then
  if systemd-detect-virt -q; then
    IS_VM=true
    log_pass "System detected as Virtual Machine"
  else
    log_pass "System detected as Physical Server"
  fi
else
  log_fail "Unable to determine virtualization type"
fi
separator
echo

# === ILO CONNECTIVITY CHECK (PHYSICAL ONLY) ===
if [[ "$IS_VM" == "false" ]]; then
  echo "Performing iLO connectivity check (physical server)..."

  if command -v ipmitool &>/dev/null; then
    ILO_HOST=$(get_ilo_ip)

    if [[ -z "$ILO_HOST" || "$ILO_HOST" == "0.0.0.0" ]]; then
      log_fail "Unable to determine iLO IP using ipmitool"
    elif ping -c 2 -W 2 "$ILO_HOST" &>/dev/null; then
      log_pass "iLO ($ILO_HOST) is reachable"
    else
      log_fail "iLO ($ILO_HOST) is NOT reachable"
    fi
  else
    log_fail "ipmitool not installed – cannot determine iLO IP"
  fi
else
  log_pass "Skipping iLO check (virtual machine)"
fi
separator
echo

# === SERVICE STATUS CHECK ===
echo "Performing service status check (cerner-ibus-service)..."

SERVICE="cerner-ibus-service"

if systemctl is-active --quiet "$SERVICE"; then
  log_pass "Service $SERVICE is running"
else
  log_fail "Service $SERVICE is NOT running"
fi
separator
echo

echo "===== PRECHECKS COMPLETED ====="
echo "Failures (if any) logged to: $ERR_LOG"
