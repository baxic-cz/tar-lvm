#!/bin/bash

###############################################################################
#
# script: install.sh
# author: Lukas Baxa alias Baxic <baxic-cs@seznam.cz>
#
# This script is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
###############################################################################


# set program name
PROGNAME='install.sh'
PNSPACES='          '

# set versions
SCRIPT_VERSION='00.22'
SUITE_VERSION='00.80'


# installation directories and files
CHECK_DIRS=(
    '700:/usr/local/sbin'
    '700:/usr/local/etc'
    '700:/usr/local/share'
    '700:/usr/local/share/doc'
    '700:/var/local'
)

CREATE_DIRS=(
    '750:/usr/local/etc/tar-lvm'
    '755:/usr/local/share/doc/tar-lvm'
    '750:/var/local/tar-lvm'
    '750:/var/local/tar-lvm/mnt'
    '750:/var/local/tar-lvm/tmp'
    '750:/var/local/tar-lvm/tmpfs'
    '750:/var/local/ssd-backup'
)

INSTALL_FILES_ONE=(
    '755:sbin/bgrun:/usr/local/sbin/bgrun'
    '755:sbin/cmdsend:/usr/local/sbin/cmdsend'
    '755:sbin/ssd-backup:/usr/local/sbin/ssd-backup'    
    '755:sbin/tar-lvm:/usr/local/sbin/tar-lvm'    
    '755:sbin/tar-lvm-one:/usr/local/sbin/tar-lvm-one'
    '644:doc/00-backing-up-with-tar.html:/usr/local/share/doc/tar-lvm/00-backing-up-with-tar.html'
    '644:doc/01-overview.html:/usr/local/share/doc/tar-lvm/01-overview.html'
    '644:doc/02-preparing-for-the-backup.html:/usr/local/share/doc/tar-lvm/02-preparing-for-the-backup.html'
    '644:doc/03-installation.html:/usr/local/share/doc/tar-lvm/03-installation.html'
    '644:doc/04-configuration.html:/usr/local/share/doc/tar-lvm/04-configuration.html'
    '644:doc/05-triggering-the-backup.html:/usr/local/share/doc/tar-lvm/05-triggering-the-backup.html'
    '644:doc/06-restoring-the-backup.html:/usr/local/share/doc/tar-lvm/06-restoring-the-backup.html'
    '644:doc/07-removal.html:/usr/local/share/doc/tar-lvm/07-removal.html'
    '644:doc/tar-lvm-deployment-scheme.png:/usr/local/share/doc/tar-lvm/tar-lvm-deployment-scheme.png'
    '644:doc/tar-lvm-filesystem-prerequisities.png:/usr/local/share/doc/tar-lvm/tar-lvm-filesystem-prerequisities.png'
)

CONFIG_FILES_ONE=(
    '600:etc/ssd-backup.conf:/usr/local/etc/ssd-backup.conf'
    '600:etc/tar-lvm/tar-lvm.conf:/usr/local/etc/tar-lvm/tar-lvm.conf'
    '600:etc/tar-lvm/tar-lvm-one.local.conf:/usr/local/etc/tar-lvm/tar-lvm-one.local.conf'
)

INSTALL_FILES_ALL=(
    '755:sbin/tar-lvm-all:/usr/local/sbin/tar-lvm-all'
)

CONFIG_FILES_ALL=(
    '600:etc/tar-lvm/tar-lvm-one.shared.conf:/usr/local/etc/tar-lvm/tar-lvm-one.shared.conf'
    '600:etc/tar-lvm/tar-lvm-all.conf:/usr/local/etc/tar-lvm/tar-lvm-all.conf'
)


# check_tools() tool1 ... toolN
#   check if all the external tools tool1 ... toolN are available on the system
# return: exit - some of the tools are missing
#         0 - ok
check_tools() {

    local fail fst
    local tool

    if ! which which >/dev/null 2>&1; then
	echo "$PROGNAME: cannot find the 'which' command that is necessary" >&2
	exit 2
    fi

    fail=1
    fst=0
    for tool in "$@"; do
	if ! which "$tool" >/dev/null 2>&1; then
	    if [[ "$fst" = 0 ]]; then
		echo "$PROGNAME: cannot find the following tools/commands that are necessary" >&2
		fst=1
	    fi
	    echo "  '$tool'" >&2
	    fail=0
	fi
    done

    [[ "$fail" = 0 ]] && exit 2
    return 0

}


# usage() [exit_code]
#   print the usage info and exit with given exit code (default 0)
# return: exit
usage() {

    local ec="${1:-0}"
    if [[ "$ec" != 0 ]]; then
	exec >&2
    fi
    
    echo "$PROGNAME - install tar-lvm suite"
    echo
    echo "    ($PROGNAME version: $SCRIPT_VERSION, tar-lvm suite version: $SUITE_VERSION)"
    echo
    echo "usage: $PROGNAME -h | help"
    echo "       $PROGNAME install [one|all]"
    echo "       $PROGNAME remove"
    echo "       $PROGNAME purge"
    echo
    echo '    -h | help ... print help and exit'
    echo '    install one ... install tar-lvm suite for one machine, i.e.'
    echo '                    not tar-lvm-all script'
    echo '    install all ... install tar-lvm suite for all machines, i.e.'
    echo '                    all tar-lvm scripts including tar-lvm-all'
    echo '    remove ... remove tar-lvm suite, keep configuration'
    echo '    purge ... remove tar-lvm suite including configuration'
    echo
    
    exit "$ec"
    
}


