#!/bin/bash

sparkx-start-ssh-agent() {
    local keys
    local key
    IFS=';' read -r -a keys <<< "${SPARKX_SSH_KEYS}"
    
    # SSH Agent should be running, once
    runcount=$(ps -ef | grep "ssh-agent" | grep -v "grep" | wc -l)
    if [ $runcount -eq 0 ]; then
        echo "SparkX SSH Agent Handler: Starting ssh-agent..."
        eval $(ssh-agent -s)

        echo $SSH_AUTH_SOCK > "/tmp/ssh-agent-socket"
       
        for key in "${keys[@]}"; do
            if [ -f $key ]; then
                echo "ssh-agent adding $key"
                ssh-add $key
            fi
        done
    fi
 
    export SSH_AUTH_SOCK=$(cat /tmp/ssh-agent-socket)
}

if [ ! -z "$SPARKX_SSH_KEYS" ]; then
    sparkx-start-ssh-agent
fi
