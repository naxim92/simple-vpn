SHELL := /bin/bash

TF_DIR := terraform
TFVARS_FILE :=  $(TF_DIR)/terraform.tfvars
DEV_ENV_FILE := docker/dev/.env
DEV_WEBUI_ENV_FILE := docker/webui/.env
DEV_WIREGUARD_ENV_FILE := docker/wireguard/.env

INSTALL_MSG := "Do you have valid DNS name linked with public ip?"
DESTROY_MSG := "Are you sure to destroy Wireguard infrastructure?"
CLEAN_MSG := "Are you sure to clean up?"
GCLOUD_FILE_MSG := "Specify path to gcloud credentials json (default: ../private/account.json): "
GCLOUD_PROJECT_MSG := "Specify gcloud project name: "
PUB_KEY_FILE_MSG := "Specify path to public key file to manage your cloud VPS (default: ../private/manager_key.pub): "
PRIVATE_KEY_FILE_MSG := "Specify path to private key file to manage your cloud VPS (default: ../private/manager_key.private): "
LETSENCRYPT_EMAIL_MSG := "Specify your email to manage let's encrypt certificates: "
WG_URL_MSG := "Specify Wireguard url to deploy it: "
WG_CLIENT_AMOUNT_MSG := "Specify how many clients the Wireguard will process: "

install: CONFIRMATION_MSG := $(INSTALL_MSG)
destroy: CONFIRMATION_MSG := $(DESTROY_MSG)
clean: CONFIRMATION_MSG := $(CLEAN_MSG)
clean_all: CONFIRMATION_MSG := $(CLEAN_MSG)

GCLOUD_FILE := "../private/account.json"
PUB_KEY_FILE := "../private/manager_key.pub"
PRIVATE_KEY_FILE := "../private/manager_key.private"

all: install

.PHONY: help config config_1 config_2 build-builder install deploy-prod deploy-public-ip deploy-service destroy clean clean_all clean_dev install-dev deploy-dev destroy-dev test test-pylint config_4 install-auto-test
help:
	@echo "--------------------------------------------------------------------------------"
	@echo "Use it for deploy, preparing environments, etc"
	@echo "To deploy on prod start install (it includes config)"
	@echo "To destroy prod start destroy"
	@echo "To config project's variables start config"
	@echo "To clean only tfvars start clean"
	@echo "To clean all runtime files start clean_all"
	@echo "To compile environment start build-builder"
	@echo "[DEV] To deploy project in dev environment start deploy-dev"
	@echo "[DEV] To clean artifatcs from dev environment start clean_dev"
	@echo "--------------------------------------------------------------------------------"
	

build-builder:
	@echo "Start preparing the environment..."
	docker build -f ./Dockerfile-builder -t naxim/simple-vpn-builder --force-rm  ./docker

install: config deploy-prod

deploy-prod: deploy-public-ip confirmation deploy-service

deploy-public-ip:
	@echo "Deploy Wireguard on production..."
	terraform -chdir=terraform init
	terraform -chdir=terraform apply -auto-approve -target google_compute_address.static

confirmation:
	$(eval ANSWER := $(shell read -n 1 -r -p $(CONFIRMATION_MSG) && echo $$REPLY))
	$(eval CONFIRMATION := $(shell [[ "$(ANSWER)" =~ ^[Yy]$$ ]] && echo 1))
	@echo

deploy-service:
	$(if $(CONFIRMATION), \
	terraform -chdir=terraform apply -auto-approve, \
	@echo "You need to create appropriate DNS record! Try again.")

config: config_1 $(TFVARS_FILE) config_2

config_1:
	@echo "--------------------------------------------------------------------------------"
	@echo "Let's configure our project!"
	@echo "(!) The root folder is ./terraform."
	@echo "Please mind about it when specify relative paths."
	@echo "--------------------------------------------------------------------------------"

