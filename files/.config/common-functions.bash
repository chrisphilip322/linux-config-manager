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
    _mkvenv_impl "$1" "$(which python2.7) -m virtualenv"
}

function mkvenv3() {
    _mkvenv_impl "$1" "$(which python3) -m venv"
}

function json() {
    python2.7 -c 'import sys, json; j = json.load(sys.stdin); json.dump(j, sys.stdout, sort_keys=True, indent=4, separators=(",", ": ")); print ""'
}

function git-branch-status() {
    local RESET="$(tput sgr0)"
    local BOLD="$(tput bold)"
    local RED="$(tput setaf 9)"
    local GREEN="$(tput setaf 10)"
    local YELLOW="$(tput setaf 11)"
    local current_branch="$(git-current-branch 2> /dev/null)"
    if [[ -z "$current_branch" ]]
    then
        return 1
    fi

    local target_branch="$(git config custom.targetbranch)"
    if [[ -z ${target_branch} ]]
    then
        target_branch="master"
    fi
    git remote update origin > /dev/null 2>&1 &
    git ls-remote --heads --exit-code origin "$current_branch" > /dev/null
    local upstream_set_result=$?
    local statustext="$(git -c color.status=always status)"
    git rev-parse --abbrev-ref --symbolic-full-name @{u} > /dev/null 2>&1
    local upstream_name_result="$?"
    local commits_ahead="$(git rev-list --count "$current_branch" ^origin/${target_branch})"
    local commits_behind="$(git rev-list --count origin/${target_branch} "^$current_branch")"
    echo -ne "$YELLOW"
    pre-print "Updating origin..." wait
    echo -ne "$RESET"

    if [[ "$current_branch" == "${target_branch}" ]]
    then
        :
    else
        if [[ "$commits_ahead" == "0" ]]
        then
            echo -e "# ${BOLD}$current_branch${RESET} is ahead of ${BOLD}origin/${target_branch}${RESET} by ${GREEN}0 commits${RESET}"
        else
            echo -e "# ${BOLD}$current_branch${RESET} is ahead of ${BOLD}origin/${target_branch}${RESET} by ${YELLOW}$commits_ahead commits${RESET}"
        fi
        if [[ "$commits_behind" == "0" ]]
        then
            echo -e "# ${BOLD}$current_branch${RESET} is behind   ${BOLD}origin/${target_branch}${RESET} by ${GREEN}0 commits${RESET}"
        else
            echo -e "# ${BOLD}$current_branch${RESET} is behind   ${BOLD}origin/${target_branch}${RESET} by ${RED}$commits_behind commits${RESET}"
        fi
    fi
    if [[ "$upstream_name_result" != "0" ]]
    then
        if [[ $upstream_set_result == "0" ]]
        then
            echo -e "# ${RED}No upstream branch set${RESET}. Consider setting one with:"
            echo "#     git branch -u origin/${current_branch}"
        else
            echo -e "# ${YELLOW}No matching remote branch${RESET}. Consider pushing with this command to set upstream info:"
            echo "#     git push -u"
        fi
    fi
    echo -e "$statustext"
}

git-current-branch() {
    # https://github.com/sorin-ionescu/prezto/blob/master/modules/git/functions/git-branch-current
    if ! git rev-parse 2> /dev/null
    then
        echo "$0: not a repository: $PWD" >&2
        return 1
    fi
    local ref="$(git symbolic-ref HEAD 2> /dev/null)"
    if [[ -n "$ref" ]]
    then
        echo "${ref#refs/heads/}"
        return 0
    else
        return 1
    fi
}

source-pyenv() {
    local root=$1

    if [[ -z "$root" ]]
    then
        root=$HOME/.local/share/pyenv
    fi

    if [[ -z "$PYENV_ROOT" ]]
    then
        export PYENV_ROOT="$root"
        export PATH="$PATH:$PYENV_ROOT/bin"
        if command -v pyenv 1>/dev/null 2>&1; then
            eval "$(pyenv init -)"
        fi
    else
        echo "pyenv is already setup, cannot source twice" >&2
    fi
}

_tox_impl() {
    for var in "$@"
    do
        if [[ "$var" == "-l" ]] || [[ "$var" == "-a" ]] || [[ "$var" == "--notest" ]]
        then
            /usr/bin/env tox "$@"
            return $?
        fi
    done
    pushd $(git root) > /dev/null
    if ! [[ -a .tox ]] && [[ -f tox.ini ]]
    then
        mkdir .tox
    fi
    /usr/bin/env tox -l "$@" > .tox/last-run
    if /usr/bin/env tox "$@"
    then
        :
    else
        echo "last run failed" >> .tox/last-run
    fi
        git rev-parse HEAD >> .tox/last-run
    popd > /dev/null
}

detox() {
    _tox_impl -p auto "$@"
}

tox() {
    _tox_impl "$@"
}

_get_exit_code() {
    local EXIT="$?"
    if [[ "$EXIT" != "0" ]]
    then
        echo " $(tput setaf 9)(${EXIT})$(tput sgr0)"
    fi
}

function _set_default_ps1() {
    RESET="\[$(tput sgr0)\]"
    RED="\[$(tput setaf 9)\]"
    GREEN="\[$(tput setaf 2)\]"
    TEAL="\[$(tput setaf 14)\]"
    HOSTNAME_GREEN="\[$(tput setaf 46)\]"

    export PS1="${RED}\u${RESET}${GREEN}@${RESET}${HOSTNAME_GREEN}\h${RESET} ${GREEN}[${RESET}${TEAL}\w${RESET}${GREEN}]${RESET}\$(_get_exit_code)\n\$ "
}

# Source-able file to load all functions into shell
# Executable file that to run functions from not a shell
# Functions without "^function " are 'private' and not runnable externally

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    if [[ $(grep "^function ${1}() {$" $0) ]]
    then
        "$@"
    elif [[ $1 ]]
    then
        echo "$1 is not a valid function"
        exit 1
    else
        echo "Pass a function name and arguments to run that function"
        exit 1
    fi
fi
