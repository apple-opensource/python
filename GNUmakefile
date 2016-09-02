##---------------------------------------------------------------------
# GNUmakefile for python
# Call Makefile to do the work, but for the install case, unpack the
# tarball to create the project source directory
##---------------------------------------------------------------------
PROJECT = python
NAME = Python
VERSION = 2.3.3
NAMEVERS = $(NAME)-$(VERSION)
TARBALL = $(NAMEVERS).tar.bz2
FIX = $(OBJROOT)/fix

VERS = 2.3
FRAMEWORKS = /System/Library/Frameworks
PYFRAMEWORK = $(FRAMEWORKS)/Python.framework
VERSIONSVERS = $(PYFRAMEWORK)/Versions/$(VERS)
INCLUDEPYTHONVERS = $(VERSIONSVERS)/include/$(PROJECT)$(VERS)
LIBPYTHONVERS = $(VERSIONSVERS)/lib/$(PROJECT)$(VERS)

MAJORVERS = $(shell echo $(VERS) | sed 's/\..*//')
DYLIB = lib$(PROJECT)$(MAJORVERS).dylib
MAN1 = /usr/share/man/man1
USRINCLUDE = /usr/include
USRLIB = /usr/lib
EXTRAS = $(VERSIONSVERS)/Extras
LIBRARYPYTHON = /Library/Python/$(VERS)
APPENDFILE = AppendToPath
PREPENDFILE = PrependToPath

no_target:
	@$(MAKE) -f Makefile

##---------------------------------------------------------------------
# We patch configure to remove the "-arch_only ppc" option, since we
# build fat.  We also set DYLD_NEW_LOCAL_SHARED_REGIONS or else python.exe
# will crash.
# PR-3373087: in site.py, catch exception for HOME is not set
# (for received faxes)
#
# PR-3478215 - for backwards compatibility with non-framework python, we
# create symbolic links in /usr/include and /usr/lib, and move the dynamic
# lib to /usr/lib as well.  We then need to change the install names in
# all object files.
##---------------------------------------------------------------------
install:
	@if [ ! -d $(OBJROOT)/$(PROJECT) ]; then \
	    echo ditto $(SRCROOT) $(OBJROOT); \
	    ditto $(SRCROOT) $(OBJROOT); \
	    echo cd $(OBJROOT); \
	    cd $(OBJROOT); \
	    echo bzcat $(TARBALL) \| gnutar xf -; \
	    bzcat $(TARBALL) | gnutar xf -; \
	    echo rm -rf $(PROJECT); \
	    rm -rf $(PROJECT); \
	    echo mv $(NAMEVERS) $(PROJECT); \
	    mv $(NAMEVERS) $(PROJECT); \
	    echo Patching configure; \
	    ed - $(PROJECT)/configure < $(FIX)/configure.ed; \
	    echo patch $(PROJECT)/Lib/site.py $(FIX)/site.py.patch; \
	    patch $(PROJECT)/Lib/site.py $(FIX)/site.py.patch; \
	    echo patch $(PROJECT)/Modules/getpath.c $(FIX)/getpath.c.patch; \
	    patch $(PROJECT)/Modules/getpath.c $(FIX)/getpath.c.patch; \
	fi
	DYLD_NEW_LOCAL_SHARED_REGIONS=1 $(MAKE) -C $(OBJROOT) -f Makefile \
		install SRCROOT=$(OBJROOT) OBJROOT="$(OBJROOT)/$(PROJECT)" \
		PREPENDFILE=$(PREPENDFILE) APPENDFILE=$(APPENDFILE) \
		VERS=$(VERS)
	@obj= && \
	for i in `find $(DSTROOT) -type f -perm -0100 \! -name \*.so`; do \
	    if size $$i > /dev/null 2>&1 ; then \
		obj="$$obj $$i"; \
	    fi; \
	done && \
	for i in $$obj; do \
	    echo install_name_tool -change $(VERSIONSVERS)/Python $(USRLIB)/$(DYLIB) $$i && \
	    install_name_tool -change $(VERSIONSVERS)/Python $(USRLIB)/$(DYLIB) $$i; \
	done
	install -d $(DSTROOT)$(USRINCLUDE)
	ln -sf ../..$(INCLUDEPYTHONVERS) $(DSTROOT)$(USRINCLUDE)/$(PROJECT)$(VERS)
	install -d $(DSTROOT)$(USRLIB)
	ln -sf ../..$(LIBPYTHONVERS) $(DSTROOT)$(USRLIB)/$(PROJECT)$(VERS)
	mv -f $(DSTROOT)$(VERSIONSVERS)/Python $(DSTROOT)$(USRLIB)/$(DYLIB)
	ln -sf ../../../../../..$(USRLIB)/$(DYLIB) $(DSTROOT)$(VERSIONSVERS)/Python
	ln -sf $(DYLIB) $(DSTROOT)$(USRLIB)/lib$(PROJECT)$(VERS).dylib
	ln -sf $(DYLIB) $(DSTROOT)$(USRLIB)/lib$(PROJECT).dylib
	install_name_tool -id $(USRLIB)/$(DYLIB) $(DSTROOT)$(USRLIB)/$(DYLIB)
	install -d $(DSTROOT)$(LIBRARYPYTHON)
	echo '$(EXTRAS)' > $(DSTROOT)$(LIBRARYPYTHON)/$(PREPENDFILE)
	install -m 0644 $(FIX)/pydoc.1 $(DSTROOT)$(MAN1)
	install -m 0644 $(FIX)/pythonw.1 $(DSTROOT)$(MAN1)
	ln -sf python.1 $(DSTROOT)$(MAN1)/python2.3.1
	ln -sf pythonw.1 $(DSTROOT)$(MAN1)/pythonw2.3.1

.DEFAULT:
	@$(MAKE) -f Makefile $@
