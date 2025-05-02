#!/bin/bash

argc=$#

if [ $argc -lt 2 ]; then
    echo 'Usage: collect_files.sh <source> <dest> [--max_depth=N]' >&2
    exit 1
fi

source=$1
dest=$2

if [ $argc -eq 3 ]; then
    if [[ $3 =~ ^--max_depth=[0-9]+ ]]; then
        third_arg=$3
        max_depth=${third_arg:12}
    else
        echo "Error: Incorrect argument \"$3\"" >&2
        echo 'Usage: collect_files.sh <source> <dest> [--max_depth=N]' >&2
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

cp_files_1 () {
    local init_dir=$1
    for f in `ls $init_dir`; do
        if [ -d $init_dir/$f ]; then
            cp_files_1 $init_dir/$f
        elif [ -f $dest/$f ]; then
            local prefix=${f%%.*}
            local suffix=${f#*.}
            local i=1
            local filename=$prefix$i.$suffix
            while [ -f $dest/$filename ]; do
                i=$((i+1))
                filename=$prefix$i.$suffix
            done
            cp $init_dir/$f $dest/$filename
        else
            cp $init_dir/$f $dest
        fi
    done
}

cp_files () {
    local init_dir=$1
    local depth=$2
    for f in `ls $init_dir`; do
        if [ -d $init_dir/$f ]; then
            cp_files $init_dir/$f $((depth+1))
        elif [ $depth -gt $max_depth ]; then
            IFS='/' read -ra path_array <<< $init_dir/$f
            tmp_path=${path_array[0]}
            i=$(($depth-$max_depth+1))
            while [ $i -lt $depth ]; do
                tmp_path=$tmp_path/${path_array[$i]}
                mkdir $tmp_path
                i=$((i+1))
            done
            tmp_path=$tmp_path/${path_array[$i]}
            mv $init_dir/$f $tmp_path
        fi
    done
}

rm_empty_dirs () {
    local init_dir=$1
    for f in $init_dir/*; do
        if [ -d $f ]; then
            if ! rmdir $f 2&>/dev/null; then
                rm_empty_dirs $f
            fi
        fi
    done
}

if [ $max_depth -eq 1 ]; then
    cp_files_1 $source
else
    cp -r $source/* $dest
    cp_files $dest 1
    rm_empty_dirs $dest
fi
