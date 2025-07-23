zmodload zsh/zutil
autoload -Uz add-zsh-hook

# --- Command duration tracking ---
function track_command_start {
  CMD_START=$EPOCHREALTIME
}
add-zsh-hook preexec track_command_start

function print_command_timestamp {
  zmodload zsh/datetime
  local now_epoch=$(printf "%.0f" "$EPOCHREALTIME")
  local now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  print -P "%F{8}→ [$now_iso | $now_epoch]%f"
}
add-zsh-hook preexec print_command_timestamp

function print_prompt_timestamp {
  local now_epoch=$(printf "%.0f" "$EPOCHREALTIME")
  local now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local threshold_ms=${CMD_DURATION_THRESHOLD:-2000}
  local duration_str=""
  if (( CMD_DURATION > threshold_ms )); then
    duration_str=" ⏱ ${CMD_DURATION}ms"
  fi

  print -P "%F{8}↩ [$now_iso | $now_epoch]$duration_str%f"
}
add-zsh-hook precmd print_prompt_timestamp

function build_git_prompt {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return
  fi

  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || echo "detached")

  # Git porcelain status
  local git_status
  git_status=$(git status --porcelain=v1 --branch 2>/dev/null)

  local staged="" unstaged="" untracked="" ahead="" behind="" upstream=""

  # Flags for modified files
  if echo "$git_status" | grep -qE '^.M|^M '; then
    unstaged="!"
  fi
  if echo "$git_status" | grep -qE '^M|^A|^R|^C|^D'; then
    staged="+"
  fi
  if echo "$git_status" | grep -q '^??'; then
    untracked="?"
  fi

  # Conditionally show upstream/remote info
  if [[ "${SHOW_GIT_AHEAD_BEHIND:-0}" != "0" ]]; then
    local branch_line
    branch_line=$(echo "$git_status" | head -n 1)

    if [[ "$branch_line" =~ \[.*:([^\]]+)\] ]]; then
      upstream="→ ${match[1]}"
    fi
    if [[ "$branch_line" =~ ahead\ ([0-9]+) ]]; then
      ahead="↑${match[1]}"
    fi
    if [[ "$branch_line" =~ behind\ ([0-9]+) ]]; then
      behind="↓${match[1]}"
    fi
  fi

  local indicators="${staged}${unstaged}${untracked}${ahead:+ $ahead}${behind:+ $behind}${upstream:+ $upstream}"
  git_info="%F{5}⊙ $branch${indicators:+ $indicators}"
}



# --- Build the full prompt in precmd ---
function precmd() {
  local last_exit=$?
  local duration=""
  local venv_info=""
  local python_version=""
  local cwd_short=""
  local git_info=""
  local status_str=""
  local color_reset="%f%k"

  # --- Exit status ---
  if (( last_exit != 0 )); then
    status_str="%F{5}✘ $last_exit"
  fi

  # --- Venv or uv ---
  if [[ -n "$VIRTUAL_ENV" ]]; then
    venv_info="%F{2}(${VIRTUAL_ENV:t})"
  elif [[ -f "pyproject.toml" && -d ".venv" ]]; then
    venv_info="%F{2}(uv)"
  fi

  # --- Python version from .tool-versions ---
  local asdf_file=""
  if git rev-parse --show-toplevel &>/dev/null; then
    asdf_file="$(git rev-parse --show-toplevel)/.tool-versions"
  elif [[ -f ".tool-versions" ]]; then
    asdf_file=".tool-versions"
  fi
  if [[ -f "$asdf_file" ]]; then
    local py_ver="$(awk '/^python / {print $2}' "$asdf_file")"
    [[ -n "$py_ver" ]] && python_version="%F{2}[py $py_ver]"
  fi

  # --- Shortened working directory ---
  cwd_short="%F{4}%~"

  git_info=""
  build_git_prompt

  # --- First line: metadata and status ---
  local meta_line="%{$status_str${status_str:+ } $venv_info${venv_info:+ }$python_version${python_version:+ }$cwd_short${cwd_short:+ } $git_info$color_reset%}"

  # --- Second line: prompt character ---
  local prompt_char="%F{black}%# %f"

  PROMPT="${meta_line}"$'\n'"${prompt_char}"
}

