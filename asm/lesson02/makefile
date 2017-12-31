
LINK = ilink32.exe
ASM  = tasm32.exe
NAME = lesson2
OBJS = $(NAME).obj
DEF  = $(NAME).def

TASMDEBUG= /zi
LINKDEBUG= /v

IMPORT=import32


$(NAME).EXE: $(OBJS) $(DEF)
	$(LINK) /Tpe /aa /c $(LINKDEBUG) $(OBJS),$(NAME),, $(IMPORT), $(DEF)

$(NAME).obj:$(NAME).asm
	$(ASM) $(TASMDEBUG) /m9 /ml $(NAME).asm
clean	:
	rm $(NAME).i??
	rm $(NAME).tds
	rm $(NAME).map
	rm $(NAME).OBJ
	rm $(NAME).exe
