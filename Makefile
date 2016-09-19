SUBDIRS = boot
SUBCLEAN = $(addsuffix .clean, $(SUBDIRS))

.PHONY: clean all $(SUBCLEAN) $(SUBDIRS)

all: $(SUBDIRS) 

clean: $(SUBCLEAN)

$(SUBDIRS):
	$(MAKE) -C $@ -f Makefile; \
	if [ $@ = 'boot' ]; then \
		$(MAKE) -C $@ -f Makefile BASENAME=boot-sio DISK_BASENAME=disk-sio ASFLAGS="--defsym SIO=1"; \
	fi

$(SUBCLEAN): %.clean: 
	$(MAKE) -C $* -f Makefile clean; \
	if [ $* = 'boot' ]; then \
		$(MAKE) -C $* -f Makefile BASENAME=boot-sio DISK_BASENAME=disk-sio ASFLAGS="--defsym SIO=1" clean; \
	fi

