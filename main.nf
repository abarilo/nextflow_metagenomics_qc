#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//———— WORKFLOW ————
workflow {
  // 1) Make output dirs
  ["fastqc","trimmed","trimmed_nano","nanoplot"].each {
    file("${params.outdir}/${it}").mkdirs()
  }

// 2) Derive sample_id 
def sample_id = file(params.read1)
                   .getSimpleName()           
                   .replaceFirst(/_R1\.fq\.gz$/, '')

  // 3) Build a single tuple of (sample_id, R1, R2)
  read_ch = Channel.of( tuple(
    sample_id,
    file(params.read1),
    file(params.read2)
  ))

  // 4) Adapters channel
  adapters_ch = Channel.value(params.adapters).map { file(it) }

  // 5) Raw QC on the paired reads
  fastQC(read_ch)

  // 6) Trim and then QC again
  trimmed = trimIllumina(read_ch, adapters_ch)
  fastQCtrim(trimmed)

  // 7) Nanopore branch
  nano_raw        = Channel.of( file(params.nanopore) )
  nanoPlot(nano_raw)
  trimmedAdapters = trimNanoAdapters(nano_raw)
  chopped         = trimNanoQuality(trimmedAdapters)
  nanoPlotTrim(chopped)
}


//———— PROCESSES ————

process trimIllumina {
  tag "${sample_id}"
  publishDir "${params.outdir}/trimmed", mode: 'copy'

  input:
    tuple val(sample_id), path(read1), path(read2)
    path adapters

  output:
    tuple val(sample_id),
          path("${sample_id}_R1_trimmed.fq.gz"),
          path("${sample_id}_R2_trimmed.fq.gz")

  script:
  """
  #!/usr/bin/env bash
  trimmomatic PE \
    -threads ${task.cpus} \
    -trimlog   ${sample_id}_trimlog.txt \
    -summary   ${sample_id}_summary.txt \
    ${read1} ${read2} \
    ${sample_id}_R1_trimmed.fq.gz ${sample_id}_R1_untrimmed.fq.gz \
    ${sample_id}_R2_trimmed.fq.gz ${sample_id}_R2_untrimmed.fq.gz \
    ILLUMINACLIP:${adapters}:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
  """
}

process fastQC {
  tag "${sample_id}"
  publishDir "${params.outdir}/fastqc", mode: 'copy'

  input:
    tuple val(sample_id), path(read1), path(read2)

  output:
    path "*_fastqc.html"

  script:
  """
  #!/usr/bin/env bash
  fastqc --threads ${task.cpus} -o . ${read1} ${read2}
  """
}

process fastQCtrim {
  tag "${sample_id}"
  publishDir "${params.outdir}/fastqc", mode: 'copy'

  input:
    tuple val(sample_id), path(read1), path(read2)

  output:
    path "*_fastqc.html"

  script:
  """
  #!/usr/bin/env bash
  fastqc --threads ${task.cpus} -o . ${read1} ${read2}
  """
}

process trimNanoAdapters {
  tag "${ nanopore_read.simpleName.replaceFirst(/\\.fastq(\\.gz)?$/, '') }"
  publishDir "${params.outdir}/trimmed_nano", mode: 'copy'

  input:
    path nanopore_read

  output:
    path "trimmed_*.fastq.gz"

  script:
  """
  #!/usr/bin/env bash
  base=\$(basename ${nanopore_read} .fastq.gz)
  porechop -i ${nanopore_read} -o trimmed_\${base}.fastq.gz
  """
}

process trimNanoQuality {
  tag "${ nanopore_read.simpleName.replaceFirst(/\\.fastq(\\.gz)?$/, '') }"
  publishDir "${params.outdir}/trimmed_nano", mode: 'copy'

  input:
    path nanopore_read

  output:
    path "chopped_*.fastq.gz"

  script:
  """
  #!/usr/bin/env bash
  base=\$(basename ${nanopore_read} .fastq.gz)
  chopper trim -i ${nanopore_read} -o chopped_\${base}.fastq.gz -q 7 --trim 10 -l 500
  """
}

process nanoPlot {
  tag "${ nanopore_read.simpleName.replaceFirst(/\\.fastq(\\.gz)?$/,'') }"
  publishDir "${params.outdir}/nanoplot", mode: 'copy'

  input:
    path nanopore_read

  // <-- this captures every file & directory under the work dir
  output:
    path "**"

  script:
  """
  #!/usr/bin/env bash
  base=\$(basename ${nanopore_read} .fastq.gz)
  NanoPlot --fastq ${nanopore_read} --loglength --outdir . --prefix \$base
  """
}

process nanoPlotTrim {
  tag "${ nanopore_read.simpleName.replaceFirst(/\\.fastq(\\.gz)?$/,'') }_trimmed"
  publishDir "${params.outdir}/nanoplot", mode: 'copy'

  input:
    path nanopore_read

  output:
    path "**"

  script:
  """
  #!/usr/bin/env bash
  base=\$(basename ${nanopore_read} .fastq.gz)
  NanoPlot --fastq ${nanopore_read} --loglength --outdir . --prefix \$base
  """
}

