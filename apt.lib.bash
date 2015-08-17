#!/bin/bash

APT_MIRRORS=()
APT_PROXY_BYPASS=()
APT_PROXY=""
APT_ARGS=("--force-yes" "-y")
APT_KEYF=()
APT_KEYS=()

PGP_SERVER="pgpkeys.mit.edu"

#
# Setup Functions
#

function __AptProxy() {
	if __NetTCPPortOpen 9999; then
		echo "Enabling Apt-Cacher Proxy on Port 9999"
		APT_PROXY="127.0.0.1:9999/"
	elif __NetTCPPortOpen 9977; then
		echo "Enabling Apt-P2P Proxy on Port 9977"
		APT_PROXY="127.0.0.1:9977/"
	elif __NetTCPPortOpen 3142; then
		echo "Enabling Apt-Cacher-NG Proxy on Port 3142"
		APT_PROXY="127.0.0.1:3142/"
	fi
}

#
# Helper Functions
#

function AptPrimaryMirror() {
	[[ ${#APT_MIRRORS[@]} -lt 1 ]] && return
	awk -F'%' '{print $1}' <<<"${APT_MIRRORS[0]}"
}

function AptPrimaryMirrorDistribution() {
	[[ ${#APT_MIRRORS[@]} -lt 1 ]] && return
	awk -F'%' '{print $2}' <<<"${APT_MIRRORS[0]}"
}

function AptProxyMirror() {
	local mirror
	mirror="$1"

	[[ -z "${mirror}" ]] && \
		mirror="$(AptPrimaryMirror)"

	AptProxyPrefix "${mirror}"
}

function AptProxyPrefix() {
	[[ ${APT_PROXY_DISABLED} -lt 1 ]] && \
		echo -n "http://${APT_PROXY}" || \
		echo -n "http://"

	[[ -n "$1" ]] && echo "$1"
}

function AptProxy() {
	local argument setProxy=0

	for argument in $@; do
		case "$argument" in
			disable) APT_PROXY_DISABLED=1;;
			enable)  APT_PROXY_DISABLED=0;;
			*) if [[ -n "${argument}" && ${setProxy} -lt 1 ]]; then
				APT_PROXY="${argument}"
				setProxy=1
			fi;;
		esac
	done

	if [[ -z "${APT_PROXY}" ]]; then
		echo "There is no available local Apt Proxy configured or detected." 1>&2
	fi

	echo "${APT_PROXY}"
}

#
# Build Config Functions
#

function AptRepo() {
	APT_MIRRORS+=("$(echo "$@" | tr ' ' '%')")
}

function AptNoProxy() {
	APT_PROXY_BYPASS+=($@)
}

function AptKey() {
	APT_KEYS+=($@)
}

function AptKeyFile() {
	APT_KEYF+=($@)
}

#
# Build Functions
#

function AptProxyConf() {
	local proxyDefined proxyConf proxyBypass awkProxyHost proxyHost proxyPort

	proxyDefined=0
	proxyConf="/etc/apt/apt.conf.d/01proxy"
	proxyBypass=""
	awkProxyHost='print "Acquire::HTTP::Proxy::"$0" \"DIRECT\";"'

	if [[ -n "$1" && -n "$2" ]]; then
		proxyHost="$1"
		proxyPort="$2"
		proxyDefined=1
	fi

	if [[ ${proxyDefined} -eq 1 ]]; then
		File "AptCache" "${proxyConf}" <<-EOF
		Acquire::HTTP::Proxy "${proxyHost}:${proxyPort}";
		$(xargs -n1 <<<"${APT_PROXY_BYPASS[@]}" | awk "{ ${awkProxyHost} }")
		EOF

		return 0
	fi

	Script <<-EOF
	if dpkg -l | grep apt-cacher-ng &>/dev/null; then
		echo 'Acquire::HTTP::Proxy "http://127.0.0.1:3142";' > ${proxyConf}
		xargs -n1 <<<"${APT_PROXY_BYPASS[@]}" | awk "{ ${awkProxyHost} }" >> ${proxyConf}
	elif dpkg -l | grep apt-p2p &>/dev/null; then
		echo 'Acquire::HTTP::Proxy "http://127.0.0.1:9977";' > ${proxyConf}
		xargs -n1 <<<"${APT_PROXY_BYPASS[@]}" | awk "{ ${awkProxyHost} }" >> ${proxyConf}
	elif dpkg -l | grep apt-cacher &>/dev/null; then
		echo 'Acquire::HTTP::Proxy "http://127.0.0.1:9999";' > ${proxyConf}
		xargs -n1 <<<"${APT_PROXY_BYPASS[@]}" | awk "{ ${awkProxyHost} }" >> ${proxyConf}
	fi
	EOF
}

function AptKeysImport() {
	[[ -n "${APT_KEYS[@]}" ]] && Script <<-EOF
	apt-key adv --keyserver ${PGP_SERVER} --recv-keys ${APT_KEYS[@]}
	EOF

	[[ -n "${APT_KEYF[@]}" ]] && Exec "AptKeyFiles" "apt-key add -" <<-EOF
	$(cat ${APT_KEYF[@]})
	EOF
}

function AptRepoSources() {
	[[ "$1" == 'no-proxy' ]] && APT_PROXY_DISABLED=1
	[[ -n "${APT_MIRRORS[@]}" ]] || return

	local debRepo awkDebRepo

	awkDebRepo=(
		"gsub (\"%\", \" \");"
		"print \"deb	 [arch=${VMDEBOOTSTRAP_ARCH}] $(AptProxyPrefix)\" \$0;"
		"print \"deb-src [arch=${VMDEBOOTSTRAP_ARCH}] $(AptProxyPrefix)\" \$0;"
	)

	File "AptRepos" "/etc/apt/sources.list" <<-EOF
	$(eval "tr ' ' '\n' <<<'${APT_MIRRORS[@]}' | awk -F'%' -- '{ ${awkDebRepo[@]} }'")
	EOF
}

function AptInstall() {
	local packages

	packages="$(timeout 1 cat <&0 | tr '\n' ' ' || true)"
	[[ -n "${packages}" ]] || return

	Script "AptInstall" <<-EOF
	export DFEBK="\\\$DEBIAN_FRONTEND"
	export DEBIAN_FRONTEND="noninteractive"
	apt-get update	${APT_ARGS[@]} $@
	apt-get upgrade ${APT_ARGS[@]} $@
	apt-get install ${APT_ARGS[@]} $@ ${packages}
	export DEBIAN_FRONTEND="\$DFEBK"
	DFEBK= ; unset DFEBK
	EOF
}

function AptCleanup() {
	Script "AptCleanup" <<-EOF
	apt-get autoremove ${APT_ARGS[@]} $@
	apt-get autoclean ${APT_ARGS[@]} $@
	apt-get purge ${APT_ARGS[@]} $@
	apt-get clean ${APT_ARGS[@]} $@
	EOF
}
