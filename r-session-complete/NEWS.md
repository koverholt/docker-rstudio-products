# 2023.11.21
- Added `Dockerfile.rockylinux9`, a community contribution! 
  - *NOTE: This image is not officially built or supported by Posit at this time.*

# 2023.03.1
- Update Python VSCode extension to version 2023.6.1

# 2023.03.0

- Update R versions to 4.1.3 and 4.2.3
- Update Python versions to 3.8.15 and 3.9.14

# 2022.12.0

- Upgrade workbench to 2022.12.0
- Use the new `WORKBENCH_JUPYTER_PATH` env var to configure jupyter location
- Remove `vscode.conf/exe` configuration in favor of the new, internal default `code-server` installation
- Refactor image to build _FROM_ the new `product-base-pro` image

# 2022.07.0

- Add a `/usr/local/bin/jupyter` symlink
- Configure Workbench to preinstall R, Python, and Quarto extensions for users on session startup
- Add workbench_jupyterlab python package for the jupyterlab extension

# 2021.09.0

- **BREAKING**: Rename `RSP_` variables to `RSW_`. Rename RStudio Server Pro to RStudio Workbench
- **BREAKING**: Change `R_VERSION` to 4.1.0
- **BREAKING**: Change `PYTHON_VERSION` to 3.9.5
- **BREAKING**: R and Python packages are no longer installed by default in session images.

We have removed R and Python packages from the session image.  This should:
- reduce the image build time and size
- make it easier for data scientists to develop reproducible environments
- eliminate conflicts between system libraries and subsequent user updates

If the removal of these system libraries introduces some problems for you, please file an issue.

# 1.4.1717-3

## Overview

R is at `/opt/R/4.0.2/bin/R`
python is at `/opt/python/3.7.7/bin/python`
jupyter is at `/opt/python/3.7.7/bin/jupyter`
code-server is at `/opt/code-server/bin/code-server`

## Changes

- Update RStudio Professional Drivers to 1.8.0
- `BREAKING`: `code-server` no longer supports the `/opt/code-server/code-server` location. 
  - As a result, you need to set `exe=/opt/code-server/bin/code-server`
  - After two changes in a row, we suspect this is the final change for a while
_vscode.conf_
```
enabled=1
exe=/opt/code-server/bin/code-server
```

# 1.4.1106-5

## Overview

R is at `/opt/R/4.0.2/bin/R`
python is at `/opt/python/3.7.7/bin/python`
jupyter is at `/opt/python/3.7.7/bin/jupyter`
code-server is at `/opt/code-server/code-server`

## Changes

- `BREAKING`: Changed code-server version and insulated against version upgrades in the future. To update:
change:

_vscode.conf_
```
enabled=1
exe=/opt/code-server/code-server-3.2.0-linux-x86_64/code-server
```
to:
_vscode.conf_
```
enabled=1
exe=/opt/code-server/code-server
```

- Update Drivers to version 1.7.0

# 1.4.1103-4

## Overview

R is at `/opt/R/4.0.2/bin/R`
python is at `/opt/python/3.7.7/bin/python`
jupyter is at `/opt/python/3.7.7/bin/jupyter`
code-server is at `/opt/code-server/code-server-3.2.0-linux-x86_64/code-server`
