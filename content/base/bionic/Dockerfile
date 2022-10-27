# Using dated tags from https://hub.docker.com/_/ubuntu/
FROM ubuntu:bionic

MAINTAINER RStudio Docker <docker@rstudio.com>
LABEL maintainer="RStudio Docker <docker@rstudio.com>"

# Locale configuration --------------------------------------------------------#
RUN apt-get update && \
	apt-get install -y locales && \
	localedef -i en_US -f UTF-8 en_US.UTF-8 && \
        rm -rf /var/lib/apt/lists/*
	
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

# Installation prerequisites --------------------------------------------------#
# curl is used to download things.
# libev-dev is required for most interactive Python applications.
RUN apt-get update \
        && \
        apt-get install -y \
        curl \
        libev-dev \
        && \
        rm -rf /var/lib/apt/lists/*

# System dependencies needed by popular R packages
# https://docs.rstudio.com/rsc/post-setup-tool/#install-system-dependencies

# Now, install the system requirements for R packages.
RUN apt-get update \
        && \
        apt-get install -y \
        default-jdk \
        gdal-bin \
        git \
        gsfonts \
        imagemagick \
        libcairo2-dev \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libgdal-dev \
        libgeos-dev \
        libgl1-mesa-dev \
        libglpk-dev \
        libglu1-mesa-dev \
        libgmp3-dev \
        libharfbuzz-dev \
        libicu-dev \
        libjpeg-dev \
        libmagick++-dev \
        libmysqlclient-dev \
        libpng-dev \
        libpq-dev \
        libproj-dev \
        libsodium-dev \
        libssh2-1-dev \
        libssl-dev \
        libtiff-dev \
        libudunits2-dev \
        libv8-dev \
        libicu-dev \
        libxml2-dev \
        make \
        perl \
        tcl \
        tk \
        tk-dev \
        tk-table \
        unixodbc-dev \
        zlib1g-dev \
        && \
        rm -rf /var/lib/apt/lists/*

# Install TinyTeX --------------------------------------------------------------#

# From https://github.com/rstudio/r-docker/blob/master/base/bionic/Dockerfile

RUN apt-get update && \
    apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/* && \
    wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh && \
    /root/.TinyTeX/bin/*/tlmgr path remove && \
    mv /root/.TinyTeX/ /opt/TinyTeX && \
    /opt/TinyTeX/bin/*/tlmgr option sys_bin /usr/local/bin && \
    /opt/TinyTeX/bin/*/tlmgr path add && \
    rm -rf /var/lib/apt/lists/*

# install packages
RUN /opt/TinyTeX/bin/*/tlmgr install \
        baskervaldx \
        carlisle \
        fancyhdr \
        hardwrap \
        ly1 \
        morefloats \
        ms \
        pagecolor \
        pgf \
        setspace \
        textcase \
        titlesec \
        transparent \
        tufte-latex \
        units \
        ulem \
        xcolor

# Install R -------------------------------------------------------------------#

# Reference: https://docs.rstudio.com/resources/install-r/

# We are NOT linking one of these R versions into the PATH.

ARG R_DISTRIBUTION=ubuntu-1804

ARG R_VERSION=3.6.3
ARG R_INSTALLER=r-${R_VERSION}_1_amd64.deb
RUN curl -fsSL -O https://cdn.rstudio.com/r/${R_DISTRIBUTION}/pkgs/${R_INSTALLER} && \
    apt-get update && \
    apt-get install -f -y ./${R_INSTALLER} && \
    rm ${R_INSTALLER} && \
    rm -rf /var/lib/apt/lists/*


# Install Python --------------------------------------------------------------#

# Reference: https://docs.rstudio.com/resources/install-python/

# We are NOT linking one of these Python versions into the PATH.

ARG MINICONDA_VERSION=4.7.12.1
ARG PYTHON_VERSION=3.7.6

# The documented approach uses a particular miniconda install script version
# to obtain the desired Python version. We are first installing miniconda and
# then asking it to install different Python versions.

RUN curl -fsSL -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
    && chmod 755 miniconda.sh \
    && ./miniconda.sh -b -p /opt/miniconda \
    && /opt/miniconda/bin/conda create --quiet --yes --prefix /opt/python/${PYTHON_VERSION} python=${PYTHON_VERSION} virtualenv \
    && rm -f miniconda.sh \
    # remove miniconda too, for size
    && rm -rf /opt/miniconda

# install quarto
ARG QUARTO_VERSION=1.0.37
COPY maybe_install_quarto.sh /tmp/maybe_install_quarto.sh
RUN /opt/R/${R_VERSION}/bin/R -e 'install.packages("odbc", repos="https://packagemanager.rstudio.com/cran/__linux__/bionic/latest")' && \
    /tmp/maybe_install_quarto.sh && \
    rm -f /tmp/maybe_install_quarto.sh
