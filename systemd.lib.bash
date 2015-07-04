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
	File 'SystemdDisableDaemons' '${CHROOT}/usr/sbin/policy-rc.d' --mod 0666 <<-EOF
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
}
