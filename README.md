```diff
---------  Under construction!  ---------
```
# ValidateBAM-nf 
Minimal nextflow pipeline to check integrity of BAM files with various tools and to generate`md5sum` of the files.
<br><br>

<p align="center">
  <img src="images/validate-bam.svg"  width="800" align="center" >
</p>



## Quick Start

Required Arguments:

| argument       | value | 
|:--------------:|:-----:| 
|`inputdir`| a path to the input folder with bam files to be checked| 
| `outdir`  | a path to an output folder for the .txt summary report files. <br> The reports will be in the `outdir/Results/`folder|
| `ref`| a path to the fasta file used as a reference genome for mapping the bam files|

To test the pipeline with the example input you can run:

```nextflow
# Clone the repository
git clone https://github.com/cgpu/ValidateBAM-nf.git

# cd into the repo folder 
cd merge-bams-nf

# Execute nextflow run command with example input parameters
nextflow run merge-bams-nf/main.nf --inputdir path/to/input/folder/ --tool 'samtools' 
```

