#!/bin/bash
#SBATCH --partition=bgfsqdr
#SBATCH --job-name=HTM_59-60
#SBATCH --time=40:00:00
#SBATCH --output=Output/matlabHTM.%j
#SBATCH --ntasks=4
#SBATCH --mem=8192

module load apps/matlab/r2019a

date

matlab -nodisplay -nosplash -r "run('runNAB(59,60,false,true)')"

date


