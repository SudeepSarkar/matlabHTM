#!/bin/bash
#SBATCH --partition=bgfsqdr
#SBATCH --job-name=runNAB_1-58
#SBATCH --time=00:20:00
#SBATCH --output=Output/matlabHTM.%j
#SBATCH --ntasks=4
#SBATCH --mem=8192

module load apps/matlab/r2019a

date

matlab -nodisplay -nosplash -r "run('runNAB(1,5,false,true)')"

date


