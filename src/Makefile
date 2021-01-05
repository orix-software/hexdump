#
# Spécifique au Projet
#

PROJECT ?= hexdump
BUILD_PATH = ../build
OBJ_PATH = $(BUILD_PATH)/obj
BIN_PATH = $(BUILD_PATH)/bin
# LD65_CFG = ../cfg/orix.cfg

KERNEL_PATH = ../../orix-software/
SHELL_PATH = ../../orix-software/
SDK_PATH = ../../orix-sdk/

LIB_PATH = $(SDK_PATH)/build/lib
LIBS = orix-sdk.lib

VERSION ?= "0.01"
VERBOSE ?= 0

# %<-------------------------------------------------------------------------->%
#               Ne rien modifier au dela de cette ligne
#

#
# Définition des outils
#

ifeq ($(CC65_HOME),)
	CC = cc65
	AS = ca65
	LD = ld65
	AR = ar65
else
	CC = $(CC65_HOME)/bin/cc65
	AS = $(CC65_HOME)/bin/ca65
	LD = $(CC65_HOME)/bin/ld65
	AR = $(CC65_HOME)/bin/ar65
endif

#
# Définition des options pour les outils
#

ifeq ($(DEBUG),yes)
	ASFLAGS = -t telestrat -I $(BUILD_PATH) -I $(SDK_PATH) -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) --list-bytes 0 -l $(OBJ_PATH)/$(PROJECT).lst --debug-info
	LDFLAGS = -t telestrat  -Ln $(BIN_PATH)/$(PROJECT).ca.sym -m $(BIN_PATH)/$(PROJECT).map --lib-path $(LIB_PATH)
	# LDFLAGS = -C "$(LD65_CFG)"  -Ln $(BUILD_PATH)/$(PROJECT).ca.sym -m $(BUILD_PATH)/$(PROJECT).map --lib-path $(LIB_PATH)
else
	ASFLAGS = -t telestrat -I $(BUILD_PATH) -I $(SDK_PATH) -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE)
	LDFLAGS = -t telestrat  --lib-path $(LIB_PATH)
	# LDFLAGS = -C "$(LD65_CFG)"  --lib-path $(LIB_PATH)
endif


#
# Cibles make
#

.PHONY: clean mrproper

all: $(BUILD_PATH) $(OBJ_PATH) $(BIN_PATH) $(BIN_PATH)/$(PROJECT)

configure: $(OBJ_PATH) $(BIN_PATH)

clean:
	cd $(OBJ_PATH) && rm -f *.o *.lst


mrproper: clean
	@#cd $(BIN_PATH) && rm -f $(PROJECT) *.sym *.map
	rm -rf $(BIN_PATH)
	rm -rf $(OBJ_PATH)


#
# Règles Make
#


SRC = $(wildcard *.s)
OBJS= $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC)))


#%.o: %.s
$(OBJ_PATH)/%.o: %.s
	@echo "Assemble $<"
	@$(AS) $(ASFLAGS) -o $@ $<


$(BIN_PATH)/$(PROJECT): $(OBJS) $(LIB_PATH)/$(LIBS)
	@echo "Create $(PROJECT)"
	@$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)
ifeq ($(DEBUG),yes)
	@echo "Create $(PROJECT).sym"
	@sed -re 's/al 00(.{4}) \.(.+)$$/\1 \2/' $(BIN_PATH)/$(PROJECT).ca.sym | sort > $(BIN_PATH)/$(PROJECT).sym
endif

$(OBJ_PATH):
	@echo "Create $(OBJ_PATH) directory"
	@mkdir -p $(OBJ_PATH)

$(BIN_PATH):
	@echo "Create $(BIN_PATH) directory"
	@mkdir -p $(BIN_PATH)

$(BUILD_PATH):
	@echo "Create $(BUILD_PATH) directory"
	@mkdir -p $(BUILD_PATH)

