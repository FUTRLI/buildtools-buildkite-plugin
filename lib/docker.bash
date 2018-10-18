#!/bin/bash


# Show a prompt for a command
function plugin_prompt() {
  if [[ -z "${HIDE_PROMPT:-}" ]] ; then
    echo -ne '\033[90m$\033[0m' >&2
    printf " %q" "$@" >&2
    echo >&2
  fi
}

# Shows the command being run, and runs it
function plugin_prompt_and_run() {
  plugin_prompt "$@"
  "$@"
}

# Shows the command about to be run, and exits if it fails
function plugin_prompt_and_must_run() {
  plugin_prompt_and_run "$@" || exit $?
}

function run_docker {
    local command=(docker)

    if [[ "${TRACE:-off}" =~ (1|on) ]] ; then
        command+=(--verbose)
    fi

    plugin_prompt_and_run "${command[@]}" "$@"
}
