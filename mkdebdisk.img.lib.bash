#!/bin/bash

## --- ## => Retain the Project Path's Owner and Group.

# Get the Project Path
: ${PROJECT_PATH:="$PWD"}

# Get the Project Path Owner and Group
: ${PROJECT_OWNER:="$(stat --format '%U' "$PROJECT_PATH")"}
: ${PROJECT_GROUP:="$(stat --format '%G' "$PROJECT_PATH")"}

# Ensure the Project Path and Files are owned by the same Owner and Group
# @NOTE: This is because when we run vmdebootstrap we require sudo for devmapper.
trap "sudo chown -Rf ${PROJECT_OWNER}:${PROJECT_GROUP} ${PROJECT_PATH}" \
 	EXIT SIGQUIT SIGTERM

## --- ## => Set mkdebdisk.img library path

MKDD_TIME="$(date '+%Y_%m_%d-%H_%M_%S')"
MKDD_PATH="$(dirname "$(ls -l ${BASH_SOURCE} | awk '{print $NF}')")"
MKDD_PATH="$(cd ${MKDD_PATH}; pwd -P)"

## --- ## => Load Libraries

source "${MKDD_PATH}/vmdebootstrap.lib.bash"
source "${MKDD_PATH}/net.lib.bash"
source "${MKDD_PATH}/util.lib.bash"
source "${MKDD_PATH}/block.lib.bash"

source "${MKDD_PATH}/apt.lib.bash"
source "${MKDD_PATH}/chroot.lib.bash"
source "${MKDD_PATH}/systemd.lib.bash"
source "${MKDD_PATH}/grub.lib.bash"
source "${MKDD_PATH}/console.lib.bash"

## --- ## => Setup the output directories

: ${MKDD_OUT_PATH:="$(pwd)/out/$(UtilBasenameNoExt $0)"}
[[ -d "${MKDD_OUT_PATH}" ]] || mkdir -p "${MKDD_OUT_PATH}"

CUSTOMIZE="${MKDD_OUT_PATH}/customize.tmp"
touch "${CUSTOMIZE}"; chmod +x "${CUSTOMIZE}"

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
