#!/bin/bash

# Check if the VM IP address was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <VM_IP_ADDRESS>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

# Take the first command-line argument as the VM's IP
VM_IP="$1"
VM_PORT="2025" # The rate-limited port

echo "Starting Flood Test on $VM_IP:$VM_PORT"
echo "Rate Limit Check: Expecting approx. 10 successes, followed by failures."
echo "--------------------------------------------------------"

# Attempt 20 rapid connections to the rate-limited port
for i in {1..20}; do
    # -z: zero-I/O mode (scan) | -w 1: timeout after 1 second
    if nc -z -w 1 $VM_IP $VM_PORT; then
        echo "Connection $i: ✅ SUCCESS (ACCEPTED)"
    else
        echo "Connection $i: ❌ FAILED (REJECTED)"
    fi
    # A small pause is helpful to allow the kernel to process the rejection
    # sleep 0.01 
done

echo "--------------------------------------------------------"
echo "Flood Test Complete."