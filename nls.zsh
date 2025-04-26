#!/bin/zsh

# Return error if the script was not run with source
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  echo "This script must be sourced, not executed."
  return 1
fi

# Validate and export the token
if [[ -z "$1" ]]; then
  echo "Usage: source $0 <NLS_TOKEN>"
  return 1
fi

context_file=''
if [ -n "$2" ] && [ -f "$2" ]; then
  # If a second argument is provided and it's a file, source it.
  context_file="$2"
fi

export NLS_TOKEN="$1"

# Determine absolute path to this script
script_path="$(realpath "$0")"

# Create a widget that captures and replaces the command line.
modify_line() {
  setopt localoptions NOMONITOR
  # Save the current buffer and command history
  print -S $BUFFER
  # Escape the full line for JSON
  local current_line
  current_line=$(echo $BUFFER | jq -Rs)

  local context="\"\""
  if [[ -f $context_file ]]; then
    context=$(jq -Rs . < $context_file)
  fi
  # Inform the user and set up output via the real terminal
  # Prepare a temporary file for the API response
  local tmpfile
  tmpfile=$(mktemp /tmp/nls.XXXXXX) || { echo "Error: Cannot create temp file" >/dev/tty; return 1; }

  # Fire off the API call in the background
  curl -sS -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $NLS_TOKEN" \
    -d "{\"context\":${context},\"message\":${current_line},\"os\":\"$(uname -s)\",\"shell\":\"zsh\"}" \
    -X POST https://ofbydj6brd.execute-api.us-east-1.amazonaws.com/default/nls_lambda \
    >"$tmpfile" 2>/dev/null &
  local pid=$!

  # Spinner loop on the real terminal
  local spin_chars=('|' '/' '-' '\')
  while kill -0 $pid 2>/dev/null; do
    for c in "${spin_chars[@]}"; do
      printf "\r\e[32m  English to Pinguish translation is on the way... \e[0m%s" "$c" >/dev/tty
      sleep 0.1
    done
  done
  printf "\r \r\e[K" >/dev/tty

  wait $pid

  # Read and remove the temp file
  local response
  response=$(<"$tmpfile")
  rm -f "$tmpfile"

  if [[ -z "$response" ]]; then
    echo -e "\e[31mError: No response from the API.\e[0m" >/dev/tty
    return 1
  fi
  # Replace buffer and redisplay
  BUFFER=$response
  CURSOR=${#BUFFER}
  zle redisplay
}
zle -N modify_line
bindkey '^T' modify_line

# Define the expected config block
expected_block=$(cat <<EOF
# NLS_WIDGET_CONFIG_START
source "$script_path" $1 $2
# NLS_WIDGET_CONFIG_END
EOF
)

# Check if the config block exists
if grep -q "# NLS_WIDGET_CONFIG_START" ~/.zshrc 2>/dev/null; then
  # Extract the existing block from the file
  existing_block=$(sed -n '/# NLS_WIDGET_CONFIG_START/,/# NLS_WIDGET_CONFIG_END/p' ~/.zshrc)

  if [[ "$existing_block" != "$expected_block" ]]; then
    # Remove the old block if it's different
    sed -i '' '/# NLS_WIDGET_CONFIG_START/,/# NLS_WIDGET_CONFIG_END/d' ~/.zshrc
    echo -e "\e[33mPersistent config updated with new NLS token in ~/.zshrc.\e[0m"
  fi
fi

# Add the block if it wasn't found or was just deleted
if ! grep -q "# NLS_WIDGET_CONFIG_START" ~/.zshrc 2>/dev/null; then
  {
    echo "$expected_block"
  } >> ~/.zshrc

  echo -e "\e[33mPersistent config added to ~/.zshrc.\e[0m"
  echo -e "\e[33mEnter a plain English command and press Ctrl+T to convert it to shell command.\e[0m"
fi