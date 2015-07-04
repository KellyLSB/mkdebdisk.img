#!/bin/bash

LINES=0

#
# Setup Functions
#

function __Block() {
	local _count_lines _exec _name _owner _group _owner_group _block
	local _block _chmod _chown _to_files _fds _fds_out _touch

	_touch=0
	_count_lines=1
	_exec="cat"
	_chmod=()
	_chown=()
	_files=()
	_fds=()
	_fds_out=()
	_mkdir=()

	_block="$(timeout 1 cat -s <&0 || true)"

	eval set -- "$(getopt -a --name '__Block' --options 'c:C:f:e:n:O:m:o:g:h?' \
		--long 'no-count-lines:,count-lines:,to-file:,exec:,name:,fd:,mod:,owner:,group:,help' -- "$@")"

	while true; do
		case "$1" in
			-f|--to-file)        _to_files+=($2);     shift 2;;
			-e|--exec)           _exec=$2;            shift 2;;
			-n|--name)           _name=$2;            shift 2;;
			-m|--mod)            _mod=$2;             shift 2;;
			-o|--owner)          _owner=$2;           shift 2;;
			-g|--group)          _group=$2;           shift 2;;
			-O|--fd)             _fds+=($2);          shift 2;;
			-c|--no-count-lines) _count_lines=0;      shift 1;;
			-C|--count-lines)    _count_lines=1;      shift 1;;
			--)                  shift;               break  ;;
			-h|-?|--help)        echo "HELP"; return; shift 1;;
		esac
	done

	_name="EO_$(UtilToUpper "${_name}")"

	if [[ "${_exec}" == "cat" && -n "${_to_files}" && -z "${_block}" ]]; then
		_exec="touch ${_to_files[@]:0:1}"
		_to_files=(${_to_files[@]:1})
	fi

	for fn in ${_to_files[@]}; do
		if grep -q '>' <<<"${fn}"; then
			fd="$(cut -d'>' -f1 <<<"${fn}")"
			fn="$(cut -d'>' -f2 <<<"${fn}")"
		fi

		_mkdir+="mkdir -p \"\$(dirname \"${fn}\")\""

		if [[ -n "${_owner}" && -n "${_group}" ]]; then
			_chown+=("chown -c ${_owner}:${_group} ${fn}")
		fi

		if [[ -n ${_mod} ]]; then
			_chmod+=("chmod -c ${_mod} ${fn}")
		fi

		_fds_out+=("${fd}> ${fn}")
	done

	for fd in ${_fds[@]}; do
		if grep -Eq '^([0-9]+|&|)>&[0-9]+$' <<<"${fd}"; then
			_fds_out+=("${fd}")
		fi
	done

	if [[ -n "${_block}" ]]; then
		VALUE=`cat -s <<-EOF
		${_mkdir[@]}
		${_exec} <<-${_name} ${_fds_out[@]}
		${_block}
		${_name}
		${_chown[@]}
		${_chmod[@]}
		EOF`
	else
		VALUE=`cat -s <<-EOF
		${_mkdir[@]}
		${_exec} ${_fds_out[@]}
		${_chown[@]}
		${_chmod[@]}
		EOF`
	fi

	if [[ ${_count_lines} -gt 0 ]]; then
		LINES=$(( ${LINES} + $(wc -l <<<"${VALUE}") + 1 ))
	fi

	echo -e "${VALUE}\n"
}

#
# Build Functions
#

function Block() {
	__Block --name "$1" ${@:2}
}

function File() {
	__Block --name "$1" --to-file "$2" ${@:3}
}

function Exec() {
	__Block --name "$1" --exec "$2" ${@:3}
}

function Script() {
	__Block --name "$1" --exec "bash" ${@:3}
}
