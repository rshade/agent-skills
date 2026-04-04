#!/bin/bash

UNUSED_VAR="hello"

echo $USER logged in at $HOME

cd /some/directory

process_files() {
    local result=$(whoami)
    echo "Running as $result"

    for f in $(ls *.txt); do
        echo "Processing $f"
    done
}

if [[ $1 = "test" ]]; then
    process_files
fi
