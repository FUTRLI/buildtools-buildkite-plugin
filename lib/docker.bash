#!/bin/bash


# Show a prompt for a command
function plugin_prompt() {
    if [[ -z "${HIDE_PROMPT:-}" ]] ; then
        echo -ne '\033[90m$\033[0m' >&2
        printf " %q" "$@" >&2
        echo >&2
    fi
}

function redact_build_args() {
    echo "$@" | sed -E "s/(--build-arg )[^ ]*( |$)/\\1<redacted> /g"
}

# Shows the command being run, and runs it
function plugin_prompt_and_run() {
    # Redact build args from $call to prevent leaking secrets into the buildkite console
    output=$(redact_build_args "$@")
    plugin_prompt "${output}"
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
