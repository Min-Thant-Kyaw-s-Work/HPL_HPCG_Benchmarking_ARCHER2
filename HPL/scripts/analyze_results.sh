#!/bin/bash

RESULTS_DIR="/work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/results"

echo "HPL Benchmark Results Summary"
echo "=============================="
echo ""

for nodes in 1 2 4 8; do
    echo "Results for $nodes node(s):"
    echo "--------------------------"
    
    # Find the latest result directory for this node count
    LATEST=$(ls -td ${RESULTS_DIR}/hpl_${nodes}node* 2>/dev/null | head -1)
    
    if [ -d "$LATEST" ]; then
        echo "Directory: $(basename $LATEST)"
        
        # Extract performance from HPL output
        if [ -f "$LATEST/hpl_output.txt" ]; then
            grep "WR" "$LATEST/hpl_output.txt" | tail -1
        fi
        
        # Show energy stats
        if [ -f "$LATEST/energy_stats.txt" ]; then
            echo "Energy Statistics:"
            cat "$LATEST/energy_stats.txt"
        fi
    else
        echo "No results found yet"
    fi
    echo ""
done