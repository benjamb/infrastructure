#!/bin/sh

DEFINITIONS_DIR="{{ EXPORT_WORKDIR }}/definitions"
DEFINITIONS_URL="git://git.baserock.org/baserock/baserock/definitions"

MORPH_DIR="{{ EXPORT_WORKDIR }}/morph"
MORPH_URL="git://git.baserock.org/baserock/baserock/morph"

EXPORT_DIR="{{ EXPORT_WORKDIR }}/exported-definitions"

clone_or_pull() {
    repo=$1
    dir=$2
    if [ -d "$dir" ]; then
        git --git-dir="$dir/.git" --work-tree="$dir" pull
    else
        git clone $repo $dir
    fi
}


clone_or_pull $DEFINITIONS_URL $DEFINITIONS_DIR
clone_or_pull $MORPH_URL $MORPH_DIR

if [ ! -d "$EXPORT_DIR" ]; then
    git init "$EXPORT_DIR"
fi


git config --global user.email "export@baserock.com"
git config --global user.name "Baserock Export Daemon"

PYTHONPATH={{ EXPORT_WORKDIR }}/morph python \
  {{ BASEROCK_EXPORT }}/baserock-export-git-submodules.py \
  --git-cache-dir {{ EXPORT_WORKDIR }}/cache \
  --mode submodule \
  $DEFINITIONS_DIR/systems/minimal-system-x86_64-generic.morph \
  "$EXPORT_DIR"
