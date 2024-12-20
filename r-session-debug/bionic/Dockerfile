ARG RSP_VERSION
FROM rstudio/r-session-complete:bionic-${RSP_VERSION}

RUN apt-get update -qq \
    && apt-get install -y \
        dnsutils \
        tcpdump \
        netcat \
        net-tools \
        psutils \
        vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY startup.sh /usr/local/bin/startup.sh