# parse_args() arg1 ... argN
#   parse the command-line arguments and set the global variables ARG_MODE
#   and ARG_SUBMODE
# return: exit - wrong arguments are given
#         0 - ok
parse_args() {

    unset ARG_MODE
    unset ARG_SUBMODE

    [[ $# -eq 0 ]] && usage 1

    if [[ "$1" = '-h' || "$1" = 'help' || "$1" = 'install' ||
		"$1" = 'remove' || "$1" = 'purge' ]]; then
	ARG_MODE="$1"
	[[ "$ARG_MODE" = '-h' ]] && ARG_MODE='help'
    else
	usage 1
    fi

    if [[ "$ARG_MODE" = 'install' ]]; then
	[[ $# -ne 2 ]] && usage 1
	if [[ "$2" = 'one' || "$2" = 'all' ]]; then
	    ARG_SUBMODE="$2"
	else
	    usage 1
	fi
    else
	[[ $# -ne 1 ]] && usage 1	
    fi
	    
    return 0
    
}


# check_root_id()
#   check that the command is called by root
# return: exit - the command is not called by root
#         0 - ok or clean exit in progress
check_root_id() {

    if [[ $(id -u) != 0 ]]; then
	echo "$PROGNAME: you must be root in order to use this script" >&2
	exit 2
    fi

    return 0

}


# check_dirs()
#   check that all required directories exist and that they have correct
#   permissions
# return: exit - some required directory is missing or doesn't have all
#                required permissions
#         0 - ok
check_dirs() {

    local ec=0
    local pd perm dir

    for pd in "${CHECK_DIRS[@]}"; do
	perm="$(echo "$pd" | cut -d: -f1)"
	dir="$(echo "$pd" | cut -d: -f2-)"

	if [[ ! -d "$dir" ]]; then
	    echo "$PROGNAME: directory '$dir' not found" >&2
	    ec=3
	    continue
	fi

	if [[ "$(find "$dir" -maxdepth 0 -perm "-$perm" | wc -l)" = 0 ]]; then
	    echo "$PROGNAME: directory '$dir' doesn't have all required" >&2
	    echo "$PNSPACES  permission bits '$perm'" >&2
	    ec=3
	    continue
	fi	
    done
    
    [[ "$ec" != 0 ]] && exit "$ec"
    return 0

}


# create_dirs()
#   create all installation directories with proper permissions if they don't
#   exist
# return: exit - cannot create installation directories with proper
#                permissions
#         0 - ok
create_dirs() {

    local pd perm dir
    declare -a arr

    eval 'arr=(' $(printf '%s\n' "${CREATE_DIRS[@]}" | sed -r -e 's#^#"#' -e 's#$#"#' | sort -t : -k 2) ')'

    for pd in "${arr[@]}"; do
	perm="$(echo "$pd" | cut -d: -f1)"
	dir="$(echo "$pd" | cut -d: -f2-)"
	
	mkdir -p -m "$perm" "$dir"
	if [[ $? -ne 0 ]]; then
	    echo "$PROGNAME: cannot create directory '$dir'" >&2
	    exit 4
	fi	
    done
    
    return 0
    
}


# install_files() ['one'|'all']
#   copy installation files into their destination and set permissions,
#   then copy configuration files as well if they don't exist or
#   to alternate files with the '.new' suffix if they already exist
# return: exit - cannot copy files or set permissions
#         0 - ok
install_files() {

    local mode="$1"
    local psd perm src dst
    declare -a arr_f tmparr_f arr_c tmparr_c

    if [[ "$mode" = 'all' ]]; then
	tmparr_f=("${INSTALL_FILES_ALL[@]}")
	tmparr_c=("${CONFIG_FILES_ALL[@]}")
    fi
    arr_f=("${INSTALL_FILES_ONE[@]}" "${tmparr_f[@]}")
    arr_c=("${CONFIG_FILES_ONE[@]}" "${tmparr_c[@]}")
    
    for psd in "${arr_f[@]}"; do
	perm="$(echo "$psd" | cut -d: -f1)"
	src="$(echo "$psd" | cut -d: -f2)"
	dst="$(echo "$psd" | cut -d: -f3-)"

	cp "$RUNDIR/install/$src" "$dst"
	if [[ $? -ne 0 ]]; then
	    echo "$PROGNAME: cannot copy installation file: " >&2
	    echo "$PNSPACES   - src: '$src'" >&2
	    echo "$PNSPACES   - dst: '$dst'" >&2
	    exit 5
	fi

	chmod "$perm" "$dst"
	if [[ $? -ne 0 ]]; then
	    echo "$PROGNAME: cannot set permissions on file '$dst'" >&2
	    exit 5
	fi
    done

    for psd in "${arr_c[@]}"; do
	perm="$(echo "$psd" | cut -d: -f1)"
	src="$(echo "$psd" | cut -d: -f2)"
	dst="$(echo "$psd" | cut -d: -f3-)"

	if [[ ! -e "$dst" ]]; then
	    cp "$RUNDIR/install/$src" "$dst"
	    if [[ $? -ne 0 ]]; then
		echo "$PROGNAME: cannot copy installation file: " >&2
		echo "$PNSPACES   - src: '$src'" >&2
		echo "$PNSPACES   - dst: '$dst'" >&2
		exit 5
	    fi

	    chmod "$perm" "$dst"
	    if [[ $? -ne 0 ]]; then
		echo "$PROGNAME: cannot set permissions on file '$dst'" >&2
		exit 5
	    fi	    
	else
	    cp "$RUNDIR/install/$src" "$dst.new"
	    if [[ $? -ne 0 ]]; then
		echo "$PROGNAME: cannot copy installation file: " >&2
		echo "$PNSPACES   - src: '$src'" >&2
		echo "$PNSPACES   - dst: '$dst.new'" >&2
		exit 5
	    fi
	    
	    chmod "$perm" "$dst.new"
	    if [[ $? -ne 0 ]]; then
		echo "$PROGNAME: cannot set permissions on file '$dst.new'" >&2
		exit 5
	    fi
	fi
    done
    
    return 0

}


# remove_files()
#   remove all installed files, but keep configuration files
# return: 1 - at least one file cannot be removed
#         0 - ok
remove_files() {

    local ec=0
    local psd dst
    
    for psd in "${INSTALL_FILES_ONE[@]}" "${INSTALL_FILES_ALL[@]}"; do
	dst="$(echo "$psd" | cut -d: -f3-)"

	rm -f "$dst"
	if [[ $? -ne 0 ]]; then
	    echo "$PROGNAME: cannot remove installed file '$dst'" >&2
	    ec=1
	fi
    done
    
    return "$ec"

}


# purge_files()
#   remove all configuration files including those with the '.new' suffix
# return: 1 - cannot remove all configuration files
#         0 - ok
purge_files() {

    local ec=0
    local psd dst
    
    for psd in "${CONFIG_FILES_ONE[@]}" "${CONFIG_FILES_ALL[@]}"; do
	dst="$(echo "$psd" | cut -d: -f3-)"

	rm -f "$dst"
	if [[ $? -ne 0 ]]; then
	    echo "$PROGNAME: cannot remove installed file '$dst'" >&2
	    ec=1
	fi

	rm -f "$dst.new"
	if [[ $? -ne 0 ]]; then
	    echo "$PROGNAME: cannot remove installed file '$dst.new'" >&2
	    ec=1
	fi
    done
    
    return "$ec"

}


# remove_dirs()
#   remove all installation directories if they're empty
# return: 1 - cannot remove installation directories
#         0 - ok
remove_dirs() {

    local ec=0
    local pd dir
    local cont
    declare -a arr
    
    eval 'arr=(' $(printf '%s\n' "${CREATE_DIRS[@]}" | sed -r -e 's#^#"#' -e 's#$#"#' | sort -t : -k 2 -r) ')'
    
    for pd in "${arr[@]}"; do
	dir="$(echo "$pd" | cut -d: -f2-)"

	if [[ -d "$dir" ]]; then
	    
	    cont="$(find "$dir" | sed -r "s#^#$PNSPACES   - #")"
	
	    if [[ "$(echo "$cont" | wc -l)" != 1 ]]; then
		echo "$PROGNAME: keeping directory '$dir', not empty:" >&2
		echo "$cont"
	    else
		rmdir "$dir"
		if [[ $? -ne 0 ]]; then
		    echo "$PROGNAME: cannot remove directory '$dir'" >&2
		    ec=1
		fi		    
	    fi

	elif [[ -f "$dir" ]]; then
	    echo "$PROGNAME: file '$dir' not a directory" >&2
	    ec=1
	fi
	
    done
    
    return "$ec"
    
}


### main

check_tools id find printf sed sort mkdir cp chmod rm rmdir

parse_args "$@"
[[ "$ARG_MODE" = 'help' ]] && usage

check_root_id

EC=0
RUNDIR="$(dirname "$0")"


case "$ARG_MODE" in
    'install')
	check_dirs
	[[ $? -ne 0 ]] && EC=3
	create_dirs
	[[ $? -ne 0 ]] && EC=4
	install_files "$ARG_SUBMODE"
	[[ $? -ne 0 ]] && EC=5
	;;
    'remove')
	remove_files
	[[ $? -ne 0 ]] && EC=6
	remove_dirs
	[[ $? -ne 0 ]] && EC=8
	;;
    'purge')
	remove_files
	[[ $? -ne 0 ]] && EC=6
	purge_files
	[[ $? -ne 0 ]] && EC=7
	remove_dirs
	[[ $? -ne 0 ]] && EC=8
	;;
esac


### exit
exit "$EC"
