#!/bin/bash

RESULTS_DIR="/work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/results"

echo "HPL Benchmark Results Summary"
echo "=============================="
echo ""

# Set the precision for bc calculations
BC_SCALE=2

for nodes in 1 2 4 8; do
    echo "Results for $nodes node(s):"
    echo "--------------------------"
    
    # Find the latest result directory for this node count
    LATEST=$(ls -td ${RESULTS_DIR}/hpl_${nodes}node* 2>/dev/null | head -1)
    
    if [ -d "$LATEST" ]; then
        echo "Directory: $(basename $LATEST)"
        
        # --- 1. Get GFLOPS ---
        hpl_output_file="$LATEST/hpl_output.txt"
        if [ ! -f "$hpl_output_file" ]; then
            echo "HPL output file not found."
            echo ""
            continue
        fi
        
        gflops_line=$(grep "WR" "$hpl_output_file" | tail -1)
        if [ -z "$gflops_line" ]; then
            echo "HPL performance line (WR) not found."
            echo ""
            continue
        fi
        
        echo "$gflops_line" # Print the original HPL performance line
        
        # Get GFLOPS, handling scientific notation (e.g., 1.6763e+03)
        gflops=$(echo "$gflops_line" | awk '{print $NF}')
        gflops=$(printf "%.2f" "$gflops") 

        # --- 2. Get Energy and Time ---
        energy_stats_file="$LATEST/energy_stats.txt"
        if [ ! -f "$energy_stats_file" ]; then
            echo "Energy stats file not found."
            echo ""
            continue
        fi
        
        echo "Energy Statistics:"
        cat "$energy_stats_file"

        # --- THIS IS THE NEW FIX ---
        # Find the line that starts with digits and ends in ".0"
        # This positively identifies the main job step.
        stats_line=$(grep "^[0-9]\+\.0" "$energy_stats_file")
        # ---------------------------
        
        if [ -z "$stats_line" ]; then
            echo "---"
            echo "Calculated Metrics:"
            echo "ERROR: Main job step (.0) not found in energy stats. Cannot calculate."
            echo ""
            continue
        fi

        # Get the energy value (e.g., "35.34K")
        energy_raw=$(echo "$stats_line" | awk '{print $3}')
        
        # Get the elapsed time string (e.g., "00:01:28")
        time_str=$(echo "$stats_line" | awk '{print $2}')

        # --- 3. Process Values ---
        
        # Convert energy (e.g., 35.34K) to Joules
        energy_val=$(echo "$energy_raw" | sed 's/K//')
        energy_joules=$(echo "$energy_val * 1000" | bc)
        
        # Convert time (HH:MM:SS) to seconds
        IFS=: read h m s <<< "$time_str"
        # Use 10# to force base-10 for numbers like 08
        total_seconds=$(( (10#$h * 3600) + (10#$m * 60) + (10#$s) ))

        # --- 4. Calculate & Print Metrics ---
        
        echo "---"
        echo "Calculated Metrics:"
        
        # Check for 0 values to prevent division by zero
        if [ "$total_seconds" -eq 0 ] || [ "$(echo "$energy_joules == 0" | bc)" -eq 1 ]; then
            printf "%-28s %s\n" "Avg. Power (W):" "N/A (Zero energy or time)"
            printf "%-28s %s\n" "Energy Efficiency (GFLOPS/W):" "N/A (Zero energy or time)"
        else
            # 1. Avg Power
            avg_power=$(echo "scale=$BC_SCALE; $energy_joules / $total_seconds" | bc)
            
            # 2. Efficiency
            efficiency=$(echo "scale=$BC_SCALE; $gflops / $avg_power" | bc)

            printf "%-28s %s\n" "Avg. Power (W):" "$avg_power"
            printf "%-28s %s\n" "Energy Efficiency (GFLOPS/W):" "$efficiency"
        fi
        
    else
        echo "No results found yet"
    fi
    echo ""
done