$(TFVARS_FILE):
	$(eval GCLOUD_FILE := $(shell read -r -p $(GCLOUD_FILE_MSG) && echo $$REPLY))
	$(eval GCLOUD_PROJECT := $(shell read -r -p $(GCLOUD_PROJECT_MSG) && echo $$REPLY))
	$(eval PUB_KEY_FILE := $(shell read -r -p $(PUB_KEY_FILE_MSG) && echo $$REPLY))
	$(eval PRIVATE_KEY_FILE := $(shell read -r -p $(PRIVATE_KEY_FILE_MSG) && echo $$REPLY))
	$(eval LETSENCRYPT_EMAIL := $(shell read -r -p $(LETSENCRYPT_EMAIL_MSG) && echo $$REPLY))
	$(eval WG_URL := $(shell read -r -p $(WG_URL_MSG) && echo $$REPLY))
	$(eval WG_CLIENT_AMOUNT := $(shell read -r -p $(WG_CLIENT_AMOUNT_MSG) && echo $$REPLY))
	@echo
	@cp $@.tpl $@
	@sed -i 's~%GCLOUD_FILE%~$(GCLOUD_FILE)~' $@
	@sed -i 's~%GCLOUD_PROJECT%~$(GCLOUD_PROJECT)~' $@
	@sed -i 's~%PUB_KEY_FILE%~$(PUB_KEY_FILE)~' $@
	@sed -i 's~%PRIVATE_KEY_FILE%~$(PRIVATE_KEY_FILE)~' $@
	@sed -i 's~%LETSENCRYPT_EMAIL%~$(LETSENCRYPT_EMAIL)~' $@
	@sed -i 's~%WG_URL%~$(WG_URL)~' $@
	@sed -i 's~%WG_CLIENT_AMOUNT%~$(WG_CLIENT_AMOUNT)~' $@

config_2:
	@echo "Project configuration is successful"

destroy: confirmation
	$(if $(CONFIRMATION), terraform -chdir=terraform destroy -auto-approve, @echo)

clean: confirmation
	@rm -f $(TFVARS_FILE)

clean_all: confirmation
	@rm -rf $(TF_DIR)/.terraform
	@rm -f $(TF_DIR)/.terraform.lock.hcl
	@rm -f $(TF_DIR)/terraform.tfstate
	@rm -f $(TF_DIR)/.terraform.tfstate.lock.info
	@rm -f $(TF_DIR)/terraform.tfstate.backup
	@rm -f $(TFVARS_FILE)

install-dev: config_3 $(DEV_WEBUI_ENV_FILE) $(DEV_WIREGUARD_ENV_FILE) $(DEV_ENV_FILE) deploy-dev

config_3:
	@echo "--------------------------------------------------------------------------------"
	@echo "[DEV] Let's configure our project in DEVELOPMENT environment!"
	@echo "--------------------------------------------------------------------------------"

$(DEV_WEBUI_ENV_FILE):
	$(eval WG_URL := $(shell read -r -p $(WG_URL_MSG) && echo $$REPLY))
	$(eval NGINX_DOCKER_HOST_SUBNET := $(shell docker network inspect wireguard_default -f '{{(index .IPAM.Config 0).Subnet}}'))
	@cp $@.tpl $@
	@sed -i 's~172\.17\.0\.0/16~$(NGINX_DOCKER_HOST_SUBNET)~' $@
	@sed -i 's~$${nginx_host}~$(WG_URL)~' $@
	@sed -i 's~$${email}~test@email~' $@

$(DEV_WIREGUARD_ENV_FILE):
	$(eval WG_CLIENT_AMOUNT := $(shell read -r -p $(WG_CLIENT_AMOUNT_MSG) && echo $$REPLY))
	@echo
	@cp $@.tpl $@
	@sed -i 's~$${nginx_host}~$(WG_URL)~' $@
	@sed -i 's~$${wg_client_amount}~$(WG_CLIENT_AMOUNT)~' $@

$(DEV_ENV_FILE):
	@cp $@.tpl $@
	@sed -i 's~%NGINX_HOST%~$(WG_URL)~' $@

