# Set the window title
title() {
  print -Pn "\e]0;$1\a"
}

# Get the short name of this host.
__short_host () {
  echo -n "${$(hostname)/.*/}"
}

# Get the path of this host's terminal registration file
__terminal_file () {
  if [[ ! -f "$HOME/.terminals.$(__short_host)" ]]; then
    touch "$HOME/.terminals.$(__short_host)"
  fi
  echo -n "$HOME/.terminals.$(__short_host)"
}

# Get the list of all terminal numbers that are in use
__get_registered_terminals() {
  awk '{ if (!seen[$0]++ && $0 ~ /[0-9]+/) print }' $(__terminal_file) | sort
}

# Filter my terminal number out of all registered ones
__get_other_registered_terminals() {
  __get_registered_terminals | awk "{ if (\$0 != $TERMINALNUMBER) print }" | sort
}

# Dump the contents of TERMINALS to the terminal registration file
__dump_terminals() {
  if [ $#TERMINALS -gt 1 ]; then
    echo "$TERMINALS" | awk 'gsub(" ", "\n")' | sort > $(__terminal_file)
  elif [ $#TERMINALS -eq 1 ]; then
    echo "$TERMINALS" > $(__terminal_file)
  else
    rm $(__terminal_file)
  fi
}

# Print terminals
__print_terminals() {
  if [ $#TERMINALS -gt 1 ]; then
    echo "$TERMINALS" | awk 'gsub(" ", "\n")' | sort
  elif [ $#TERMINALS -eq 1 ]; then
    echo "$TERMINALS"
  else
    echo "EMPTY"
  fi
}

# Register this terminal with the lowest unused terminal number
__register_terminal() {
  TERMINALS=($(__get_registered_terminals))
  # Start at 1 and increment until we don't see the number in $TERMINALS($HOME/.terminals)
  idx=1
  if [ $#TERMINALS -gt 0 ]; then
    for tidx in $TERMINALS; do
      if [[ $idx -lt $tidx ]]; then
        break
      fi
      idx=$((idx+1))
    done
  fi
  TERMINALS+=($idx)
  __dump_terminals
  unset TERMINALS
  export TERMINALNUMBER=$idx
  REGISTERED=$TERMINALNUMBER;
  unset idx
}

# Remove this terminal from the registration file.
__unregister_terminal() {
  TERMINALS=($(__get_other_registered_terminals))
  __dump_terminals
  unset TERMINALS
}

# When we exit a terminal, make sure to clean up the registration etc
exit() {
  __unregister_terminal
  builtin exit
}

# Set a new static name when this window is spawned/sourced
__set_name() {
  if [[ ! $TERMINALNUMBER || ! $REGISTERED ]]; then
    __register_terminal
  fi
  title "zsh$TERMINALNUMBER - $(__short_host)"
}

trap exit SIGHUP SIGTERM SIGABRT
setopt ignoreeof
__set_name
