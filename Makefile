R_VERSION ?= 3.6.2
R_VERSION_ALT ?= 4.1.0

PYTHON_VERSION ?= 3.9.5
PYTHON_VERSION_ALT ?= 3.8.10

RSP_VERSION ?= 1.4.1717-3
RSC_VERSION ?= 2021.09.0
RSPM_VERSION ?= 2021.09.0-1

RSP_LICENSE ?= ""
RSC_LICENSE ?= ""
RSPM_LICENSE ?= ""

RSP_FLOAT_LICENSE ?= ""
RSC_FLOAT_LICENSE ?= ""
RSPM_FLOAT_LICENSE ?= ""
SSP_FLOAT_LICENSE ?= ""

RSP_LICENSE_SERVER ?= ""
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

all: help


images: server-pro connect package-manager  ## Build all images
	docker-compose build


update-versions:  ## Update the version files for all products
	@sed -i '' "s/^RSP_VERSION=.*/RSP_VERSION=${RSP_VERSION}/g" server-pro/.env
	@sed -i '' "s/^RSP_VERSION=.*/RSP_VERSION=${RSP_VERSION}/g" r-session-complete/bionic/.env
	@sed -i '' "s/^RSP_VERSION=.*/RSP_VERSION=${RSP_VERSION}/g" r-session-complete/centos7/.env
	@sed -i '' "s/^RSC_VERSION=.*/RSC_VERSION=${RSC_VERSION}/g" connect/.env
	@sed -i '' "s/^RSPM_VERSION=.*/RSPM_VERSION=${RSPM_VERSION}/g" package-manager/.env
	@sed -i '' "s/^ARG RSP_VERSION=.*/ARG RSP_VERSION=${RSP_VERSION}/g" server-pro/Dockerfile
	@sed -i '' "s/^ARG RSC_VERSION=.*/ARG RSC_VERSION=${RSC_VERSION}/g" connect/Dockerfile
	@sed -i '' "s/^ARG RSC_VERSION=.*/ARG RSC_VERSION=${RSC_VERSION}/g" connect-content-init/Dockerfile
	@sed -i '' "s/^ARG RSPM_VERSION=.*/ARG RSPM_VERSION=${RSPM_VERSION}/g" package-manager/Dockerfile
	@sed -i '' "s/^RSPM_VERSION:.*/RSPM_VERSION: ${RSPM_VERSION}/g" docker-compose.yml
	@sed -i '' "s/RSPM_VERSION:.*/RSPM_VERSION: ${RSPM_VERSION}/g" docker-compose.yml
	@sed -i '' "s/rstudio\/rstudio-package-manager:.*/rstudio\/rstudio-package-manager:${RSPM_VERSION}/g" docker-compose.yml
	@sed -i '' "s/RSC_VERSION:.*/RSC_VERSION: ${RSC_VERSION}/g" docker-compose.yml
	@sed -i '' "s/rstudio\/rstudio-connect:.*/rstudio\/rstudio-connect:${RSC_VERSION}/g" docker-compose.yml
	@sed -i '' "s/RSP_VERSION:.*/RSP_VERSION: ${RSP_VERSION}/g" docker-compose.yml
	@sed -i '' "s/rstudio\/rstudio-server-pro:.*/rstudio\/rstudio-server-pro:${RSP_VERSION}/g" docker-compose.yml
	@sed -i '' "s/^R_VERSION:.*/R_VERSION=${R_VERSION}/g" server-pro/Dockerfile
	@sed -i '' "s/^R_VERSION:.*/R_VERSION=${R_VERSION}/g" connect/Dockerfile
	@sed -i '' "s/^R_VERSION:.*/R_VERSION=${R_VERSION}/g" package-manager/Dockerfile
	@sed -i '' "s|^RVersion.*=.*|RVersion = /opt/R/${R_VERSION}/|g" package-manager/rstudio-pm.gcfg
	@sed -i '' "s/^ARG RSP_VERSION=.*/ARG RSP_VERSION=${RSP_VERSION}/g" r-session-complete/bionic/Dockerfile
	@sed -i '' "s/^ARG RSP_VERSION=.*/ARG RSP_VERSION=${RSP_VERSION}/g" r-session-complete/centos7/Dockerfile


rsp: server-pro
server-pro:  ## Build RSP image
	docker build -t rstudio/rstudio-server-pro:$(RSP_VERSION) --build-arg R_VERSION=$(R_VERSION) --build-arg RSP_VERSION=$(RSP_VERSION) server-pro

rsp-hook:
	cd ./server-pro && \
	DOCKERFILE_PATH=Dockerfile \
	IMAGE_NAME=rstudio/rstudio-server-pro:$(RSP_VERSION) \
	./hooks/build

