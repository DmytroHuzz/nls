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
  local current_line="$BUFFER"
  print -S "$current_line" # Save the command to history

  echo -e "\n\e[32mEnglish to Pinguish translation is on the way...\e[0m"

  local os_name="$(uname -o 2>/dev/null || uname -s)"

  local context=""
  if [[ -n context_file ]]; then
    context=$(jq -Rs . < ${context_file})
  fi

  local response
  response=$(curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $NLS_TOKEN" \
    -d "{\"context\": ${context}, \"message\": \"${current_line}\", \"os\": \"${os_name}\", \"shell\": \"zsh\"}" \
    -X POST https://ofbydj6brd.execute-api.us-east-1.amazonaws.com/default/nls_lambda)

  if [[ -z "$response" ]]; then
    echo -e "\e[31mError: No response from the API.\e[0m"
    return 1
  fi

  BUFFER="$response"
  CURSOR=${#BUFFER}
  zle redisplay
}

# Register the function as a ZLE widget.
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