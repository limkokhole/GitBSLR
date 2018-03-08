#!/bin/bash

cd $(dirname $0)
make || exit $?
rm -rf test/ || exit $?
[ -e test/ ] && exit 1
mkdir test/ || exit $?

#With GitBSLR installed, Git can end up writing to outside the repository directory. If a pulled
# repository is malicious, this can cause remote code execution, for example by scribbling across your .bashrc.
#GitBSLR must prevent that. Since the entire point of GitBSLR is writing outside the repo, something
# else must be changed. The only available option is preventing Git from creating symlinks to outside the repo root.
#The simplest and most effective way would be returning an error. The most appropriate one would be EPERM,
# "The filesystem containing linkpath does not support the creation of symbolic links."


mkdir test/victim/
echo echo Test passed > test/victim/script.sh
mkdir test/evilrepo_v1/

cd test/evilrepo_v1/
git init
ln -s ../victim/ evil_symlink
git add .
git commit -m "GitBSLR test"
cd ../..

mkdir test/evilrepo_v2/
cd test/evilrepo_v2/
git init
mkdir evil_symlink/
echo echo Installing Bitcoin miner... > evil_symlink/script.sh
git add .
git commit -m "GitBSLR test"
cd ../..

mkdir test/clone/
cd test/clone/
mv ../evilrepo_v1/.git ./.git
LD_PRELOAD=../../gitbslr.so git reset --hard
mv .git ../evilrepo_v1/.git
mv ../evilrepo_v2/.git ./.git
LD_PRELOAD=../../gitbslr.so git reset --hard
mv .git ../evilrepo_v2/.git

cd ../../
sh test/victim/script.sh