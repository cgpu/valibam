
Channel
    .fromPath("${params.inputdir}/*.bam")
    .into { validate_sam_file_channel_ ; samtools_flagstat_channel_ ; qualimap_bamqc_channel_}

Channel
    .fromPath(params.ref)
    .into { md5sum_channel_ ; ref_validate_sam_channel_ ; ref_samtools_flagstat_channel_ ; ref_qualimap_bamqc_channel_}



process generate_md5sum {
  tag "$bam"
  publishDir "$params.outdir/md5sum", mode: 'copy'
  container "frolvlad/alpine-bash:latest"

  input:
  file(bam) from md5sum_channel_

  output:
  file("*") into nowhere_channel_

  script:
  """
  md5sum $bam >  "${bam.baseName}.md5sum"  
  """
}

process validate_bam_file {
  tag "$bam"
  publishDir "$params.outdir/ValidateBamFiles", mode: 'copy'
  container "broadinstitute/gatk:latest"

  input:
  file(bam) from validate_sam_file_channel_
  each file(ref) from ref_validate_sam_channel_

  output:
  file("*") into multiqc_channel_validate_bam_

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
process samtools_flagstat {
  tag "$bam"
  publishDir "$params.outdir/SamtoolsFlagstat", mode: 'copy'
  container "lifebitai/samtools:latest"

  input:
  file(bam) from samtools_flagstat_channel_
  each file(ref) from ref_samtools_flagstat_channel_

  output:
  file("*") into multiqc_channel_samtools_flagstat_

  script:
  """
  samtools flagstat ${bam} > ${bam.baseName}.flagstats.txt
  """
}
process qualimap_bamqc {
  tag "$bam"
  publishDir "$params.outdir/QualimapBamQC", mode: 'copy'
  container "maxulysse/sarek:latest"

  input:
  file(bam) from qualimap_bamqc_channel_
  each file(ref) from ref_qualimap_bamqc_channel_

  output:
  file("*") into multiqc_channel_qualimap_bamqc_

  script:
  """
  qualimap \
  bamqc \
  -bam ${bam} \
  --paint-chromosome-limits \
  --genome-gc-distr HUMAN \
  -nt 2 \
  -skip-duplicated \
  --skip-dup-mode 0 \
  -outdir ${bam.baseName} \
  -outformat HTML
  """
}
process multiqc {
    publishDir "$params.outdir/MultiQC", mode: 'copy'
    container 'ewels/multiqc:v1.7'

    when:
    !params.skip_multiqc

    input:
    file (validateSamFile) from multiqc_channel_validate_bam_.collect().ifEmpty([])
    file (flagstat) from multiqc_channel_samtools_flagstat_.collect().ifEmpty([])
    file (bamqc) from multiqc_channel_qualimap_bamqc_.collect().ifEmpty([])
    
    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    """
    multiqc .  -m picard -m qualimap -m samtools
    """
}