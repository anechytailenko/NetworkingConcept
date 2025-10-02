#!/bin/bash

DATA_FILE=~/week3/data.txt

IP_ADDR=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
MAC_ADDR=$(ip a | grep 'link/ether' | awk '{print $2}' | head -n 1)


LINE_NUM=1


while read LINE; do
    COMMAND=$(echo $LINE | tr '[:upper:]' '[:lower:]')

    case "$COMMAND" in
        "hello")
            echo "Hello! My IP is $IP_ADDR. My MAC is $MAC_ADDR."
            ;;

        "data")
            LINE_NUM=1
            LINE_CONTENT=$(sed -n "${LINE_NUM}p" "$DATA_FILE")
            if [ -n "$LINE_CONTENT" ]; then
                echo "$LINE_CONTENT"
                LINE_NUM=$((LINE_NUM + 1))
            else
                echo "Data file is empty or missing."
            fi
            ;;

        "next")
            LINE_CONTENT=$(sed -n "${LINE_NUM}p" "$DATA_FILE")
            if [ -n "$LINE_CONTENT" ]; then
                echo "$LINE_CONTENT"
                LINE_NUM=$((LINE_NUM + 1))
            else
                echo "--- END OF DATA ---"
            fi
            ;;

        "exit")
            echo "Goodbye!"
            break
            ;;

        *)
            echo "Unknown command: $LINE. Supported: hello, data, next, exit."
            ;;
    esac
done