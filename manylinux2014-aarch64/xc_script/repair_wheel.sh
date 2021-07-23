#!/bin/bash

# AUTHOR: odidev
# DATE: 2021-07-20
# DESCRIPTION: The wheels are cross compiled and we can't be repair in currnet
#              environment. So, better to repair in manylinux container. So,
#              we need to run BEFORE_ALL again in target manylinux contaner. So,
#              instead of running BEFORE_ALL again we can copy the stored files.

install_dir='/host/tmp/install_deps'

for file in `find $install_dir -type f`; do
    install_path=$(echo ${file} | sed 's/^.*usr/\/usr/')
    install -m 0644 -D ${file} ${install_path}
done

$1
