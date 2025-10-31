#!/bin/bash
#SBATCH --job-name=HPCG_1node_HYBRID_32x4
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --account=ta210-hex

module load PrgEnv-gnu
module load cray-libsci
module load cray-mpich

export OMP_NUM_THREADS=4
export OMP_PLACES=cores
export OMP_PROC_BIND=close

cd /work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/hpcg/hpcg-HPCG-release-3-1-0/build/bin

RESULTS_DIR="/work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/results/hpcg_1node_hybrid_32x4_$(date +%Y%m%d_%H%M%S)"
mkdir -p ${RESULTS_DIR}

# Problem size for 1 node
cat > hpcg.dat << EOF
HPCG benchmark input file
Sandia National Laboratories; University of Tennessee, Knoxville
128 128 128
60
EOF

cp hpcg.dat ${RESULTS_DIR}/

srun --distribution=block:block --hint=nomultithread ./xhpcg 2>&1 | tee ${RESULTS_DIR}/hpcg_output.txt

# Move result files to results directory
mv *.txt ${RESULTS_DIR}/ 2>/dev/null
mv *.yaml ${RESULTS_DIR}/ 2>/dev/null

# Add sleep 60 to prevent sacct errors
echo "HPCG finished. Waiting 60s for Slurm database..."
sleep 60

sacct -j ${SLURM_JOB_ID} --format=JobID,Elapsed,ConsumedEnergy,MaxRSS,AllocCPUS > ${RESULTS_DIR}/energy_stats.txt

echo "Results saved to: ${RESULTS_DIR}"
