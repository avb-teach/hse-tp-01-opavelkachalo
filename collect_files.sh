#!/bin/bash

argc=$#

if [ $argc -lt 2 ]; then
    echo 'Usage: collect_files.sh <source> <dest> [--max_depth N]' >&2
    exit 1
fi

source=$1
dest=$2

if [ $argc -ge 3 ]; then
    max_depth=$4
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
    local elem_count=$(find $init_dir -mindepth 1 | wc -l)
    while true; do
        find output_dir -type d -empty -exec rm -rf {} +
        if [ $elem_count -eq $(find $init_dir -mindepth 1 | wc -l) ]; then
            break
        fi
        elem_count=$(find $init_dir -mindepth 1 | wc -l)
    done
}

if [ $max_depth -eq 1 ]; then
    cp_files_1 $source
else
    cp -r $source/* $dest
    cp_files $dest 1
    rm_empty_dirs $dest
fi
