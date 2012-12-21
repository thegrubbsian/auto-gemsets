function create_or_switch_gemset() {
  if [ ! -d "${GEMSET_ROOT}/${GEMSET}" ]; then
    mkdir -p "${GEMSET_ROOT}/${GEMSET}" && echo "${GEMSET} created. run gem install bundler"
  fi

  switch_gemset
}

function switch_gemset() {
  export GEM_PATH="${GEMSET_PATH}"
  export GEM_HOME="${GEMSET_PATH}"
  export GEM_ROOT="${GEMSET_PATH}"
  echo "Now using ${GEMSET} gemset via ${GEMFILE}"
  break
}

function auto_gemsets() {
  local dir="$PWD"
  local version_file

  until [[ -z "$dir" ]]; do
    gemfile="$dir/Gemfile"
    IFS='/' read -a gemfile_path_parts <<< "$gemfile"

    gemset="${gemfile_path_parts[${#gemfile_path_parts[@]}-2]}"

    if   [[ "${GEMSET_PATH//:$DEFAULT_GEMSET}" == "${GEMSET_ROOT}/$gemset" ]]; then return
    elif [[ -f "$gemfile" ]]; then
      export GEMSET_PATH="${GEMSET_ROOT}/$gemset:${DEFAULT_GEMSET}"
      export GEMSET="${gemset}"
      export GEMFILE="${gemfile}"
      create_or_switch_gemset
    fi

    dir="${dir%/*}"
  done
}

if [ ! -n "$GEMSET_ROOT" ]; then
  export GEMSET_ROOT="${HOME}/.gemsets"
fi

if [[ -n "$ZSH_VERSION" ]]; then
  precmd_functions+=("auto_gemsets")
else
  if [[ -n "$PROMPT_COMMAND" ]]; then
    if [[ ! "$PROMPT_COMMAND" == *auto_gemsets* ]]; then
      PROMPT_COMMAND="$PROMPT_COMMAND; auto_gemsets"
    fi
  else
    PROMPT_COMMAND="auto_gemsets"
  fi
fi