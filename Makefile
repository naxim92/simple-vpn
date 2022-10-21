.PHONY: help build-utils
help:
	@echo "Use it for preparing environment, udpdating tools version, etc"
	@echo "To compile environment start build-utils"
build-utils:
	@echo "Start preparing the environment..."
	docker build -f ./Dockerfile-utils -t naxim/vpn_utils --force-rm  ./docker