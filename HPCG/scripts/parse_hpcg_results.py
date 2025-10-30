#!/usr/bin/env python3
import sys
import os
import glob
import yaml

def parse_hpcg_yaml(filename):
    """Parse HPCG YAML output file for performance metrics"""
    try:
        with open(filename, 'r') as f:
            # HPCG YAML files might have issues, try to parse key metrics
            content = f.read()
            
            # Look for Final Summary section
            gflops = None
            time = None
            
            for line in content.split('\n'):
                if 'HPCG result is VALID' in line or 'HPCG result is' in line:
                    parts = line.split('=')
                    if len(parts) > 1:
                        gflops_str = parts[1].strip().split()[0]
                        try:
                            gflops = float(gflops_str)
                        except:
                            pass
                            
                if 'Total Time' in line:
                    parts = line.split('=')
                    if len(parts) > 1:
                        time = float(parts[1].strip().split()[0])
                        
            return time, gflops
    except:
        return None, None

def parse_hpcg_txt(filename):
    """Parse HPCG text output for performance metrics"""
    try:
        with open(filename, 'r') as f:
            content = f.read()
            
            for line in content.split('\n'):
                if 'Final Summary::HPCG result is' in line:
                    parts = line.split('=')
                    if len(parts) > 1:
                        gflops = float(parts[1].strip().split()[0])
                        return gflops
    except:
        return None
        
    return None

def parse_energy(filename):
    """Parse energy statistics from sacct output, looking only for the .0 job step"""
    if not os.path.exists(filename):
        return None, None
    
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    for line in lines:
        if line.strip().endswith(".0"): # Only look at the main job step
            parts = line.split()
            if len(parts) > 3:
                try:
                    # Get Elapsed Time
                    time_str = parts[1]
                    h, m, s = map(int, time_str.split(':'))
                    total_seconds = float((h * 3600) + (m * 60) + s)
                    
                    # Get Consumed Energy
                    energy_raw = parts[2]
                    energy_joules = 0.0
                    
                    if energy_raw.endswith('K'):
                        energy_joules = float(energy_raw[:-1]) * 1000
                    elif energy_raw.endswith('M'):
                        energy_joules = float(energy_raw[:-1]) * 1000000
                    elif energy_raw.isdigit():
                        energy_joules = float(energy_raw)

                    if total_seconds > 0 and energy_joules > 0:
                        return total_seconds, energy_joules
                except Exception as e:
                    pass # Ignore parsing errors on this line
                    
    return None, None

if __name__ == "__main__":
    results_dir = "/work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/results"
    
    print("HPCG Benchmark Results Summary")
    print("=" * 80)
    print(f"{'Nodes':<10} {'Runtime (s)':<12} {'GFLOPS':<12} {'Energy (J)':<15} {'Avg Power (W)':<15} {'GFLOPS/W':<12}")
    print("-" * 80)
    
    for nodes in [1, 2, 4, 8]:
        dirs = glob.glob(f"{results_dir}/hpcg_{nodes}node*")
        if dirs:
            latest = max(dirs) # Find latest result directory
            
            yaml_files = glob.glob(f"{latest}/*.yaml")
            txt_files = glob.glob(f"{latest}/HPCG-Benchmark*.txt")
            
            gflops = None
            runtime = None
            
            # Try to get data from YAML file first
            if yaml_files:
                runtime, gflops = parse_hpcg_yaml(yaml_files[0])
            
            # If YAML parsing fails, try to get GFLOPS from txt file
            if not gflops and txt_files:
                gflops = parse_hpcg_txt(txt_files[0])
                
            # Get energy and runtime from sacct
            sacct_time, energy = parse_energy(f"{latest}/energy_stats.txt")
            
            if not runtime and sacct_time:
                runtime = sacct_time # Use sacct time if YAML fails
            
            if gflops:
                if energy and runtime and runtime > 0:
                    avg_power = energy / runtime
                    gflops_per_watt = gflops / avg_power
                    print(f"{nodes:<10} {runtime:<12.2f} {gflops:<12.4f} {energy:<15.2f} {avg_power:<15.2f} {gflops_per_watt:<12.4f}")
                else:
                    print(f"{nodes:<10} {runtime if runtime else 'N/A':<12} {gflops:<12.4f} {'N/A':<15} {'N/A':<15} {'N/A':<12}")
            else:
                print(f"{nodes:<10} {'No results found'}")
        else:
            print(f"{nodes:<10} {'No results found'}")