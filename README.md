```diff
---------  Under construction!  ---------
```

# ValidateBAM-nf 
Minimal nextflow pipeline to check integrity of BAM files with picard `ValidateSamFile`
<br><br><br>

<p align="center">
  <img src=""  width="800" align="center" >
</p>


## Quick Start

Required Arguments:

| argument       | value | 
|:--------------:|:-----:| 
| `inputdir`| a path to the input folder with bam files to be checked| 
| `outdir`  | a path to an output folder for the .txt summary report files. The reports will be in the `outdir/Results/` folder|
|`ref`| a path to the fasta file used as a reference genome for mapping the bam files|

To test the pipeline with the example input you can run:

```nextflow
# Clone the repository
git clone https://github.com/cgpu/merge-bams-nf.git

# cd into the repo folder 
cd merge-bams-nf

# Execute nextflow run command with example input parameters
nextflow run cgpu/merge-bams-nf --input_files_list example-input/input_files_list.csv  --tool 'samtools' -with-docker lifebitai/samtools:latest
```

