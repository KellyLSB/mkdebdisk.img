#!/bin/bash

#
# Build Functions
#

function SystemdReload() {
	Exec 'SystemdReload' "systemctl reload-daemon"
}

function SystemdEnableService() {
	Exec 'SystemdEnableService' "systemctl enable $1" ${@:2}
}

function SystemdDisableService() {
	Exec 'SystemdDisableService' "systemctl disable $1" ${@:2}
}

function SystemdStartService() {
	Exec 'SystemdStartService' "systemctl start $1" ${@:2}
}

function SystemdStopService() {
	Exec 'SystemdStopService' "systemctl stop $1" ${@:2}
}

function SystemdRestartService() {
	Exec 'SystemdRestartService' "systemctl restart $1" ${@:2}
}

function SystemdEnableDaemons() {
	Exec 'SystemdEnableDaemons' 'rm -f ${CHROOT}/user/sbin/policy-rc.d'
}

function SystemdDisableDaemons() {
	File 'SystemdDisableDaemons' '${CHROOT}/usr/sbin/policy-rc.d' --mod 'a+x' \
	<<-EOF
	#!/bin/sh
	echo "All runlevel operations denied by policy" 1>&2
	exit 101
	EOF
}

function SystemdFirstRun() {
	File 'SystemdFirstRun' '${CHROOT}/var/lib/firstrun' --mod 'a+x'
}

function SystemdRootPassword() {
	Exec 'SystemdRootPassword' "chpasswd <<<\"root:$1\""
	VMDebootstrapRootPassword "$1" &>/dev/null
}

function SystemdHostname() {
	File 'SystemdHostname' '${CHROOT}/etc/hostname' <<<"$1"
	Exec 'SystemdHostname' \
		"sed -Ei 's/(\s+)localhost(\s+)/\1$1 localhost\2/g' /etc/hosts"
	VMDebootstrapHostname "$1" &>/dev/null
}
