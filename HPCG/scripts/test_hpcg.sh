#!/bin/bash
#SBATCH --job-name=HPCG_test
#SBATCH --nodes=1
#SBATCH --tasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --account=ta210-hex

module load PrgEnv-gnu
module load cray-libsci
module load cray-mpich

cd /work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/hpcg/hpcg-HPCG-release-3-1-0/build/bin

# Create test input file (small problem, short runtime)
cat > hpcg.dat << EOF
HPCG benchmark input file
Sandia National Laboratories; University of Tennessee, Knoxville
32 32 32
30
EOF

srun -n 16 ./xhpcg