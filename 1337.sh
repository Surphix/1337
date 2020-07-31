#!/bin/sh
# shellcheck disable=1003,1091,2006,2016,2034,2039
# vim: set ts=2 sw=2 sts=2 et:

#( Colors
#
# fg
red='\e[31m'
lred='\e[91m'
green='\e[32m'
lgreen='\e[92m'
yellow='\e[33m'
lyellow='\e[93m'
blue='\e[34m'
lblue='\e[94m'
magenta='\e[35m'
lmagenta='\e[95m'
cyan='\e[36m'
lcyan='\e[96m'
grey='\e[90m'
lgrey='\e[37m'
white='\e[97m'
black='\e[30m'
#

#( Globals
#
# user
lse_user_id="$UID"
[ -z "$lse_user_id" ] && lse_user_id="`id -u`"
lse_user="$USER"
[ -z "$lse_user" ] && lse_user="`id -nu`"
lse_pass=""
lse_home="$HOME"
[ -z "$lse_home" ] && lse_home="`(grep -E "^$lse_user:" /etc/passwd | cut -d: -f6)2>/dev/null`"

# system
lse_arch="`uname -m`"
lse_linux="`uname -r`"
lse_hostname="`hostname`"
lse_distro=`command -v lsb_release >/dev/null 2>&1 && lsb_release -d | sed 's/Description:\s*//' 2>/dev/null`
[ -z "$lse_distro" ] && lse_distro="`(source /etc/os-release && echo "$PRETTY_NAME")2>/dev/null`"

# lse
lse_passed_tests=""
lse_executed_tests=""
lse_DEBUG=false
lse_procmon_data=`mktemp`
lse_procmon_lock=`mktemp`

# printf
alias printf="env printf"

gtfo_bins="
/apt-get 	
/apt 	
/aria2c 	
/arp 	
/ash 	
/awk 	
/base32 	
/base64 	
/bash 	
/bpftrace 	
/bundler 	
/busctl 	
/busybox 	
/byebug 	
/cancel 	
/cat 	
/chmod 	
/chown 	
/chroot 	
/cobc 	
/cp 	
/cpan 	
/cpulimit 	
/crash 	
/crontab 	
/csh 	
/curl 	
/cut 	
/dash 	
/date 	
/dd 	
/dialog 	
/diff 	
/dmesg 	
/dmsetup 	
/dnf 	
/docker 	
/dpkg 	
/easy_install 	
/eb 	
/ed 	
/emacs 	
/env 	
/eqn 	
/expand 	
/expect 	
/facter 	
/file 	
/find 	
/finger 	
/flock 	
/fmt 	
/fold 	
/ftp 	
/gawk 	
/gcc 	
/gdb 	
/gem 	
/genisoimage 	
/gimp 	
/git 	
/grep 	
/gtester 	
/hd 	
/head 	
/hexdump 	
/highlight 	
/iconv 	
/iftop 	
/ionice 	
/ip 	
/irb 	
/jjs 	
/journalctl 	
/jq 	
/jrunscript 	
/ksh 	
/ksshell 	
/ld.so 	
/ldconfig 	
/less 	
/logsave 	
/look 	
/ltrace 	
/lua 	
/lwp-download 	
/lwp-request 	
/mail 	
/make 	
/man 	
/mawk 	
/more 	
/mount 	
/mtr 	
/mv 	
/mysql 	
/nano 	
/nawk 	
/nc 	
/nice 	
/nl 	
/nmap 	
/node 	
/nohup 	
/nroff 	
/nsenter 	
/od 	
/openssl 	
/pdb 	
/perl 	
/pg 	
/php 	
/pic 	
/pico 	
/pip 	
/pkexec 	
/pry 	
/puppet 	
/python 	
/rake 	
/readelf 	
/red 	
/redcarpet 	
/restic 	
/rlogin 	
/rlwrap 	
/rpm 	
/rpmquery 	
/rsync 	
/ruby 	
/run-mailcap 	
/run-parts 	
/rvim 	
/scp 	
/screen 	
/script 	
/sed 	
/service 	
/setarch 	
/sftp 	
/shuf 	
/smbclient 	
/socat 	
/soelim 	
/sort 	
/sqlite3 	
/ssh 	
/start-stop-daemon 	
/stdbuf 	
/strace 	
/strings 	
/su 	
/sysctl 	
/systemctl 	
/tac 	
/tail 	
/tar 	
/taskset 	
/tclsh 	
/tcpdump 	
/tee 	
/telnet 	
/tftp 	
/time 	
/timeout 	
/tmux 	
/top 	
/ul 	
/unexpand 	
/uniq 	
/unshare 	
/uudecode 	
/uuencode 	
/valgrind 	
/vi 	
/vim 	
/watch 	
/wget 	
/whois 	
/wish 	
/xargs 	
/xxd 	
/xz 	
/yelp 	
/yum 	
/zip 	
/zsh 	
/zsoelim 	
/zypper
"

