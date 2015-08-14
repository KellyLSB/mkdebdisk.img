#!/bin/bash

## --- ## => Retain the Project Path's Owner and Group.

# Get the Project Path
: ${MKDDP_PATH:="$PWD"}

# Get the Project Path Owner and Group
: ${MKDDP_OWNER:="$(stat --format '%U' "$MKDDP_PATH")"}
: ${MKDDP_GROUP:="$(stat --format '%G' "$MKDDP_PATH")"}

# Ensure the Project Path and Files are owned by the same Owner and Group
# @NOTE: This is because when we run vmdebootstrap we require sudo for devmapper.
trap "sudo chown -Rf ${MKDDP_OWNER}:${MKDDP_GROUP} ${MKDDP_PATH}" EXIT SIGQUIT SIGTERM

## --- ## => User Set ARCH and DIST

# Get the System Image Debian Package Architecture and Distribution.
: ${MKDDP_ARCH:="$ARCH"}
: ${MKDDP_DIST:="$DIST"}

## --- ## => Default ARCH and DIST

# Use Current Architecture as Default
if [[ -z "${MKDDP_ARCH}" ]]; then
	case "$(uname -m)" in
		x86_64) MKDDP_ARCH="amd64";;
		*)
			echo "Unable to determine dpkg package architecture." 1>&2
			echo "Default selection order: \$ARCH, \$MKDDP_ARCH, \$(uname -m)" 1>&2
			exit 1
		;;
	esac
fi

# Default the Debian Distribution to Jessie
: ${MKDDP_DIST:="jessie"}

## --- ## => Set mkdebdisk.img library path

MKDD_PATH="$(dirname "$(ls -l ${BASH_SOURCE} | awk '{print $NF}')")"
MKDD_PATH="$(cd ${MKDD_PATH}; pwd -P)"
MKDDP_TIME="$(date '+%Y-%m-%d-%H-%M-%S')"
CUSTOMIZE="customize-${MKDDP_TIME}"

## --- ## => Load Libraries

source "${MKDD_PATH}/net.lib.bash"
source "${MKDD_PATH}/util.lib.bash"
source "${MKDD_PATH}/block.lib.bash"

source "${MKDD_PATH}/apt.lib.bash"
source "${MKDD_PATH}/chroot.lib.bash"
source "${MKDD_PATH}/systemd.lib.bash"
source "${MKDD_PATH}/grub.lib.bash"
source "${MKDD_PATH}/console.lib.bash"

## --- ## => Start Building

# Use a proxy during bootstrap.
__AptProxy

# Known servers to not respond to proxies well.
APT_NOPROXY+=(
	"get.docker.io"
	"get.docker.com"
	"download.oracle.com"
)

#
# Setup Functions
#

function __Prefix() {
	cat -s <<-EOF
	#!/bin/sh
	CHROOT="\$1"
	cd "\${CHROOT}"
	$(ChrootPrepare)
	EOF
}

function __Suffix() {
	cat -s <<-EOF
	chmod a+x "\${CHROOT}/provision"
	chroot "\${CHROOT}" /provision
	rm -f "\${CHROOT}/provision"
	$(ChrootCleanup)
	exit 0

	#!/bin/bash
	EOF
}

#
# Build Functions
#

function Begin() {
	LENGTH=$(( $(wc -l <<<"$(__Prefix)") + $(wc -l <<<"$(__Suffix)") + 1 ))

	__Prefix
	echo "tail -n +${LENGTH} \$0 > \"\${CHROOT}/provision\""
	__Suffix
}
