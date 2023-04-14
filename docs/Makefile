#
# Spécifique au Projet
#

PROJECT ?= hexdump
BUILD_PATH = ../build

MAN_PATH = $(BUILD_PATH)/usr/share/man
MD2HLP_PATH = ../../md2hlp/src/

VERBOSE ?= 0

# %<-------------------------------------------------------------------------->%
#               Ne rien modifier au dela de cette ligne
#

#
# Définition des outils
#

MD2HLP = $(MD2HLP_PATH)/md2hlp.py3

#
# Définition des options pour les outils
#

ifeq ($(VERBOSE),1)
	MD2HLPFLAGS = -v
else
	ifeq ($(VERBOSE),2)
		MD2HLPFLAGS = -vv
	endif
endif


#
# Cibles make
#

.PHONY: clean mrproper

all: $(MAN_PATH) $(MAN_PATH)/$(PROJECT).hlp

configure: $(MAN_PATH)

clean:
	cd $(MAN_PATH) && rm -f *.hlp


mrproper: clean
	@# cd $(MAN_PATH) && rm -f $(PROJECT).hlp
	rm -rf $(MAN_PATH)


#
# Règles Make
#


SRC = $(PROJECT).md
OBJS= $(addprefix $(MAN_PATH)/, $(patsubst %.md,%.hlp, $(SRC)))


#%.hlp: %.md
$(MAN_PATH)/%.hlp: %.md
	@echo "Create $(PROJECT).hlp"
	@python $(MD2HLP) $(MD2HLPFLAGS) -o $@ -f $<


$(MAN_PATH)/$(PROJECT).hlp: $(PROJECT).md

$(MAN_PATH):
	@echo "Create $(BUILD_PATH) directory"
	@mkdir -p $(BUILD_PATH)
	@echo "Create $(MAN_PATH) directory"
	@mkdir -p $(MAN_PATH)