# internal data
lse_common_setuid="
/bin/fusermount
/bin/mount
/bin/ntfs-3g
/bin/ping
/bin/ping6
/bin/su
/bin/umount
/lib64/dbus-1/dbus-daemon-launch-helper
/sbin/mount.ecryptfs_private
/sbin/mount.nfs
/sbin/pam_timestamp_check
/sbin/pccardctl
/sbin/unix2_chkpwd
/sbin/unix_chkpwd
/usr/bin/Xorg
/usr/bin/arping
/usr/bin/at
/usr/bin/beep
/usr/bin/chage
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/crontab
/usr/bin/expiry
/usr/bin/firejail
/usr/bin/fusermount
/usr/bin/fusermount-glusterfs
/usr/bin/gpasswd
/usr/bin/kismet_capture
/usr/bin/mount
/usr/bin/mtr
/usr/bin/newgidmap
/usr/bin/newgrp
/usr/bin/newuidmap
/usr/bin/passwd
/usr/bin/pkexec
/usr/bin/procmail
/usr/bin/staprun
/usr/bin/su
/usr/bin/sudo
/usr/bin/sudoedit
/usr/bin/traceroute6.iputils
/usr/bin/umount
/usr/bin/weston-launch
/usr/lib/chromium-browser/chrome-sandbox
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/dbus-1/dbus-daemon-launch-helper
/usr/lib/eject/dmcrypt-get-device
/usr/lib/openssh/ssh-keysign
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/polkit-1/polkit-agent-helper-1
/usr/lib/pt_chown
/usr/lib/snapd/snap-confine
/usr/lib/spice-gtk/spice-client-glib-usb-acl-helper
/usr/lib/x86_64-linux-gnu/lxc/lxc-user-nic
/usr/lib/xorg/Xorg.wrap
/usr/libexec/Xorg.wrap
/usr/libexec/abrt-action-install-debuginfo-to-abrt-cache
/usr/libexec/dbus-1/dbus-daemon-launch-helper
/usr/libexec/gstreamer-1.0/gst-ptp-helper
/usr/libexec/openssh/ssh-keysign
/usr/libexec/polkit-1/polkit-agent-helper-1
/usr/libexec/pt_chown
/usr/libexec/qemu-bridge-helper
/usr/libexec/spice-gtk-x86_64/spice-client-glib-usb-acl-helper
/usr/sbin/exim4
/usr/sbin/grub2-set-bootflag
/usr/sbin/mount.nfs
/usr/sbin/mtr-packet
/usr/sbin/pam_timestamp_check
/usr/sbin/pppd
/usr/sbin/pppoe-wrapper
/usr/sbin/suexec
/usr/sbin/unix_chkpwd
/usr/sbin/userhelper
/usr/sbin/usernetctl
/usr/sbin/uuidd
"
#regex rules for common setuid
lse_common_setuid="$lse_common_setuid
/snap/core/.*
/var/tmp/mkinitramfs.*
"
#critical writable files
lse_critical_writable="
/etc/apache2/apache2.conf
/etc/apache2/httpd.conf
/etc/bash.bashrc
/etc/bash_completion
/etc/bash_completion.d/*
/etc/environment
/etc/environment.d/*
/etc/hosts.allow
/etc/hosts.deny
/etc/httpd/conf/httpd.conf
/etc/httpd/httpd.conf
/etc/incron.conf
/etc/incron.d/*
/etc/logrotate.d/*
/etc/modprobe.d/*
/etc/pam.d/*
/etc/passwd
/etc/php*/fpm/pool.d/*
/etc/php/*/fpm/pool.d/*
/etc/profile
/etc/profile.d/*
/etc/rc*.d/*
/etc/rsyslog.d/*
/etc/shadow
/etc/skel/*
/etc/sudoers
/etc/sudoers.d/*
/etc/supervisor/conf.d/*
/etc/supervisor/supervisord.conf
/etc/sysctl.conf
/etc/sysctl.d/*
/etc/uwsgi/apps-enabled/*
/root/.ssh/authorized_keys
"
#critical writable directories
lse_critical_writable_dirs="
/etc/bash_completion.d
/etc/cron.d
/etc/cron.daily
/etc/cron.hourly
/etc/cron.weekly
/etc/environment.d
/etc/logrotate.d
/etc/modprobe.d
/etc/pam.d
/etc/profile.d
/etc/rsyslog.d/
/etc/sudoers.d/
/etc/sysctl.d
/root
"
#)

#( Options
lse_color=true
lse_interactive=true
lse_proc_time=60
lse_level=0 #Valid levels 0:default, 1:interesting, 2:all
lse_selection="" #Selected tests to run. Empty means all.
lse_find_opts='-path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -path /run -prune -o' #paths to exclude from searches
#)

cecho() {
  if $lse_color; then
    printf "%b" "$@"
  else
    # If color is disabled we remove it
    printf "%b" "$@" | sed 's/\x1B\[[0-9;]\+[A-Za-z]//g'
  fi
}

##################################################################( file system
lse_run_tests_filesystem() {
  lse_header "fst" "GTFO Bins"

  #get setuid binaries
  lse_test "fst010" "1" \
    "Binaries with setuid bit" \
    'find / $lse_find_opts -perm -4000 -type f -print' \
    "" \
    "lse_setuid_binaries"

  #uncommon setuid binaries
  lse_test "fst020" "0" \
    "Uncommon setuid binaries" \
    'local setuidbin="$lse_setuid_binaries"; local IFS="
"; for cs in ${lse_common_setuid}; do setuidbin=`printf "$setuidbin\n" | grep -Ev "$cs"`;done ; printf "$setuidbin\n"' \
    "fst010"
}

lse_request_information() {
  if $lse_interactive; then
  cecho "${grey}---\n"
    [ -z "$lse_user" ] && lse_user=`lse_ask "Could not find current user name. Current user?"`
    lse_pass=`lse_ask "If you know the current user password, write it here to check sudo privileges"`
  cecho "${grey}---\n"
  fi
}

lse_show_info() {
  echo
  cecho "${lblue}        User:${reset} $lse_user\n"
  cecho "${lblue}     User ID:${reset} $lse_user_id\n"
  cecho "${lblue}    Password:${reset} "
  if [ -z "$lse_pass" ]; then
    cecho "${grey}none${reset}\n"
  else
    cecho "******\n"
  fi
  cecho "${lblue}        Home:${reset} $lse_home\n"
  cecho "${lblue}        Path:${reset} $PATH\n"
  cecho "${lblue}       umask:${reset} `umask 2>/dev/null`\n"

  echo
  cecho "${lblue}    Hostname:${reset} $lse_hostname\n"
  cecho "${lblue}       Linux:${reset} $lse_linux\n"
	if [ "$lse_distro" ]; then
  cecho "${lblue}Distribution:${reset} $lse_distro\n"
	fi
  cecho "${lblue}Architecture:${reset} $lse_arch\n"
  echo
}
lse_header() {
  local id="$1"
  shift
  local title="$*"
  local text="${magenta}"

  # Filter selected tests
  if [ "$lse_selection" ]; then
    local sel_match=false
    for s in $lse_selection; do
      if [ "`printf \"%s\" \"$s\"|cut -c1-3`" = "$id" ]; then
        sel_match=true
        break
      fi
    done
    $sel_match || return 0
  fi

  for i in $(seq ${#title} 70); do
    text="$text="
  done
  text="$text(${green} $title ${magenta})====="
  cecho "$text${reset}\n"
}
lse_exit() {
  local ec=1
  local text="\n${magenta}=================================="
  [ "$1" ] && ec=$1
  text="$text(${green} FINISHED ${magenta})=================================="
  cecho "$text${reset}\n"
  rm -f "$lse_procmon_data"
  rm -f "$lse_procmon_lock"
  exit "$ec"
}

lse_procmon() {
  # monitor processes
  #NOTE: The first number will be the number of occurrences of a process due to 
  #      uniq -c
  while [ -f "$lse_procmon_lock" ]; do
    ps -ewwwo start_time,pid,user:50,args
    sleep 0.001
  done | grep -v 'ewwwo start_time,pid,user:50,args' | sed 's/^ *//g' | tr -s '[:space:]' | grep -v "^START" | grep -Ev '[^ ]+ [^ ]+ [^ ]+ \[' | sort -Mr | uniq -c | sed 's/^ *//g' > "$lse_procmon_data"
}

