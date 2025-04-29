#!/bin/bash

argc=$#

if [ $argc -lt 2 ]; then
    echo 'Usage: ./collect_files.sh <source> <dest> [--max_depth=N]' >&2
    exit 1
fi

source=$1
dest=$2

if [ $argc -eq 3 ]; then
    if [[ $3 =~ ^--max_depth=[0-9]+ ]]; then
        third_arg=$3
        max_depth=${third_arg:12}
    else
        echo "Error: Incorrect argument ${3}" >&2
        echo 'Usage: ./collect_files.sh <source> <dest> [--max_depth=N]' >&2
        exit 1
    fi
else
    max_depth=1
fi

if [ ! -d $source ]; then
    echo "Error: $source is not a directory" >&2
    exit 1
fi

if [ ! -e $dest ]; then
    mkdir $dest
elif [ ! -d $dest ]; then
    echo "Error: $dest is not a directory" >&2
    exit 1
fi