deploy-dev: .EXPORT_ALL_VARIABLES
	@echo "Deploy on your machine...."
	$(eval HOST_DATA_PATH := $(shell docker inspect $$HOSTNAME -f '{{json .HostConfig.Binds}}' | jq '.[] | select(. | contains("simple-vpn")) | split(":/simple-vpn")[0]'))
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/dev/docker-compose.yml run --rm openssl
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/wireguard/docker-compose.yml up -d wireguard
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/webui/docker-compose.yml run --rm webuiapp pip install -r requirements.txt
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/webui/docker-compose.yml -f docker/dev/dev-webui-docker-compose.yml up -d webuiapp
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/webui/docker-compose.yml -f docker/dev/dev-webui-docker-compose.yml up -d balancer
	@sleep 3
	curl -s -L -k --header 'Host: $(WG_URL)' https://host.docker.internal/install?force
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/webui/docker-compose.yml -f docker/dev/dev-webui-docker-compose.yml restart webuiapp
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/webui/docker-compose.yml -f docker/dev/dev-webui-docker-compose.yml restart balancer

.EXPORT_ALL_VARIABLES:

clean_dev:
	@rm -f $(DEV_WIREGUARD_ENV_FILE)
	@rm -f $(DEV_WEBUI_ENV_FILE)
	@rm -f $(DEV_ENV_FILE)
	@find  logs -type f ! -name ".gitkeep" | xargs rm -f
	@find  webui/data -type f ! -name ".gitkeep" | xargs rm -f

destroy-dev:
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/webui/docker-compose.yml down || true
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/wireguard/docker-compose.yml down || true

test: test-pylint

test-pylint:
	$(eval HOST_DATA_PATH := $(shell docker inspect $$HOSTNAME -f '{{json .HostConfig.Binds}}' | jq '.[] | select(. | contains("simple-vpn")) | split(":/simple-vpn")[0]'))
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/dev/docker-compose.yml run --rm tester

test-full: test-pylint-f test-eslint-f

test-pylint-f:
	$(eval HOST_DATA_PATH := $(shell docker inspect $$HOSTNAME -f '{{json .HostConfig.Binds}}' | jq '.[] | select(. | contains("simple-vpn")) | split(":/simple-vpn")[0]'))
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/dev/docker-compose.yml run --rm tester pylint webui

test-eslint-f:
	$(eval HOST_DATA_PATH := $(shell docker inspect $$HOSTNAME -f '{{json .HostConfig.Binds}}' | jq '.[] | select(. | contains("simple-vpn")) | split(":/simple-vpn")[0]'))
	@DATA_PATH=$(HOST_DATA_PATH) docker compose -p wireguard -f docker/dev/docker-compose.yml run --rm tester npx eslint -c test/eslint/.eslintrc.yml webui/static/js/*.js

install-auto-test: config_4 deploy-dev

config_4:
	$(eval WG_URL := wireguard.local)
	$(eval NGINX_DOCKER_HOST_SUBNET := $(shell docker network inspect wireguard_default -f '{{(index .IPAM.Config 0).Subnet}}'))
	ping -c 1 $WG_URL
	ping -c 1 host.docker.internal
	@cp $(DEV_WEBUI_ENV_FILE).tpl $(DEV_WEBUI_ENV_FILE)
	@sed -i 's~172\.17\.0\.0/16~$(NGINX_DOCKER_HOST_SUBNET)~' $(DEV_WEBUI_ENV_FILE)
	@sed -i 's~$${nginx_host}~$(WG_URL)~' $(DEV_WEBUI_ENV_FILE)
	@sed -i 's~$${email}~test@email~' $(DEV_WEBUI_ENV_FILE)
	@cp $(DEV_WIREGUARD_ENV_FILE).tpl $(DEV_WIREGUARD_ENV_FILE)
	@sed -i 's~$${nginx_host}~$(WG_URL)~' $(DEV_WIREGUARD_ENV_FILE)
	@sed -i 's~$${wg_client_amount}~5~' $(DEV_WIREGUARD_ENV_FILE)
	@cp $(DEV_ENV_FILE).tpl $(DEV_ENV_FILE)
	@sed -i 's~%NGINX_HOST%~$(WG_URL)~' $(DEV_ENV_FILE)
	
