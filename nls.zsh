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

export NLS_TOKEN="$1"

# Determine absolute path to this script
script_path="$(realpath "$0")"

# Create a widget that captures and replaces the command line.
modify_line() {
  local current_line="$BUFFER"
  print -S "$current_line" # Save the command to history

  echo -e "\n\e[32mEnglish to Pinguish translation is on the way...\e[0m"

  local os_name="$(uname -o 2>/dev/null || uname -s)"
  local response
  response=$(curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $NLS_TOKEN" \
    -d "{\"message\": \"${current_line}\", \"os\": \"${os_name}\", \"shell\": \"zsh\"}" \
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

# Ensure persistent config in ~/.zshrc.
# The persistent block is marked between:
#   # NLS_WIDGET_CONFIG_START
#   ...
#   # NLS_WIDGET_CONFIG_END
if grep -q "# NLS_WIDGET_CONFIG_START" ~/.zshrc 2>/dev/null; then
  # Extract the current persistent configuration line containing the token.
  existing_line=$(grep "source \"$script_path\"" ~/.zshrc)
  # Assume the token is the third whitespace-separated field.
  existing_token=$(echo "$existing_line" | awk '{print $3}')
  if [[ "$existing_token" != "$NLS_TOKEN" ]]; then
    # Only update if the token is different.
    sed -i.bak "s|^source \"$script_path\" .*|source \"$script_path\" ${NLS_TOKEN}|" ~/.zshrc
    echo -e "\e[33mPersistent config updated with new NLS token in ~/.zshrc.\e[0m"
  fi
else
  # Append persistent configuration block if it doesn't exist.
  {
    echo ""
    echo "# NLS_WIDGET_CONFIG_START"
    echo "source \"$script_path\" ${NLS_TOKEN}"
    echo "# NLS_WIDGET_CONFIG_END"
  } >> ~/.zshrc
  echo -e "\e[33mPersistent config added to ~/.zshrc.\e[0m"
  echo -e "\e[33mEnter a plain English command and press Ctrl+T to convert it to shell command.\e[0m"

fi