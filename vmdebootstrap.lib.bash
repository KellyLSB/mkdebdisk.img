#!/bin/bash

VMDEBOOTSTRAP_ARCH=""
VMDEBOOTSTRAP_HOST_ARCH="$(uname -m)"
VMDEBOOTSTRAP_FOREIGN=""
VMDEBOOTSTRAP_DISK_SIZE="4G"
VMDEBOOTSTRAP_BOOT_SIZE="64M"

VMDEBOOTSTRAP_HOSTNAME="debdisk"
VMDEBOOTSTRAP_ROOT_PASSWORD="root"

VMDEBOOTSTRAP_ARGS=(
    "--package debian-archive-keyring"
    "--package apt-transport-https"
    "--package debootstrap"
    "--package minicom"
    "--package picocom"
    "--package locales"
    "--package curl"
    "--package nano"
)

#
# Private Functions
#

function __VMDebootstrapFileFmt() {
    local filefmt

    filefmt="$(VMDebootstrapArch)-$(VMDebootstrapDistribution)"
    echo -n "${MKDD_OUT_PATH}/${filefmt}-${MKDD_TIME}"
}

#
# Build Config Functions
#

function VMDebootstrapArch() {
    # Set the Host Architecture again
    # @NOTE seems that the initial variable
    #   never gets set; I'll debug it later.
    VMDEBOOTSTRAP_HOST_ARCH="$(uname -m)"

    # Set the architecture value
    if [[ -n "$1" ]]; then
        VMDEBOOTSTRAP_ARCH="$1"
    fi

    # Default first to the $ARCH value
    if [[ -z "${VMDEBOOTSTRAP_ARCH}" && -n "${ARCH}" ]]; then
        VMDEBOOSTRAP_ARCH="${ARCH}"
    fi

    # Fallback to the host architecture
    if [[ -z "${VMDEBOOTSTRAP_ARCH}" && -z "${ARCH}" ]]; then
    	case "${VMDEBOOTSTRAP_HOST_ARCH}" in
    		x86_64|amd64)  VMDEBOOTSTRAP_ARCH="amd64";;
            aarch64|arm64) VMDEBOOTSTRAP_ARCH="arm64";;
    		*)
    			echo "Unable to determine dpkg package architecture." 1>&2
    			echo "Default selection order:" 1>&2
                echo "- \$VMDEBOOTSTRAP_ARCH" 1>&2
                echo "- \$ARCH" 1>&2
                echo "- \$(uname -m)" 1>&2
    			exit 1
    		;;
    	esac
    fi

    # Set the foreign architecture kernel emulator
    case "${VMDEBOOTSTRAP_HOST_ARCH}" in
        x86_64|amd64)
            [[ "${VMDEBOOTSTRAP_ARCH}" != "amd64" ]] && \
                VMDEBOOTSTRAP_FOREIGN="$(which qemu-x86_64-static)"
            ;;
        aarch64|arm64)
            [[ "${VMDEBOOTSTRAP_ARCH}" != "arm64" ]] && \
                VMDEBOOTSTRAP_FOREIGN="$(which qemu-aarch64-static)"
            ;;
        armhf|arm)
            [[ "${VMDEBOOTSTRAP_ARCH}" != "armhf" ]] && \
                VMDEBOOTSTRAP_FOREIGN="$(which qemu-arm-static)"
            ;;
        *)
            echo "Only x86_64, amd64, aarch64, arm64, armhf and arm are supported at this time!" 1>&2
            echo "Solely because I'm lazy feel free and patch mkdebdisk.img/vmdebootstrap.lib.bash and submit a pull request."  1>&2
            echo "Skipping..." 1>&2
            ;;
    esac

    echo -n "${VMDEBOOTSTRAP_ARCH}"
}

function VMDebootstrapForeign() {
    [[ -n "$1" ]] && VMDEBOOTSTRAP_FOREIGN="$(which $1)"
    echo -n "${VMDEBOOTSTRAP_FOREIGN}"
}

function VMDebootstrapDistribution() {
    AptPrimaryMirrorDistribution $@
}

# Automatically retrieves the primary mirror from apt.lib.bash
function VMDebootstrapMirror() {
    AptProxyMirror $@
}

function VMDebootstrapDiskSize() {
    [[ -n "$1" ]] && VMDEBOOTSTRAP_DISK_SIZE="$1"
    echo -n "${VMDEBOOTSTRAP_DISK_SIZE}"
}

function VMDebootstrapBootPartitionSize() {
    [[ -n "$1" ]] && VMDEBOOTSTRAP_BOOT_SIZE="$1"
    echo -n "${VMDEBOOTSTRAP_BOOT_SIZE}"
}

function VMDebootstrapBootPartitionType() {
    [[ -n "$1" ]] && VMDEBOOTSTRAP_BOOT_TYPE="$1"
    echo -n "${VMDEBOOTSTRAP_BOOT_TYPE}"
}

function VMDebootstrapHostname() {
    [[ -n "$1" ]] && VMDEBOOTSTRAP_HOSTNAME="$1"
    echo -n "${VMDEBOOTSTRAP_HOSTNAME}"
}

function VMDeboostrapRootPassword() {
    [[ -n "$1" ]] && VMDEBOOTSTRAP_ROOT_PASSWORD="$1"
    echo -n "${VMDEBOOTSTRAP_ROOT_PASSWORD}"
}

#
# Build Functions
#

function VMDebootstrapAddArgument() {
    VMDEBOOTSTRAP_ARGS+=("--$1 \"$2\"")
}

function VMDebootstrapArguments() {
    local arguments

    arguments=(
        "arch:$(VMDebootstrapArch)"
        "distribution:$(VMDebootstrapDistribution)"
        "mirror:$(VMDebootstrapMirror)"
        "image:$(__VMDebootstrapFileFmt).img"
        "size:$(VMDebootstrapDiskSize)"
        "bootsize:$(VMDebootstrapBootPartitionSize)"
        "boottype:$(VMDebootstrapBootPartitionType)"
        "log-level:debug"
        "verbose"
        "no-kernel"
        "no-extlinux"
        "hostname:$(VMDebootstrapHostname)"
        "customize:${CUSTOMIZE}"
    )

    for argument in ${arguments[@]}; do
        option="$(cut -d':' -f1 <<<"${argument}")"

        if grep -q ":" <<<"${argument}"; then
            value="$(cut -d':' -f2- <<<"${argument}")"
            echo -n "--${option} ${value} "
        else
            echo -n "--${option} "
        fi
    done

    echo "${VMDEBOOTSTRAP_ARGS[@]}"
}

function VMDebootstrapBuild() {
    chmod +x ${CUSTOMIZE}
    sudo vmdebootstrap $(VMDebootstrapArguments) $@
    sudo mv "${CUSTOMIZE}" "$(__VMDebootstrapFileFmt).customize"
    sudo mv "debootstrap.log" "$(__VMDebootstrapFileFmt).log"
}
