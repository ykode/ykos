SUBDIRS = boot
SUBCLEAN = $(addsuffix .clean, $(SUBDIRS))

.PHONY: clean all $(SUBCLEAN) $(SUBDIRS)

all: $(SUBDIRS) 

clean: $(SUBCLEAN)

$(SUBDIRS):
	$(MAKE) -C $@ -f Makefile

$(SUBCLEAN): %.clean: 
	$(MAKE) -C $* -f Makefile clean


