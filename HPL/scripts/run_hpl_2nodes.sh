#!/bin/bash
#SBATCH --job-name=HPL_2nodes
#SBATCH --nodes=2
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
export OMP_PLACES=cores
export OMP_PROC_BIND=close

cd /work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/hpl/hpl-2.3/bin/ARCHER2

RESULTS_DIR="/work/ta210/ta210/ta210kyaw2/ciuk2025/green_hpc_challenge/results/hpl_2nodes_$(date +%Y%m%d_%H%M%S)"
mkdir -p ${RESULTS_DIR}

cat > HPL.dat << EOF
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
150000        Ns
1            # of NBs
256          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
16           Ps
16           Qs
16.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
1            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
1            DEPTHs (>=0)
2            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOF

cp HPL.dat ${RESULTS_DIR}/

srun --distribution=block:block --hint=nomultithread ./xhpl 2>&1 | tee ${RESULTS_DIR}/hpl_output.txt

sacct -j ${SLURM_JOB_ID} --format=JobID,Elapsed,ConsumedEnergy,MaxRSS,AllocCPUS > ${RESULTS_DIR}/energy_stats.txt

echo "Results saved to: ${RESULTS_DIR}"