#!/bin/bash

# Find QEMU processes
qemu_pids=$(pgrep -f "qemu")

if [ -z "$qemu_pids" ]; then
    echo "No QEMU processes found running"
    exit 0
fi

# Display running QEMU processes
echo "Found running QEMU processes:"
ps -fp $qemu_pids

# Attempt graceful shutdown first
for pid in $qemu_pids; do
    echo "Attempting graceful shutdown of QEMU process $pid..."
    kill -SIGTERM $pid

    # Wait up to 30 seconds for graceful shutdown
    for i in {1..30}; do
        if ! kill -0 $pid 2>/dev/null; then
            echo "QEMU process $pid stopped successfully"
            break
        fi
        sleep 1
    done

    # Force kill if still running
    if kill -0 $pid 2>/dev/null; then
        echo "Forcing shutdown of QEMU process $pid..."
        kill -9 $pid
    fi
done

# Verify all processes are stopped
if pgrep -f "qemu" >/dev/null; then
    echo "Warning: Some QEMU processes may still be running"
    exit 1
else
    echo "All QEMU processes stopped successfully"
    exit 0
fi