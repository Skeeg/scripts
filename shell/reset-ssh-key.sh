#!/usr/bin/env bash

reset-ssh-key() {
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$1"; ssh-keyscan -H "$1" >> "$HOME/.ssh/known_hosts"
}