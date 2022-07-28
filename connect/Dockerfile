ARG R_VERSION=3.6.2
FROM rstudio/r-base:${R_VERSION}-bionic
LABEL maintainer="RStudio Docker <docker@rstudio.com>"

# Locale configuration --------------------------------------------------------#
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008,DL3009
RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        gdal-bin \
        gdebi-core \
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
        libglib2.0-0 \
        libglpk-dev \
        libglu1-mesa-dev \
        libgmp3-dev \
        libharfbuzz-dev \
        libicu-dev \
        libjpeg-dev \
        libmagick++-dev \
        libmysqlclient-dev \
        libpng-dev \
        libproj-dev \
        libsm6 \
        libsodium-dev \
        libssh2-1-dev \
        libssl-dev \
        libssl1.0.0 \
        libtiff-dev \
        libudunits2-dev \
        libv8-dev \
        libxext6 \
        libxml2-dev \
        libxrender1 \
        make \
        perl \
        sudo \
        tcl \
        tk \
        tk-dev \
        tk-table \
        unixodbc-dev \
        wget \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add another R version -------------------------------------------------------#

ARG R_VERSION_ALT=4.1.0
RUN apt-get update -qq && \
    curl -O https://cdn.rstudio.com/r/ubuntu-1804/pkgs/r-${R_VERSION_ALT}_1_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive gdebi --non-interactive r-${R_VERSION_ALT}_1_amd64.deb && \
    rm -f ./r-${R_VERSION_ALT}_1_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python  -------------------------------------------------------------#
ARG PYTHON_VERSION=3.9.5
RUN curl -O https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda3-4.7.12.1-Linux-x86_64.sh -bp /opt/python/${PYTHON_VERSION} && \
    /opt/python/${PYTHON_VERSION}/bin/conda install -y python==${PYTHON_VERSION} && \
    /opt/python/${PYTHON_VERSION}/bin/pip install 'virtualenv<20' && \
    /opt/python/${PYTHON_VERSION}/bin/pip install --upgrade setuptools && \
    rm -rf Miniconda3-*-Linux-x86_64.sh

# Install another Python --------------------------------------------------------------#

ARG PYTHON_VERSION_ALT=3.8.10
RUN curl -O https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda3-4.7.12.1-Linux-x86_64.sh -bp /opt/python/${PYTHON_VERSION_ALT} && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/conda install -y python==${PYTHON_VERSION_ALT} && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/pip install 'virtualenv<20' && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/pip install --upgrade setuptools && \
    rm -rf Miniconda3-*-Linux-x86_64.sh

# Runtime settings ------------------------------------------------------------#
ARG TINI_VERSION=0.18.0
RUN curl -L -o /usr/local/bin/tini https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini && \
    chmod +x /usr/local/bin/tini

COPY --chmod=0775 startup.sh /usr/local/bin/startup.sh

# Download RStudio Connect -----------------------------------------------------#
ARG RSC_VERSION=2022.07.0
SHELL [ "/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update --fix-missing \
    && RSC_VERSION_URL=`echo -n "${RSC_VERSION}" | sed 's/+/%2B/g'` \
    && curl -L -o rstudio-connect.deb https://cdn.rstudio.com/connect/$(echo $RSC_VERSION | sed -r 's/([0-9]+\.[0-9]+).*/\1/')/rstudio-connect_${RSC_VERSION_URL}~ubuntu18_amd64.deb \
    && gdebi -n rstudio-connect.deb \
    && rm -rf rstudio-connect.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 3939/tcp
ENV RSC_LICENSE ""
ENV RSC_LICENSE_SERVER ""
COPY rstudio-connect.gcfg /etc/rstudio-connect/rstudio-connect.gcfg
VOLUME ["/data"]

COPY /docker-entrypoint.sh .
COPY /docker-entrypoint.d/* /docker-entrypoint.d/
ONBUILD COPY /docker-entrypoint.d/* /docker-entrypoint.d/
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["/usr/local/bin/startup.sh"]
