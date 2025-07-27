#
# From   https://blog.brujordet.no/post/bash/debugging_bash_like_a_sire
#

function log::info {
  log::_write_log "INFO" "$@"
}

function log::level_is_active {
  local check_level current_level
  check_level=$1

  declare -A log_levels=(
    [DEBUG]=1
    [INFO]=2
    [WARN]=3
    [ERROR]=4
  )

  check_level="${log_levels["$check_level"]}"
  current_level="${log_levels["$LOG_LEVEL"]}"

  (( check_level >= current_level ))
}



function log::_write_log {
  local timestamp file function_name log_level
  log_level=$1
  shift

  if log::level_is_active "$log_level"; then
    timestamp=$(date +'%y.%m.%d %H:%M:%S')
    file="${BASH_SOURCE[2]##*/}"
    function_name="${FUNCNAME[2]}"
    >&2 printf '%s [%s] [%s - %s]: %s\n' \
      "$log_level" "$timestamp" "$file" "$function_name" "${*}"
  fi
}



function log::error {
  log::_write_log "ERROR" "$@"
  local stack_offset=1
  printf '%s:\n' 'Stacktrace:' >&2

  for stack_id in "${!FUNCNAME[@]}"; do
    if [[ "$stack_offset" -le "$stack_id" ]]; then
      local source_file="${BASH_SOURCE[$stack_id]}"
      local function="${FUNCNAME[$stack_id]}"
      local line="${BASH_LINENO[$(( stack_id - 1 ))]}"
      >&2 printf '\t%s:%s:%s\n' "$source_file" "$function" "$line"
    fi
  done
}


trap 'log::error "An error has occurred"' ERR


log::info "Dude"
