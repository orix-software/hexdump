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

START_ADDR ?= 0x0900

VERSION ?= "0.01"
VERBOSE ?= 0

# %<-------------------------------------------------------------------------->%
#               Ne rien modifier au dela de cette ligne
#
TARGET = telestrat

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
	ASFLAGS = -t $(TARGET) -I ../ -I . -I $(SDK_PATH)/macros -I $(SDK_PATH)/include -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) --auto-import --list-bytes 0 -l $(@:.o=.lst) --debug-info
	LDFLAGS = -t $(TARGET)  -Ln $(@).ca.sym -m $(@).map --lib-path $(LIB_PATH) --start-addr $(START_ADDR)
	# LDFLAGS = -C "$(LD65_CFG)"  -Ln $(BUILD_PATH)/$(PROJECT).ca.sym -m $(BUILD_PATH)/$(PROJECT).map --lib-path $(LIB_PATH)
else
	ASFLAGS = -t $(TARGET) -I ../ -I . -I $(SDK_PATH)/macros -I $(SDK_PATH)/include -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) --auto-import
	LDFLAGS = -t $(TARGET)  --lib-path $(LIB_PATH) --start-addr $(START_ADDR)
	# LDFLAGS = -C "$(LD65_CFG)"  --lib-path $(LIB_PATH)
endif

CREATE_DEP = --create-dep $(@:.o=.d)

#
# Cibles make
#

.PHONY: clean mrproper


all: $(BUILD_PATH) $(OBJ_PATH) $(BIN_PATH) $(BIN_PATH)/$(PROJECT)


configure: $(OBJ_PATH) $(BIN_PATH)


clean:
	@cd $(OBJ_PATH) && rm -f *.o *.lst *.d
	@cd $(BIN_PATH) && rm -f *.sym *.map


mrproper: clean
	@rm -rf $(BIN_PATH)
	@rm -rf $(OBJ_PATH)


#
# Règles Make
#


SRC = $(wildcard *.s)
OBJS= $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC)))
DEPS := $(OBJS:.o=.d)

#%.o: %.s
$(OBJ_PATH)/%.o: %.s
	@echo "Assemble $<"
	@$(AS) $(ASFLAGS) $(CREATE_DEP) -o $@ $<


$(BIN_PATH)/$(PROJECT): $(OBJS) $(LIB_PATH)/$(LIBS)
	@echo "Create $(PROJECT) (start address = $(START_ADDR))"
	@$(LD) $(LDFLAGS) -o $@ $^ $(LIBS) $(TARGET).lib
ifeq ($(DEBUG),yes)
	@echo "Create $(PROJECT).sym"
	@sed -re 's/al 00(.{4}) \.(.+)$$/\1 \2/' $(BIN_PATH)/$(PROJECT).ca.sym | sort | uniq > $(BIN_PATH)/$(PROJECT).sym
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

-include $(DEPS)
