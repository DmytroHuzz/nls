#!/usr/bin/env bats

# Path to the script under test
SCRIPT="$BATS_TEST_DIRNAME/../nls.zsh"

@test "script refuses to execute instead of source" {
  run zsh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"mast be sourced"* ]]
}

@test "script errors when missing token" {
  run zsh -c "source $SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}
