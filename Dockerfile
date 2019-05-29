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

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/root/miniconda3/bin/casm" ]