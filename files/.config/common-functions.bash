#!/bin/env bash

function print-func() {
    declare -f $1
    echo $1
}

function mkd() {
    mkdir -p $1
    cd $1
}

function which() {
    /usr/bin/which $1 2> /dev/null || type $1 2> /dev/null && return 0 || echo "Nothing named '$1' was found." >&2 && return 1
}

_list_swap_directories() {
    local IFS=$'\n'
    files=$(git ls-tree -r $(git rev-parse --abbrev-ref HEAD) --name-only)
    for f in $files
    do
        d=$(dirname -- $f)
        b=$(basename $f)
        swp=".${b}.swp"
        swp_full="${d}/${swp}"
        test -a $swp_full && readlink -f $d
    done | uniq
}

_check_for_unsaved_changes_impl() {
    local IFS=$'\n'
    if [[ $1 ]]
    then
        cd $1
    fi
    dirs_to_check=$(_list_swap_directories)
    result=$(for i in $dirs_to_check; do bash -c "cd $i && vim -r 2>&1"; done | grep "owned by: $USER" -A2 | grep "modified: YES" -B1 | grep "file name" | cut -d':' -f2 | cut -d' ' -f2)
    if [ "$result" != "" ]
    then
        echo "$(tput setaf 3)WARNING: You have unsaved changes!!!"
        echo ""
        for i in $result; do echo $i; done
        echo "$(tput sgr0)"
        return 1
    fi
}

function check_for_unsaved_changes() {
    pre-print "Checking for unsaved changes..." _check_for_unsaved_changes_impl "$@"
}

function repeat() {
    local str=$1
    local count=$2
    printf "%0.s${str}" $(seq 1 $count)
}

function pre-print() {
    local str=$1
    local cmd=$2
    printf "$str"
    local output=$($cmd "${@:3}")
    repeat \\b ${#str}
    repeat " " ${#str}
    repeat \\b ${#str}
    printf "${output}"
}

function f() {
    local target_dir="$1"
    find "$target_dir" -type d \( -path "*/node_modules" -o -path "*/venv*" -o -path "*/.tox" -o -path "*/.git" -o -path "*/.eggs" \) -prune -o -print
}

_mkvenv_impl() {
    local venv_name="$1"
    local venv_command="$2"

    if [[ -z "$venv_name" ]]
    then
        venv_name="./venv"
    fi
    if [[ -d "$venv_name" ]]
    then
        echo "There is already a folder at '$venv_name', can't create a new venv there" >&2
        return 1
    fi
    cmd="${venv_command} ${venv_name} && ${venv_name}/bin/pip install --upgrade pip && ${venv_name}/bin/pip install --upgrade setuptools"
    echo $cmd
    bash -c "$cmd"
    source "${venv_name}/bin/activate"
}

function mkvenv() {
    _mkvenv_impl "$1" "python2.7 -m virtualenv"
}

function mkvenv3() {
    _mkvenv_impl "$1" "python3 -m venv"
}

function json() {
    python2.7 -c 'import sys, json; j = json.load(sys.stdin); json.dump(j, sys.stdout, sort_keys=True, indent=4, separators=(",", ": ")); print ""'
}
