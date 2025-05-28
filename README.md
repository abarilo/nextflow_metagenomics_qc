# read_qc Nextflow Pipeline

A Nextflow pipeline for Nanopore long read and Illumina short read quality control, trimming and reporting.

## 🔧 Requirements

- [Nextflow](https://www.nextflow.io/) ≥ 21.04  
- Docker or Singularity (see below)  

## 🚀 Usage

```bash
nextflow run main.nf  -profile quality_control --read1 /path/to/illumina_reads_R1/*.fq.gz --read2 /path/to/illumina_reads_R2/*.fq.gz \
 --nanopore /path/to/nanopore_reads/*.fastaq --adapters /path/to/illumina_adapters.fa --outdir /path/to/results
```

### CLI Parameters

| Parameter    | Description                                                     | Default          |
|--------------|-----------------------------------------------------------------|------------------|
| `-profile`   | Nextflow profile to use (e.g. `quality_control`)                | _required_       |
| `--read1`    | Illumina read R1 FASTQ files (glob pattern)                    | _required_       |
| `--read2`    | Illumina read R2 FASTQ files (glob pattern)                    | _required_       |
| `--nanopore` | Nanopore reads (FASTA/FASTQ glob pattern)                      | _required_       |
| `--adapters` | FASTA file of Illumina adapters for trimming                    | _required_       |
| `--outdir`   | Output directory for QC reports and trimmed reads               | `./results`      |

> **Tip:** Override any setting in `nextflow.config` by passing `--config my.config`.

## ⚙️ Configuration

All pipeline settings (resource allowances, paths, container options…) live in `nextflow.config`.  
To tweak settings:

1. Open `nextflow.config`  
2. Modify values under the `process` scope. For example:

   ```groovy
   process {
     withName: FastQC {
       executor       = 'slurm'
       queue          = 'all'
       cpus           = 8
       memory         = '64 GB'
       time           = '7h'
       scratch        = true
       clusterOptions = '-w omics-cn001'
     }
   }
   ```


## 🛠 Tool-specific Settings

Tool parameters (trimming thresholds, FastQC flags, etc.) are defined directly in each process’s `script` block in `main.nf`.  
To adjust:

1. Open `main.nf`  
2. Locate the `script:` section for the desired process (e.g., `Trimmomatic`, `FastQC`, `Porechop`)  
3. Edit command-line flags or parameters as needed  
4. Save and rerun the pipeline

## 🐳 Docker & Singularity

### Docker

The Docker image includes:

- Trimmomatic v0.39  
- FastQC v0.12.1  
- Porechop v0.2.4  
- Chopper v0.10.0  
- NanoPlot v1.44.1  

To use Docker (modify `nextflow.config` to enable containers):

```bash
docker pull abarilo/read_qc:latest
```

### Singularity (for HPC)

Build the image once:

```bash
singularity build read_qc.sif docker://abarilo/read_qc:latest
```



