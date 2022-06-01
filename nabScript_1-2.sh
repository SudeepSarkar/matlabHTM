#!/bin/bash
#SBATCH --job-name=runNABAU_1-2
#SBATCH --time=02:00:00
#SBATCH --output=Output/matlabHTMAU.%j
#SBATCH --ntasks=1
#SBATCH --mem=8192

module load apps/matlab/r2019a

date

matlab -nodisplay -nosplash -r "run('runNAB(1,2,false,true)')"

date


