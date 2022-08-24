IMAGE_OS ?= bionic

R_VERSION ?= 3.6.2
R_VERSION_ALT ?= 4.1.0

PYTHON_VERSION ?= 3.9.5
PYTHON_VERSION_ALT ?= 3.8.10

RSW_VERSION ?= 2022.07.1+554.pro3
RSC_VERSION ?= 2022.08.0
RSPM_VERSION ?= 2022.07.2-11

DRIVERS_VERSION ?= 2021.10.0

RSW_LICENSE ?= ""
RSC_LICENSE ?= ""
RSPM_LICENSE ?= ""

RSW_FLOAT_LICENSE ?= ""
RSC_FLOAT_LICENSE ?= ""
RSPM_FLOAT_LICENSE ?= ""
SSP_FLOAT_LICENSE ?= ""

RSW_LICENSE_SERVER ?= ""
RSC_LICENSE_SERVER ?= ""
RSPM_LICENSE_SERVER ?= ""

# Optional Command for docker run
CMD ?=

SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules


# To avoid the issue between mac and linux
# Mac require -i '', while -i is the preferred on linux
UNAME_S := $(shell uname -s)

SED_FLAGS=""
ifeq ($(UNAME_S),Linux)
	SED_FLAGS="-i"
else ifeq ($(UNAME_S),Darwin)
	SED_FLAGS="-i ''"
endif

RSW_TAG_VERSION=`echo "$(RSW_VERSION)" | sed -e 's/\+/-/'`

all: help


images: workbench connect package-manager  ## Build all images
	DOCKER_BUILDKIT=1 IMAGE_OS=$(IMAGE_OS) docker-compose build


update-versions:  ## Update the version files for all products
	just RSW_VERSION=${RSW_VERSION} RSC_VERSION=${RSC_VERSION} RSPM_VERSION=${RSPM_VERSION} R_VERSION=${R_VERSION} update-versions 

update-drivers:  ## Update the driver version
	@sed $(SED_FLAGS) "s/^DRIVERS_VERSION=.*/DRIVERS_VERSION=${DRIVERS_VERSION}/g" content/pro/Makefile
	@sed $(SED_FLAGS) "s/\"drivers\": \".[^\,\}]*\"/\"drivers\": \"${DRIVERS_VERSION}\"/g" content/matrix.json
	@sed $(SED_FLAGS) "s/^ARG DRIVERS_VERSION=.*/ARG DRIVERS_VERSION=${DRIVERS_VERSION}/g" helper/workbench-for-microsoft-azure-ml/Dockerfile

rsw: workbench
workbench:  ## Build Workbench image
	DOCKER_BUILDKIT=1 docker build -t rstudio/rstudio-workbench:$(RSW_TAG_VERSION) --build-arg R_VERSION=$(R_VERSION) --build-arg RSW_VERSION=$(RSW_VERSION) --file workbench/Dockerfile.$(IMAGE_OS) workbench

test-rsw: test-workbench
test-workbench:
	cd ./workbench && IMAGE_NAME=rstudio/rstudio-workbench:$(RSW_TAG_VERSION) docker-compose -f docker-compose.test.yml run sut
test-rsw-i: test-workbench-i
test-workbench-i:
	cd ./workbench && IMAGE_NAME=rstudio/rstudio-workbench:$(RSW_TAG_VERSION) docker-compose -f docker-compose.test.yml run sut bash


run-rsw: run-workbench
run-workbench:  ## Run RSW container
	docker rm -f rstudio-workbench
	docker run -it \
		--name rstudio-workbench \
		-p 8787:8787 \
		-v $(PWD)/workbench/conf:/etc/rstudio/ \
		-v /run \
		-e RSW_LICENSE=$(RSW_LICENSE) \
		rstudio/rstudio-workbench:$(RSW_TAG_VERSION) $(CMD)


rsc: connect
connect:  ## Build RSC image
	DOCKER_BUILDKIT=1 docker build -t rstudio/rstudio-connect:$(RSC_VERSION) --build-arg R_VERSION=$(R_VERSION) --build-arg RSC_VERSION=$(RSC_VERSION) --file connect/Dockerfile.$(IMAGE_OS) connect

test-rsc: test-connect
test-connect:
	cd ./connect && IMAGE_NAME=rstudio/rstudio-connect:$(RSC_VERSION) docker-compose -f docker-compose.test.yml run sut
