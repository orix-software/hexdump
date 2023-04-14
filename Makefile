export PROJECT := $(notdir $(shell pwd))

all: project docs


.PHONY: configure docs clean mrproper

configure:
	@$(MAKE) -C src $@
	@$(MAKE) -C docs $@

project:
	@echo -e "\nMake project $(PROJECT)\n"
	@$(MAKE) -C src

docs:
	@echo -e "\nMake project $(PROJECT) man page\n"
	@$(MAKE) -C docs

clean:
	@$(MAKE) -C src $@
	@$(MAKE) -C docs $@


mrproper:
	@$(MAKE) -C src $@
	@$(MAKE) -C docs $@