lse_test_passed() {
  # Checks if a test passed by ID
  local id="$1"
  for i in $lse_passed_tests; do
    [ "$i" = "$id" ] && return 0
  done
  return 1
}

lse_test() {
  # Test id
  local id="$1"
  # Minimum level required for this test to show its output
  local level=$(($2))
  # Name of the current test
  local name="$3"
  # Output of the test
  local cmd="$4"
  # Dependencies
  local deps="$5"
  # Variable name where to store the output
  local var="$6"

  # Define colors
  local l="${lred}!"
  local r="${lgreen}"
  [ $level -eq 1 ] && l="${lyellow}*" && r="${cyan}"
  [ $level -eq 2 ] && l="${lblue}i" && r="${blue}"

  # Filter selected tests
  if [ "$lse_selection" ]; then
    local sel_match=false
    for s in $lse_selection; do
      if [ "$s" = "$id" ] || [ "$s" = "`printf \"%s\" \"$id\" | cut -c1-3`" ]; then
        sel_match=true
      fi
    done
    $sel_match || return 0
  fi

  # DEBUG messages
  $lse_DEBUG && cecho "${lmagenta}DEBUG: ${lgreen}Executing: ${reset}$cmd\n"

  # Print name and line
#   cecho "${white}[${l}${white}] ${grey}${id}${white} $name${grey}"
#   for i in $(seq $((${#name}+4)) 67); do
#     echo -n "."
#   done

  # Check dependencies
  local non_met_deps=""
  for d in $deps; do
    lse_test_passed "$d" || non_met_deps="$non_met_deps $d"
  done
  if [ "$non_met_deps" ]; then
    cecho " ${grey}skip\n"
    # In "selection mode" we print the missed dependencies
    if [ "$lse_selection" ]; then
      cecho "${red}---\n"
      cecho "Dependencies not met:$reset $non_met_deps\n"
      cecho "${red}---$reset\n"
    fi
    return 1
  fi 

  # If level is 2 and lse_level is less than 2, then we do not execute
  # level 2 tests unless their output needs to be assigned to a variable
  if [ $level -ge 2 ] && [ $lse_level -lt 2 ] && [ -z "$var" ]; then
    cecho " ${grey}skip\n"
    return 1
  else
    if $lse_DEBUG; then
      output="`eval "$cmd" 2>&1`"
    else
      # Execute command if this test's level is in scope
      output="`eval "$cmd" 2>/dev/null`"
    # Assign variable if available
    fi
    [ "$var" ] && readonly "${var}=$output"
    # Mark test as executed
    lse_executed_tests="$lse_executed_tests $id"
  fi

  if [ -z "$output" ]; then
    cecho "${grey} nope${reset}\n"
    return 1
  else
    lse_passed_tests="$lse_passed_tests $id"
    #cecho "${r} yes!${reset}\n"
    if [ $lse_level -ge $level ]; then
        for o in $output; do
            for bin in ${gtfo_bins}; do 
                if [[ $o == *$bin ]]; then
                    cecho "${r} $o -> https://gtfobins.github.io/gtfobins$bin"
                fi
            done
        done


    fi
    return 0
  fi
}

#( Main
while getopts "hcil:e:p:s:" option; do
  case "${option}" in
    c) lse_color=false;;
    e) lse_exclude_paths "${OPTARG}";;
    i) lse_interactive=false;;
    l) lse_set_level "${OPTARG}";;
    s) lse_selection="`printf \"%s\" \"${OPTARG}\"|sed 's/,/ /g'`";;
    p) lse_proc_time="${OPTARG}";;
    h) lse_help; exit 0;;
    *) lse_help; exit 1;;
  esac
done

#trap to exec on SIGINT
trap "lse_exit 1" 2

#lse_request_information
lse_show_info
PATH="$PATH:/sbin:/usr/sbin" #fix path just in case

lse_procmon &
(sleep "$lse_proc_time"; rm -f "$lse_procmon_lock") &

lse_run_tests_filesystem

lse_exit 0
#)