default : test;
help :
	@echo Usage:
	@echo make run: run program
	@echo make test: compute diff from canonical result
	@echo make canonize: canonize test results

PROGNAME := utf8

FPC := fpc
FPC_OPTIONS := -O3 -Oodfa -Sew -g -gl -al -an -ar -at -vq -Xm -CX -XX -Xs

ifeq ($(OS),Windows_NT)
EXE_NAME := $(PROGNAME).exe
RUN_CMD := $(EXE_NAME)
clean :
	del *.map *.ppu *.o *.s *.out $(PROGNAME).exe
else
EXE_NAME := $(PROGNAME)
RUN_CMD := ./$(EXE_NAME)
clean :
	rm *.map *.ppu *.o *.s *.out $(PROGNAME)
endif

$(EXE_NAME) : ../../dutf8.pas utf8.pas
	$(FPC) $(FPC_OPTIONS) -FU. -Fu../.. utf8.pas
build : $(EXE_NAME);

run : build
	$(RUN_CMD)
test-quiet : build
	@$(RUN_CMD) >$(PROGNAME).out
	@diff $(PROGNAME).can $(PROGNAME).out
test : build
	@$(MAKE) -s --no-print-directory test-quiet && echo OK
canonize :
	cp $(PROGNAME).out $(PROGNAME).can
