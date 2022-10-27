#!/bin/bash

# only install quarto if python 3.10 and R 4.1 OR python 3.9 and R 4.1
# TODO: figure out a different hierarchy...
if ([[ `ls /opt/python/ | grep '3\.10\.'` ]] && [[ `ls /opt/R | grep '4\.1\.'` ]]) || ([[ `ls /opt/python/ | grep '3\.9\.'` ]] && [[ `ls /opt/R | grep '4\.1\.'` ]]) ; then
  qver=${QUARTO_VERSION:-1.0.37}
  echo '--> Installing Quarto'
  curl -L -o /quarto.deb https://github.com/quarto-dev/quarto-cli/releases/download/v${qver}/quarto-${qver}-linux-amd64.deb
  apt install /quarto.deb
  rm -f /quarto.deb
fi
