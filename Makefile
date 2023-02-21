SHELL := /bin/bash

TF_DIR := "terraform"
TFVARS_FILE :=  $(TF_DIR)/terraform.tfvars

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

.PHONY: help config config_1 config_2 build-utils install deploy-prod deploy-public-ip deploy-service clean clean_all
help:
	@echo "Use it for deploy, preparing environments, udpdating tools version, etc"
	@echo "To deploy on prod start install"
	@echo "[Not finished] To compile environment start build-utils"

build-utils:
	@echo "[Not finished] Start preparing the environment..."
	docker build -f ./Dockerfile-utils -t naxim/vpn_utils --force-rm  ./docker

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

config: config_1 terraform/terraform.tfvars config_2

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
	@cp $@.sample $@
	@sed -i 's/%GCLOUD_FILE%/$(GCLOUD_FILE)/' $@
	@sed -i 's/%GCLOUD_PROJECT%/$(GCLOUD_PROJECT)/' $@
	@sed -i 's/%PUB_KEY_FILE%/$(PUB_KEY_FILE)/' $@
	@sed -i 's/%PRIVATE_KEY_FILE%/$(PRIVATE_KEY_FILE)/' $@
	@sed -i 's/%LETSENCRYPT_EMAIL%/$(LETSENCRYPT_EMAIL)/' $@
	@sed -i 's/%WG_URL%/$(WG_URL)/' $@
	@sed -i 's/%WG_CLIENT_AMOUNT%/$(WG_CLIENT_AMOUNT)/' $@

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

