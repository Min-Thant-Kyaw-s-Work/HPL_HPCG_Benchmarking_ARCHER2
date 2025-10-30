#!/bin/bash
#SBATCH --job-name=HPCG_test_dim
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --account=ta210-hex

module load PrgEnv-gnu
module load cray-libsci
module load cray-mpich

cd /work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/hpcg/hpcg-HPCG-release-3-1-0/build/bin

# Test with safe dimensions (powers of 2 work best)
cat > hpcg.dat << EOF
HPCG benchmark input file
Sandia National Laboratories; University of Tennessee, Knoxville
64 64 64
30
EOF

srun -n 8 ./xhpcg