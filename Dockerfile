FROM tensorflow/tensorflow:2.5.0-gpu

ENV SHELL /bin/bash
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV DEBIAN_FRONTEND=noninteractive
ARG VERSION
ENV VERSION ${VERSION:-dev}

WORKDIR /mlsteam/lab

ADD clean-layer.sh requirements.txt requirements.system install-sshd.sh set_terminal_dark.sh /tmp/

RUN apt-key del 7fa2af80
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/7fa2af80.pub

RUN sed -i 's/archive.ubuntu.com/tw.archive.ubuntu.com/g' /etc/apt/sources.list && \
    mkdir -p /mlsteam/data && \
    mkdir -p /mlsteam/lab && \
    mkdir -p /mlsteam/.keras/models && \
    apt-get update && \
    xargs apt-get install -y < /tmp/requirements.system && \
    pip3 install --no-cache-dir -r /tmp/requirements.txt && \
    bash /tmp/install-sshd.sh && \
    bash /tmp/set_terminal_dark.sh && \
    bash /tmp/clean-layer.sh

RUN pip3 install --upgrade https://github.com/myelintek/lib-mlsteam/releases/download/v0.3/mlsteam-0.3.0-py3-none-any.whl

ADD src /mlsteam/lab
ADD bash.bashrc /etc/bash.bashrc
ADD mobilenet_v2_weights_tf_dim_ordering_tf_kernels_1.0_224_no_top.h5 /mlsteam/.keras/models/

RUN cd /mlsteam/lab && \
	git clone https://github.com/chandrikadeb7/Face-Mask-Detection.git && \
    jupyter nbconvert --to notebook --inplace --execute entry.ipynb inference.ipynb training.ipynb && \
	rm -rf /mlsteam/data/*

RUN rm -rf /usr/lib/x86_64-linux-gnu/libcuda.so /usr/lib/x86_64-linux-gnu/libcuda.so.1 /tmp/*