test-rsp: test-server-pro
test-server-pro:
	cd ./server-pro && IMAGE_NAME=rstudio/rstudio-server-pro:$(RSP_VERSION) docker-compose -f docker-compose.test.yml run sut
test-server-pro-float:
	cd ./server-pro && IMAGE_NAME=rstudio/rstudio-server-pro:$(RSP_VERSION) docker-compose -f docker-compose.test-float.yml run sut
test-rsp-i: test-server-pro-i
test-server-pro-i:
	cd ./server-pro && IMAGE_NAME=rstudio/rstudio-server-pro:$(RSP_VERSION) docker-compose -f docker-compose.test.yml run sut bash
test-server-pro-float-i:
	cd ./server-pro && IMAGE_NAME=rstudio/rstudio-server-pro:$(RSP_VERSION) docker-compose -f docker-compose.test-float.yml run sut bash


run-rsp: run-server-pro
run-server-pro:  ## Run RSP container
	docker rm rstudio-server-pro
	docker run -it --privileged \
		--name rstudio-server-pro \
		-p 8787:8787 \
		-v /run \
		-e RSP_LICENSE=$(RSP_LICENSE) \
		rstudio/rstudio-server-pro:$(RSP_VERSION) $(CMD)

rsc: connect
connect:  ## Build RSC image
	docker build -t rstudio/rstudio-connect:$(RSC_VERSION) --build-arg R_VERSION=$(R_VERSION) --build-arg RSC_VERSION=$(RSC_VERSION) connect

test-rsc: test-connect
test-connect:
	cd ./connect && IMAGE_NAME=rstudio/rstudio-connect:$(RSC_VERSION) docker-compose -f docker-compose.test.yml run sut
test-rsc-i: test-connect-i
test-connect-i:
	cd ./connect && IMAGE_NAME=rstudio/rstudio-connect:$(RSC_VERSION) docker-compose -f docker-compose.test.yml run sut bash


run-rsc: run-connect
run-connect:  ## Run RSC container
	docker rm rstudio-connect
	docker run -it --privileged \
		--name rstudio-connect \
		-p 3939:3939 \
		-v $(CURDIR)/data/rsc:/var/lib/rstudio-connect \
		-v $(CURDIR)/connect/rstudio-connect.gcfg:/etc/rstudio-connect/rstudio-connect.gcfg \
		-e RSC_LICENSE=$(RSC_LICENSE) \
		rstudio/rstudio-connect:$(RSC_VERSION) $(CMD)


rspm: package-manager
package-manager:  ## Build RSPM image
	docker build -t rstudio/rstudio-package-manager:$(RSPM_VERSION) --build-arg R_VERSION=$(R_VERSION) --build-arg RSPM_VERSION=$(RSPM_VERSION) package-manager


test-rspm: test-package-manager
test-package-manager:
	cd ./package-manager && IMAGE_NAME=rstudio/rstudio-package-manager:$(RSPM_VERSION) docker-compose -f docker-compose.test.yml run sut
test-rspm-i: test-package-manager-i
test-package-manager-i:
	cd ./package-manager && IMAGE_NAME=rstudio/rstudio-package-manager:$(RSPM_VERSION) docker-compose -f docker-compose.test.yml run sut bash


run-rspm: run-package-manager
run-package-manager:  ## Run RSPM container
	docker rm rstudio-package-manager
	docker run -it --privileged \
		--name rstudio-package-manager \
		-p 4242:4242 \
		-v $(CURDIR)/data/rspm:/data \
		-v $(CURDIR)/package-manager/rstudio-pm.gcfg:/etc/rstudio-pm/rstudio-pm.gcfg \
		-e RSPM_LICENSE=$(RSPM_LICENSE)  \
		rstudio/rstudio-package-manager:$(RSPM_VERSION) $(CMD)


test-all: rspm test-rspm rsc test-rsc rsp test-rsp


float:
	docker-compose -f helper/float/docker-compose.yml build

run-float: run-floating-lic-server
run-floating-lic-server:  ## Run the floating license server for RSP products
	RSP_FLOAT_LICENSE=$(RSP_FLOAT_LICENSE) RSC_FLOAT_LICENSE=$(RSC_FLOAT_LICENSE) RSPM_FLOAT_LICENSE=$(RSPM_FLOAT_LICENSE) SSP_FLOAT_LICENSE=$(SSP_FLOAT_LICENSE) \
	docker-compose -f helper/float/docker-compose.yml up


help:  ## Show this help menu
	@grep -E '^[0-9a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##"; OFS="\t\t"}; {printf "\033[36m%-30s\033[0m %s\n", $$1, ($$2==""?"":$$2)}'


.PHONY: server-pro rsp run-server-pro connect rsc run-connect package-manager rspm run-package-manager run-floatating-lic-server
