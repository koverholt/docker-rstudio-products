# RStudio Package Manager

Docker images for RStudio Professional Products

**IMPORTANT:** There are a few things you need to know before using these images:

1. This image may introduce **BREAKING** changes, as such we recommend:
   - Avoid using the `latest` tag to avoid unexpected issues, and
   - Always read through the [NEWS](./NEWS.md) to understand these changes before updating.
1. These images are provided as a convenience to RStudio customers and are not formally supported by RStudio. If you
   have questions about these images, you can ask them in the issues in the repository or to your support
   representative, who will route them appropriately.
1. Outdated images will be removed periodically from DockerHub as product version updates are made. Please make plans to
   update at times or use your own build of the images.
1. These images are meant as a starting point for your needs. Consider creating a fork of this repo, where you can
   continue to merge in changes we make while having your own security scanning, base OS in use, or other custom
   changes. We
   provide [instructions for building](https://github.com/rstudio/rstudio-docker-products#instructions-for-building) for
   these cases.
1. The Package Manager image uses the `No Sandbox` option documented
   [here](https://docs.rstudio.com/rspm/admin/process-management/#process-management-sandboxing) by default, if you need
   a more secure option for configuring
   [Git-related package builds](https://docs.rstudio.com/rspm/admin/building-packages/) we recommend [using a system with
   sandboxing enabled](https://docs.rstudio.com/rspm/admin/process-management/#docker).

## Simple Example

To verify basic functionality as a first step:

```bash
# Replace with valid license
export RSPM_LICENSE=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX

# Run without persistent data and using default configuration
docker run -it \
    -p 4242:4242 \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    rstudio/rstudio-package-manager:latest
    
# Alternatively, the above can be ran using a single just command
just RSPM_LICENSE=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX run
```

Open [http://localhost:4242](http://localhost:4242) to access RStudio Package Manager UI.

For a more "real" deployment, continue reading!

## Overview

Note that running the RStudio Package Manager Docker image requires a valid RStudio Package Manager license.

This container includes:

1. R 3.6.2
2. RStudio Package Manager

> NOTE: Package Manager is currently not very particular about R version. Changing the R version is rarely necessary.

## Configuration

RStudio Package Manager is configured via the`/etc/rstudio-pm/rstudio-pm.gcfg` file. You should mount this file as
a volume from the host machine. Changes will take effect when the container is restarted.

Be sure the config file has the `[HTTP].Listen` field configured. See a complete example of that file at
[`package-manager/rstudio-pm.gcfg`](./rstudio-pm.gcfg).

## Persistent Data

In order to persist Package Manager data between container restarts, configure the `Server.DataDir` option to go to
a persistent volume. The included configuration file expects a persistent volume from the host machine or your docker
orchestration system to be available at `/var/lib/rstudio-pm`. Should you wish to move this to a different path, you can change the
`Server.DataDir` option.

When changing `Server.DataDir` to a custom location, we also recommend setting `Server.LauncherDir`
to a consistent location within `Server.DataDir`, such as `{Server.DataDir}/launcher_internal`.
The default location of `Server.LauncherDir` depends on the container's hostname, which may be
different each time the container restarts.

```ini
[Server]
DataDir = /mnt/rspm/data
; Use a consistent location for the Launcher directory. The default location
; is based on the hostname, and the hostname may be different in each container.
LauncherDir = /mnt/rspm/data/launcher_internal
```

## Licensing

Using the RStudio Package Manager Docker image requires a valid license for Package Manager. You can set the license in three ways:

1. Setting the `RSPM_LICENSE` environment variable to a valid license key inside the container
2. Setting the `RSPM_LICENSE_SERVER` environment variable to a valid license server / port inside the container
3. Mounting a `/etc/rstudio-pm/license.lic` single file that contains a valid license for RStudio Package Manager

**NOTE:** the "offline activation process" is not supported by this image today. Offline installations will need
to explore using a license server, license file, or custom image with manual intervention.

## Environment variables

| Variable | Description | Default |
|-----|---|---|
| `RSPM_LICENSE` | License key for RStudio Package Manager, format should be: `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX` | None |
| `RSPM_LICENSE_SERVER` | Floating license server, format should be: `my.url.com:port` | None |

## Ports

| Variable | Description |
|-----|---|
| `4242` | Default HTTP Port for RStudio Package Manager |

## Example usage

```bash
# Replace with valid license
export RSPM_LICENSE=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX

# Run without persistent data and using an external configuration
docker run -it \
    -p 4242:4242 \
    -v $PWD/package-manager/rstudio-pm.gcfg:/etc/rstudio-pm/rstudio-pm.gcfg \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    rstudio/rstudio-package-manager:latest

# Run with persistent data and using an external configuration
docker run -it \
    -p 4242:4242 \
    -v $PWD/data/rspm:/data \
    -v $PWD/package-manager/rstudio-pm.gcfg:/etc/rstudio-pm/rstudio-pm.gcfg \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    rstudio/rstudio-package-manager:latest
```

Open [http://localhost:4242](http://localhost:4242) to access RStudio Package Manager UI.

To create repositories you need to access the container directly and execute some commands.
To do this find the container ID for RSPM (using `docker ps`) and run:

```bash
docker exec -it {container-id} /bin/bash
```

Then please refer to the [RSPM guide](https://docs.rstudio.com/rspm/admin/) on how
to [create and manage](https://docs.rstudio.com/rspm/admin/getting-started/configuration/) your repositories.

#### example of adding a local tarball built in rsw to rspm

For this example, a package, `demo1` was created with version 0.1.0 and a 
tarball was created using the build pane in rsw. This will write out the
tarball on the host system at `data/rsw/rstudio/demo1_0.1.0.tar.gz`

Copy the tarball into the `/tmp` dir using `docker cp`:

Find the container id for the running package-manager container via `docker ps`:

```bash
❯ docker ps
CONTAINER ID   IMAGE ...
b8ae944b7f2d   rstudio/rstudio-package-manager:2021.12.0-3 ...
```

```bash
# replace b8ae944b7f2d with your container ID
docker cp data/rsw/rstudio/demo1_0.1.0.tar.gz b8ae944b7f2d:/tmp
```

now you can create the repo in rspm

```bash
root@1b6f4f5fc669:/# rspm create source --name=demopkgs
Source 'demopkgs':
  Type:  Local
root@1b6f4f5fc669:/# rspm add --source=demopkgs --path='/tmp/demo1_0.1.0.tar.gz'
Added package '/tmp/demo1_0.1.0.tar.gz'.
root@1b6f4f5fc669:/# rspm create repo --name=demopkgs --description="demo package repo"
Repository: demopkgs - demo package repo - R
root@1b6f4f5fc669:/# rspm subscribe --repo=demopkgs --source=demopkgs
Repository: demopkgs
Sources:
--demopkgs (Local)
```

It can then be installed from R on the local machine:

```R
> install.packages("demo1", repos = "http://rstudio-package-manager:4242/demopkgs/latest")
Installing package into ‘/home/rstudio/R/x86_64-pc-linux-gnu-library/3.6’
(as ‘lib’ is unspecified)
trying URL 'http://rstudio-package-manager:4242/demopkgs/latest/src/contrib/demo1_0.1.0.tar.gz'
Content type 'application/x-gzip' length 859 bytes
==================================================
downloaded 859 bytes

* installing *source* package ‘demo1’ ...
** using staged installation
** R
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
** building package indices
** testing if installed package can be loaded from temporary location
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (demo1)

The downloaded source packages are in
	‘/tmp/RtmpRVTKFG/downloaded_packages’
```

# Licensing

The license associated with the RStudio Docker Products repository is located
[in LICENSE.md](https://github.com/rstudio/rstudio-docker-products/blob/main/LICENSE.md).

As is the case with all container images, the images themselves also contain other software which may be under other
licenses (i.e. bash, linux, system libraries, etc., along with any other direct or indirect dependencies of the primary
software being contained).

It is an image user's responsibility to ensure that use of this image (and any of its dependent layers) complies with
all relevant licenses for the software contained in the image.
