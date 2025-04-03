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

export NLS_TOKEN="$1"

# Determine absolute path to this script
script_path="$(realpath "${BASH_SOURCE[0]}")"

# Create a function that captures and replaces the command line.
modify_line() {
  local current_line="$READLINE_LINE"
  # Save the current command to history
  history -s "$current_line"

  echo -e "\n\e[32mEnglish to Pinguish translation is on the way...\e[0m"

  local os_name
  os_name="$(uname -o 2>/dev/null || uname -s)"
  local response
  response=$(curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $NLS_TOKEN" \
    -d "{\"message\": \"${current_line}\", \"os\": \"${os_name}\", \"shell\": \"bash\"}" \
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

# Ensure persistent config in ~/.bashrc.
if grep -q "# NLS_WIDGET_CONFIG_START" ~/.bashrc 2>/dev/null; then
  # Extract the current persistent configuration line containing the token.
  existing_line=$(grep "source \"$script_path\"" ~/.bashrc)
  # Assume the token is the third whitespace-separated field.
  existing_token=$(echo "$existing_line" | awk '{print $3}')
  if [[ "$existing_token" != "$NLS_TOKEN" ]]; then
    # Only update if the token is different.
    sed -i.bak "s|^source \"$script_path\" .*|source \"$script_path\" ${NLS_TOKEN}|" ~/.bashrc
    echo -e "\e[33mPersistent config updated with new NLS token in ~/.bashrc.\e[0m"
  fi
else
  # Append persistent configuration block if it doesn't exist.
  {
    echo ""
    echo "# NLS_WIDGET_CONFIG_START"
    echo "source \"$script_path\" ${NLS_TOKEN}"
    echo "# NLS_WIDGET_CONFIG_END"
  } >> ~/.bashrc
  echo -e "\e[33mPersistent config added to ~/.bashrc.\e[0m"
  echo -e "\e[33mEnter a plain English command and press Ctrl+T to convert it to a shell command.\e[0m"
fi
