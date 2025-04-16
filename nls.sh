#!/bin/bash

# Return error if the script was not run with source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be sourced, not executed."
  return 1 2>/dev/null || exit 1
fi

# Validate and export the token
if [[ -z "$1" ]]; then
  echo "Usage: source ${BASH_SOURCE[0]} <NLS_TOKEN>"
  return 1
fi

context_file=''
if [ -n "$2" ] && [ -f "$2" ]; then
  # If a second argument is provided and it's a file, source it.
  context_file="$2"
fi

export NLS_TOKEN="$1"

# Determine absolute path to this script
script_path="$(realpath "${BASH_SOURCE[0]}")"

# Create a function that captures and replaces the command line.
modify_line() {
  local current_line="$(echo $READLINE_LINE | jq -Rs)"
  # Save the current command to history
  history -s $READLINE_LINE

  echo -e "\n\e[32mEnglish to Pinguish translation is on the way...\e[0m"

  local os_name
  os_name="$(uname -o 2>/dev/null || uname -s)"

  local context="\"\""
  if [[ -f $context_file ]]; then
    context=$(jq -Rs . < $context_file)
  fi

  local response
  response=$(curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $NLS_TOKEN" \
    -d "{\"context\": ${context},\"message\": ${current_line}, \"os\": \"${os_name}\", \"shell\": \"bash\"}" \
    -X POST https://ofbydj6brd.execute-api.us-east-1.amazonaws.com/default/nls_lambda)

  if [[ -z "$response" ]]; then
    echo -e "\e[31mError: No response from the API.\e[0m"
    return 1
  fi

  # Replace the command line with the API response
  READLINE_LINE="$response"
  READLINE_POINT=${#READLINE_LINE}
}

# Register the function with Readline by binding Ctrl+T to it.
bind -x '"\C-t": modify_line'


# Define the expected config block
expected_block=$(cat <<EOF
# NLS_WIDGET_CONFIG_START
source "$script_path" $1 $2
# NLS_WIDGET_CONFIG_END
EOF
)
# Check if the config block exists
if grep -q "# NLS_WIDGET_CONFIG_START" ~/.bashrc 2>/dev/null; then
  # Extract the current persistent configuration line containing the token.
  existing_block=$(sed -n '/# NLS_WIDGET_CONFIG_START/,/# NLS_WIDGET_CONFIG_END/p' ~/.bashrc)
  if [[ "$existing_block" != "$expected_block" ]]; then
    # Remove the old block if it's different
    sed -i '/# NLS_WIDGET_CONFIG_START/,/# NLS_WIDGET_CONFIG_END/d' ~/.bashrc
    echo -e "\e[33mPersistent config updated with new NLS token in ~/.bashrc.\e[0m"
  fi
fi

# Add the block if it wasn't found or was just deleted
if ! grep -q "# NLS_WIDGET_CONFIG_START" ~/.bashrc 2>/dev/null; then
  {
    echo "$expected_block"
  } >> ~/.bashrc

  echo -e "\e[33mPersistent config added to ~/.bashrc.\e[0m"
  echo -e "\e[33mEnter a plain English command and press Ctrl+T to convert it to shell command.\e[0m"
fi
