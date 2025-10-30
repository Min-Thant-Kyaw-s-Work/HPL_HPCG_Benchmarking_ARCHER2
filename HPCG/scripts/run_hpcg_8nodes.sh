#!/bin/bash
#SBATCH --job-name=HPCG_8nodes
#SBATCH --nodes=8
#SBATCH --tasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --account=ta210-hex

module load PrgEnv-gnu
module load cray-libsci
module load cray-mpich

export OMP_NUM_THREADS=1

cd /work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/hpcg/hpcg-HPCG-release-3-1-0/build/bin

RESULTS_DIR="/work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/results/hpcg_8nodes_$(date +%Y%m%d_%H%M%S)"
mkdir -p ${RESULTS_DIR}

# Adjusted dimensions for 1024 MPI processes  
cat > hpcg.dat << EOF
HPCG benchmark input file
Sandia National Laboratories; University of Tennessee, Knoxville
192 192 192
60
EOF

cp hpcg.dat ${RESULTS_DIR}/

srun --distribution=block:block --hint=nomultithread ./xhpcg 2>&1 | tee ${RESULTS_DIR}/hpcg_output.txt

mv *.txt ${RESULTS_DIR}/ 2>/dev/null
mv *.yaml ${RESULTS_DIR}/ 2>/dev/null

echo "HPCG finished. Waiting 60s for Slurm database..."
sleep 60

sacct -j ${SLURM_JOB_ID} --format=JobID,Elapsed,ConsumedEnergy,MaxRSS,AllocCPUS > ${RESULTS_DIR}/energy_stats.txt

echo "Results saved to: ${RESULTS_DIR}"