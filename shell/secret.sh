#!/usr/bin/env bash

# Origin: https://github.com/ACloudGuru/node-dev-dotfiles/blob/trunk/lib/secret.sh

## Save and export shell secrets using keychain
secret () {
  USAGE="
    Usage:
    > secret set [KEY] [VALUE]
    > secret get [KEY]
    > secret export [KEY] # outputs: export [KEY]=[VALUE]
    > secret unset [KEY]
  "

  MODE="$1"
  KEY="$2"
  VALUE="$3"
  KIND="shell secret"
  ACCOUNT="$(whoami)"
  ARG_LENGTH="$#"

  # Set a secret in keychain
  if [ $MODE = "set" ] && [ $ARG_LENGTH -eq "3" ]; then
    if security add-generic-password -U -a "$ACCOUNT" -D "$KIND" -s "$KEY" -w "$VALUE";
    then echo "$KEY saved to keychain.";
    fi

  # Get a secret from keychain
  elif [ $MODE = "get" ] && [ $ARG_LENGTH -eq "2" ]; then
    security find-generic-password -a "$ACCOUNT" -D "$KIND" -s "$KEY" -w;

  # Export a secret to shell
  elif [ $MODE = "export" ] && [ $ARG_LENGTH -eq "2" ]; then
    if security find-generic-password -a "$ACCOUNT" -D "$KIND" -s "$KEY" -w &>/dev/null;
    then
      export $KEY=$(secret get $KEY | xargs);
      echo "$KEY loaded from keychain.";
    else
      echo "$KEY not found in keychain."
    fi

  # Delete a secret in keychain
  elif [ $MODE = "unset" ] && [ $ARG_LENGTH -eq "2" ]; then
    security delete-generic-password -a "$ACCOUNT" -D "$KIND" -s "$KEY" -w;

  # Unkown mode
  else
    echo $USAGE;
  fi
}
