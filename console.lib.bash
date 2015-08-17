#!/bin/bash

CONSOLE_BAUD="115200"
CONSOLE_BITS=8
CONSOLE_DEVICE=""
CONSOLE_FLOW=""
CONSOLE_PARITY="n"
CONSOLE_SYSTEMD_SERIAL_GETTY_ARGS=("-L")
CONSOLE_SYSTEMD_SERIAL_GETTY_BIN="/sbin/getty"
CONSOLE_SYSTEMD_SERIAL_GETTY_TERM="vt100"

CONSOLE_LINUX_CMDLINE=()
CONSOLE_SYSTEMD_GETTY=()

#
# Helper Functions
#

# Returns the first serial console for the getty
function ConsoleSerialCommand() {
	"${CONSOLE_SYSTEMD_GETTY[0]}"
}

#
# Build Functions
#

function ConsoleAdd() {
	local options device baud parity bits flow term

	device="${1-CONSOLE_DEVICE}"
	baud="${2-CONSOLE_BAUD}"
	parity="${3-CONSOLE_PARITY}"
	bits="${4-CONSOLE_BITS}"
	flow="${5-CONSOLE_FLOW}"
	term="${6-CONSOLE_SYSTEMD_SERIAL_GETTY_TERM}"

	# Set the default console device.
	if [[ -z "${CONSOLE_DEVICE}" && -n "${device}" ]]; then
		CONSOLE_DEVICE="${device}"
	fi

	# Create a Serial Getty in Linux via Systemd.
	systemd_serial_getty_console=(
		"${CONSOLE_SYSTEMD_SERIAL_GETTY_BIN}"
		"${CONSOLE_SYSTEMD_SERIAL_GETTY_ARGS[@]}"
		"${device}" "${baud}" "${term}"
	)

	CONSOLE_SYSTEMD_GETTY+=("${systemd_serial_getty_console[@]}")

	# Tell linux to use a Serial Console at Boot.
	CONSOLE_LINUX_CMDLINE+=("${device},${baud}${parity}${bits}${flow}")

	# Add the serial console to the VMDebootstrapArguments
	VMDebootstrapAddArgument "serial-console-command" \
	 	"${systemd_serial_getty_console[@]}"
}

function ConsoleSystemdGetty() {
	for device in ${CONSOLE_LINUX_CMDLINE}; do
		device="$(cut -d ',' -f1 <<<"${device}")"

		Exec "EnableSystemdConsoleSupport" \
			"systemctl enable serial-getty@${device}.service"
	done
}

function ConsoleLinuxCmdline() {
	for device in ${CONSOLE_LINUX_CMDLINE}; do
		GrubAppendEtcDefaultVar \
			"GRUB_CMDLINE_LINUX" \
			"console=${device}"
	done
}
