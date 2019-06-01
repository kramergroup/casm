# Obtain VASP pseudo-potentials
# -----------------------------
# The pseudo-potentials cannot be publicly distributed due to license constrains.
# This build container obtains them from a private S3 store such as minio
# using the S3_HOST and access-key and secret arguments
FROM minio/mc as s3

ARG S3_HOST
ARG S3_ACCESS_KEY_ID
ARG S3_SECRET_ACCESS_KEY

RUN mc config host add --insecure minio https://$S3_HOST $S3_ACCESS_KEY_ID $S3_SECRET_ACCESS_KEY
RUN mc --insecure cp minio/vasp/vasp5_psps.tar.gz /tmp/vasp5_psps.tar.gz

WORKDIR /VASP5_psps
RUN tar xvzf /tmp/vasp5_psps.tar.gz 

FROM ubuntu

WORKDIR /install
RUN apt-get update && apt-get install --no-install-recommends -y wget curl ssh-client && rm -rf /var/lib/apt/lists/* && \
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh --no-check-certificate -O Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm -rf /install

ENV PATH=$PATH:/root/miniconda3/bin

WORKDIR /data
RUN /root/miniconda3/bin/conda install --override-channels --yes \
                                       -c bpuchala/label/dev \
                                       -c prisms-center \
                                       -c defaults \
                                       -c conda-forge casm

RUN /root/miniconda3/bin/conda init bash

## Patch the casm code for generating INCARs
## See issue: 
COPY patches/casm.io.vasp.incar.py.patch /tmp/casm.io.vasp.incar.py.patch
RUN apt-get update && apt-get install --no-install-recommends -y patch && rm -rf /var/lib/apt/lists/*
RUN patch /root/miniconda3/lib/python3.6/site-packages/casm/vasp/io/incar.py /tmp/casm.io.vasp.incar.py.patch

COPY entrypoint.sh /entrypoint.sh

COPY --from=0 /VASP5_psps /VASP5_psps
ENV POTCAR_DIR_PATH /VASP5_psps

ENTRYPOINT [ "/root/miniconda3/bin/casm" ]