set_default_gemset() {
  if [ -n "${DEFAULT_GEMSET}" ]; then
    if [ ! "$GEM_PATH" == "${DEFAULT_GEMSET}" ]; then
      DEFAULT=$( basename $DEFAULT_GEMSET )
    fi

    if [ -n "$GEMSET" ] && [ ! "$GEMSET" == "$DEFAULT" ]; then
      remove_path "${GEMSET_ROOT}/${GEMSET}/bin"
    fi

    DEFAULT_BIN_PATH="${DEFAULT_GEMSET}/bin"

    export GEMSET="${DEFAULT}"
    export GEM_HOME="$DEFAULT_GEMSET"
    export GEMFILE="$DEFAULT_GEMSET"
    export GEM_ROOT="$GEM_HOME"
    export GEM_PATH="$GEM_HOME"

    add_path "$DEFAULT_BIN_PATH"
    using_gemset_via "*default"
  fi
}

using_gemset_via() {
  echo "Now using $GEMSET gemset via $1"
}

remove_path() {
  NEW_PATH=""
  IFS=':' read -a PATHS <<< "$PATH"
  for p in "${PATHS[@]}"
  do
    if [ ! "$p" == "$1" ]; then
      if [ -z "$NEW_PATH" ]; then
        NEW_PATH="$p"
      else
        NEW_PATH="$NEW_PATH:$p"
      fi
    fi
  done
  export PATH="$NEW_PATH"
}

add_path () {
  if ! echo $PATH | egrep -q "(^|:)$1($|:)" ; then
     if [ "$2" = "after" ] ; then
        PATH=$PATH:$1
     else
        PATH=$1:$PATH
     fi

     export PATH
  fi
}

auto_gemsets() {
  local dir="$PWD"

  until [[ -z "$dir" ]]; do
    GEMFILE="$dir/Gemfile"

    if [ -f "$GEMFILE" ]; then
      get_parent_dirname
      if [ "$GEMSET" == "$PARENT_DIR" ]; then
        break
      else
        set_gemset "$PARENT_DIR"
        break
      fi
    else
      if [ ! "$GEMSET" == "$DEFAULT" ]; then
        set_default_gemset
      fi
    fi

    dir="${dir%/*}"
  done
}

get_parent_dirname() {
  IFS='/' read -a gemfile_path_parts <<< "$GEMFILE"
  PARENT_DIR="${gemfile_path_parts[${#gemfile_path_parts[@]}-2]}"
}

set_gemset() {
  NEW_GEMSET="$1"
  NEW_GEMSET_PATH="${GEMSET_ROOT}/${1}"
  NEW_GEMSET_BIN_PATH="${NEW_GEMSET_PATH}/bin"
  remove_path "$GEMSET_BIN_PATH"
  create_gemset_if_missing "$NEW_GEMSET"
  export GEMSET="$NEW_GEMSET"
  export GEM_HOME="$NEW_GEMSET_PATH"
  export GEM_ROOT="$NEW_GEMSET_PATH"
  export GEM_PATH="$NEW_GEMSET_PATH:$DEFAULT_GEMSET"

  add_path "$DEFAULT_BIN_PATH"
  add_path "$NEW_GEMSET_BIN_PATH"

  using_gemset_via "$GEMFILE"
}

create_gemset_if_missing() {
  if [ ! -d "${GEMSET_ROOT}/${1}" ]; then
    mkdir -p "${GEMSET_ROOT}/${1}" && echo "${1} created. run gem install bundler"
  fi
}

# Create a GEMSET_ROOT if none is set
if [ ! -n "$GEMSET_ROOT" ]; then
  export GEMSET_ROOT="${HOME}/.gemsets"
fi

# If ZSH add precommand
if [[ -n "$ZSH_VERSION" ]]; then
  precmd_functions+=("auto_gemsets")
else
  # If there's already a prompt command,
  if [ -n "$PROMPT_COMMAND" ]; then
    # check if it's already in the PROMPT
    if [ ! "$PROMPT_COMMAND" == *auto_gemsets* ]; then
      PROMPT_COMMAND="$PROMPT_COMMAND; auto_gemsets"
    fi
  else
    PROMPT_COMMAND="auto_gemsets"
  fi
fi

# Set default when sourced
set_default_gemset