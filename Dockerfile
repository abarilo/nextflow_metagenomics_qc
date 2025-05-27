FROM ubuntu:22.04

# 1) System deps
RUN apt-get update \
 && apt-get install -y wget bzip2 ca-certificates curl git \
 && apt-get clean

# 2) Miniconda
ENV CONDA_DIR=/opt/conda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
 && bash /tmp/miniconda.sh -b -p $CONDA_DIR \
 && rm /tmp/miniconda.sh \
 && $CONDA_DIR/bin/conda clean -afy
ENV PATH=$CONDA_DIR/bin:$PATH

# 3) Install Mamba
RUN conda install -y -c conda-forge mamba \
 && conda clean -afy

# 4) Install Python 3.10 + all tools in one mamba step
RUN mamba install -y \
      -c defaults \
      -c conda-forge \
      -c bioconda \
      python=3.10 \
      trimmomatic=0.39 \
      fastqc=0.12.1 \
      porechop=0.2.4 \
      chopper=0.10.0 \
      nanoplot=1.44.1 \
    && mamba clean --all --yes

# 5) Smoke-test
RUN python --version \
 && trimmomatic -version \
 && fastqc --version \
 && porechop --version \
 && chopper --version \
 && NanoPlot --version

ENTRYPOINT ["bash"]