test-rsc-i: test-connect-i
test-connect-i:
	cd ./connect && IMAGE_NAME=rstudio/rstudio-connect:$(RSC_VERSION) docker-compose -f docker-compose.test.yml run sut bash


run-rsc: run-connect
run-connect:  ## Run RSC container
	docker rm -f rstudio-connect
	docker run -it --privileged \
		--name rstudio-connect \
		-p 3939:3939 \
		-v $(CURDIR)/data/rsc:/var/lib/rstudio-connect \
		-v $(CURDIR)/connect/rstudio-connect.gcfg:/etc/rstudio-connect/rstudio-connect.gcfg \
		-e RSC_LICENSE=$(RSC_LICENSE) \
		rstudio/rstudio-connect:$(RSC_VERSION) $(CMD)


rspm: package-manager
package-manager:  ## Build RSPM image
	DOCKER_BUILDKIT=1 docker build -t rstudio/rstudio-package-manager:$(RSPM_VERSION) --build-arg R_VERSION=$(R_VERSION) --build-arg RSPM_VERSION=$(RSPM_VERSION) --file package-manager/Dockerfile.$(IMAGE_OS) package-manager


test-rspm: test-package-manager
test-package-manager:
	cd ./package-manager && IMAGE_NAME=rstudio/rstudio-package-manager:$(RSPM_VERSION) docker-compose -f docker-compose.test.yml run sut
test-rspm-i: test-package-manager-i
test-package-manager-i:
	cd ./package-manager && IMAGE_NAME=rstudio/rstudio-package-manager:$(RSPM_VERSION) docker-compose -f docker-compose.test.yml run sut bash


run-rspm: run-package-manager
run-package-manager:  ## Run RSPM container
	docker rm -f rstudio-package-manager
	docker run -it \
		--name rstudio-package-manager \
		-p 4242:4242 \
		-v $(CURDIR)/data/rspm:/data \
		-v $(CURDIR)/package-manager/rstudio-pm.gcfg:/etc/rstudio-pm/rstudio-pm.gcfg \
		-e RSPM_LICENSE=$(RSPM_LICENSE)  \
		rstudio/rstudio-package-manager:$(RSPM_VERSION) $(CMD)


test-all: rspm test-rspm rsc test-rsc rsw test-rsw

test-azure: test-rsw-azure

rsw-azure: workbench-azure
workbench-azure:  ## Build Workbench for Microsoft Azure ML image
	DOCKER_BUILDKIT=1 docker build \
		-t rstudio/rstudio-workbench-for-microsoft-azure-ml:$(RSW_TAG_VERSION) \
		--build-arg R_VERSION=$(R_VERSION) \
		--build-arg RSW_VERSION=$(RSW_VERSION) \
		helper/workbench-for-microsoft-azure-ml

test-rsw-azure: test-workbench-azure
test-workbench-azure:
	cd ./helper/workbench-for-microsoft-azure-ml && IMAGE_NAME=rstudio/rstudio-workbench-for-microsoft-azure-ml:$(RSW_TAG_VERSION) docker-compose -f docker-compose.test.yml run sut
test-rsw-azure-i: test-workbench-azure-i
test-workbench-azure-i:
	cd ./helper/workbench-for-microsoft-azure-ml && IMAGE_NAME=rstudio/rstudio-workbench-for-microsoft-azure-ml:$(RSW_TAG_VERSION) docker-compose -f docker-compose.test.yml run sut bash

float:
	docker-compose -f helper/float/docker-compose.yml build

run-float: run-floating-lic-server
run-floating-lic-server:  ## [DO NOT USE IN PRODUCTION] Run the floating license server for pro products
	RSW_FLOAT_LICENSE=$(RSW_FLOAT_LICENSE) RSC_FLOAT_LICENSE=$(RSC_FLOAT_LICENSE) RSPM_FLOAT_LICENSE=$(RSPM_FLOAT_LICENSE) SSP_FLOAT_LICENSE=$(SSP_FLOAT_LICENSE) \
	docker-compose -f helper/float/docker-compose.yml up


help:  ## Show this help menu
	@grep -E '^[0-9a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##"; OFS="\t\t"}; {printf "\033[36m%-30s\033[0m %s\n", $$1, ($$2==""?"":$$2)}'


.PHONY: workbench rsw run-workbench connect rsc run-connect package-manager rspm run-package-manager run-floatating-lic-server
