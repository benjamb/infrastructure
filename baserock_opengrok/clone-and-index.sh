#!/bin/sh


dir={{ OPENGROK_BASE }}/source
if [ ! -d $dir/.git ]; then
        git clone /opt/export-workdir/exported-definitions/ $dir
fi

git --git-dir="$dir/.git" --work-tree="$dir" pull
(cd $dir && git submodule init)
(cd $dir && git submodule sync)
(cd $dir && git submodule update)
git --git-dir="$dir/.git" --work-tree="$dir" clean -xdff

OPENGROK_INSTANCE_BASE={{ OPENGROK_BASE }} {{ OPENGROK_BASE }}/bin/OpenGrok index {{ OPENGROK_BASE }}/source/
