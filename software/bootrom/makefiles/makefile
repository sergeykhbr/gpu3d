include util.mak

TOP_DIR=../
OBJ_DIR = $(TOP_DIR)obj
ELF_DIR = $(TOP_DIR)bin


#-----------------------------------------------------------------------------
.SILENT:
  TEA = 2>&1 | tee _$@-comp.err

all: bootrom
	$(ECHO) "    All done.\n"

bootrom:
	$(ECHO) "    Bootrom tests image building started:"
	$(MKDIR) ./$(OBJ_DIR)
	$(MKDIR) ./$(ELF_DIR)
	make -f make_bootrom TOP_DIR=$(TOP_DIR) OBJ_DIR=$(OBJ_DIR) ELF_DIR=$(ELF_DIR) $@ $(TEA)
