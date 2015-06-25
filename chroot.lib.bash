#!/bin/bash

#
# Build Functions
#

function ChrootMount() {
	local src_blck dst_path options

	src_blck="$1"
	dst_path="$2"
	options=(${@:3})

	if	 [[ -b "${src_blck}" ]]; then
		Script "ChrootMountMkdir" <<-EOF
		echo -ne "Mounting block device: \t"
		mkdir -p "\${CHROOT}${dst_path}"
		EOF
	elif [[ -d "${src_blck}" ]]; then
		Script "ChrootMountMkdir" <<-EOF
		echo -ne "Bind mounting directory: \t"
		mkdir -p "\${CHROOT}${dst_path}"
		EOF
		options+=("bind")
	elif [[ -f "${src_blck}" ]]; then
		Script "ChrootMountMkdir" <<-EOF
		echo -ne "Bind mounting file: \t"
		mkdir -p "\${CHROOT}$(dirname "${dst_path}")"
		EOF
		options+=("bind")
	fi

	Script "ChrootMount" <<-EOF
	echo "'${src_blck}' -> '(chroot)${dst_path}'"
	mount -o "${options}" "${src_blck}" "\${CHROOT}${dst_path}"
	EOF
	options="$(tr ' ' ',' <<<'${options[@]}')"
}

function ChrootUnmount() {
	local dst_path

	dst_path="$1"

	Script "ChrootUnmount" <<-EOF
	mount | awk '{print \$3}' | grep -q "\${CHROOT}${dist_path}" || return
	echo "Unmounting '(chroot)${dst_path}'."
	umount -lf "\${CHROOT}${dst_path}"
	EOF
}

function ChrootPrepare() {
	ChrootMount "/dev"     "/dev"
	ChrootMount "/dev/pts" "/dev/pts"
	ChrootMount "/proc"    "/proc"
	ChrootMount "/sys"     "/sys"

	SystemdDisableDaemons
	SystemdFirstRun
}

function ChrootCleanup() {
	SystemdEnableDaemons

	ChrootUnmount "/sys"
	ChrootUnmount "/proc"
	ChrootUnmount "/dev/pts"
	ChrootUnmount "/dev"
}
