#
# From   https://blog.brujordet.no/post/bash/debugging_bash_like_a_sire
#
trap 'log::error "An error has occurred."' ERR

function log::_write_log {
    local timestamp file function_name log_level
    log_level=$1
    shift
    if log::level_is_active "$log_level"; then
        timestamp=$(/bin/date +"%y.%m.%d %H:%M:%S")
        file="${BASH_SOURCE[2]##*/}"
        function_name="${FUNCNAME[2]}"
        >&2 printf '%s [%s] [%s - %s]: %s\n' \
            "$log_level" "$timestamp" "$file" "$function_name" "${*}"
    fi
}

function log::debug {
    log::_write_log "DEBUG" "$@"
}
function log::info {
    log::_write_log "INFO" "$@"
}
function log::warn {
    log::_write_log "WARN" "$@"
}

function log::level_is_active {
    local check_level=${1:-NONE}
    local context_level=${LOG_LEVEL:-NONE}
    declare -A log_levels=(
        [DEBUG]=1
        [INFO]=2
        [WARN]=3
        [ERROR]=4
    )
    if [[ -v "log_levels[$check_level]" ]]; then
        check_level="${log_levels["$check_level"]}"
    else
        >&2 printf "FATAL %s\n" "Programming error, invalid log level; ${check_level}."
        exit 1
    fi
    if [[ -v "log_levels[$context_level]" ]]; then
        context_level="${log_levels["$context_level"]}"
    else
        if [[ "NONE" != "$context_level" ]]; then
            >&2 printf "WARNING %s\n" "Unknown log level; ${context_level}."
        fi
        (( context_level = 100 + check_level ))
    fi
    #printf "  Levels  test %d. >= %d.\n"  $check_level  $context_level
    (( check_level >= context_level ))
}

function log::error {
    log::_write_log "ERROR" "$@"
    local stack_offset=1
    printf "%s:\n" "Stacktrace:" >&2
    for stack_id in "${!FUNCNAME[@]}"; do
        if [[ "$stack_offset" -le "$stack_id" ]]; then
            local source_file="${BASH_SOURCE[$stack_id]}"
            local function="${FUNCNAME[$stack_id]}"
            local line="${BASH_LINENO[$(( stack_id - 1 ))]}"
            >&2 printf "\t%s:%s:%s\n" "$source_file" "$function" "$line"
        fi
    done
}

## END
