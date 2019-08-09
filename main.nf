
Channel
    .fromPath("${params.inputdir}/*.bam")
    .into {  md5_channel ; validate_bam_channel ; samtools_flagstat_channel ; qualimap_bamqc_channel}

Channel
    .fromPath(params.ref)
    .into { ref_validate_bam_channel ; ref_samtools_flagstat_channel ; ref_qualimap_bamqc_channel}


process generate_md5 {
  tag "$bam"
  publishDir "$params.outdir/md5sum", mode: 'copy'
  container "frolvlad/alpine-bash:latest"

  input:
  file(bam) from md5_channel

  output:
  file("*") into nowhere_channel_

  script:
  """
  filename=`echo ${bam}`
  sum=`md5sum $bam | cut -d " " -f1`
  filename="\${filename}__md5_\${sum}"
  touch "\$filename"
  """
}

process validate_bam {
  tag "$bam"
  publishDir "$params.outdir/ValidateBamFiles", mode: 'copy'
  container "broadinstitute/gatk:latest"

  input:
  file(bam) from validate_bam_channel
  each file(ref) from ref_validate_bam_channel

  output:
  file("*") into multiqc_channel_validate_bam

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
  file(bam) from samtools_flagstat_channel
  each file(ref) from ref_samtools_flagstat_channel

  output:
  file("*") into multiqc_channel_samtools_flagstat

  script:
  """
  samtools flagstat ${bam} > "${bam.baseName}.flagstats.txt"
  """
}

process qualimap_bamqc {
  tag "$bam"
  container "maxulysse/sarek:latest"
  echo true

  input:
  file(bam) from qualimap_bamqc_channel
  each file(ref) from ref_qualimap_bamqc_channel

  output:
  file("${bam.baseName}_folder") into inliner_channel
  file("*") into multiqc_channel_qualimap_bamqc
  
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
  -outdir ${bam.baseName}_folder \
  -outformat HTML && ls -l ${bam.baseName}_folder
  """
}

process inliner {
  tag "inliner"
  publishDir "$params.outdir/QualimapBamQC", mode: 'copy'
  container "loadthefalaina/npm-inliner:1.0.0"
  echo true 

  input:
  file(folder) from inliner_channel

  output:
  file("*") into qualimap_bamqc_results

  script:
  """
  ls -l .
  """
}

process multiqc {
    publishDir "$params.outdir/MultiQC", mode: 'copy'
    container 'ewels/multiqc:v1.7'

    when:
    !params.skip_multiqc

    input:
    file (validateSamFile) from multiqc_channel_validate_bam.collect().ifEmpty([])
    file (flagstat) from multiqc_channel_samtools_flagstat.collect().ifEmpty([])
    file (bamqc) from multiqc_channel_qualimap_bamqc.collect().ifEmpty([])
    
    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    """
    multiqc .  -m picard -m qualimap -m samtools
    """
}
