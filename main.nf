params.inputdir = false
params.outdir   = false
params.ref      = false

Channel
    .fromPath("${params.inputdir}/*.bam")
    .set { validate_sam_file_channel_ }

Channel
    .fromPath(params.ref)
    .set { ref_channel_ }

process validate_sam_file {
  publishDir "$params.outdir/Results", mode: 'copy'
  container "broadinstitute/gatk:latest"

  input:
  file(bam) from validate_sam_file_channel_
  each file(ref) from ref_channel_

  output:
  file("*txt") into multiqc_channel_

  script:
  """
   gatk ValidateSamFile \
  --INPUT ${bam} \
  --OUTPUT ${bam.baseName}_summary.txt \
  --INDEX_VALIDATION_STRINGENCY NONE \
  --VALIDATE_INDEX false \
  --IS_BISULFITE_SEQUENCED false \
  --MAX_OPEN_TEMP_FILES 8000 \
  --MAX_OUTPUT 1000 \
  --MODE SUMMARY \
  --SKIP_MATE_VALIDATION false \
  --REFERENCE_SEQUENCE ${ref}

  """
}
