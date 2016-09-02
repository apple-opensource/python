##
# Makefile for python
##

Project               = python
Extra_Configure_Flags = --enable-ipv6 --with-threads --enable-framework=$(DSTROOT)/System/Library/Frameworks --enable-toolbox-glue --srcdir=$(Sources)
# Extra_CC_Flags and Extra_LD_Flags are needed because CFLAGS gets overridden
# by the RC_* variables.  These values would normally be set by the default
# python Makefile
Extra_CC_Flags += -fno-common -Wno-long-double
Extra_LD_Flags += -Wl,-F.
Extra_Install_Flags   = DESTDIR=${DSTROOT} MANDIR=${DSTROOT}/usr/share/man
GnuAfterInstall       = fixup-after-install

# It's a GNU Source project
include $(MAKEFILEPATH)/CoreOS/ReleaseControl/GNUSource.make

Install_Flags := $(shell echo $(Install_Flags) | sed 's/prefix=[^ ]* *//')
Install_Target = frameworkinstall
SRCDIR = $(OBJROOT)/Sources
Sources = $(SRCDIR)/$(Project)
FIX = $(SRCDIR)/fix

##---------------------------------------------------------------------
# Create copy and build there.  Also patch configure to allow fat binaries.
##---------------------------------------------------------------------
lazy_install_source:: copy-source-to-objroot

copy-source-to-objroot:
	ditto $(SRCROOT) $(SRCDIR)
	ed - $(Sources)/configure < $(FIX)/configure.ed

##---------------------------------------------------------------------
# Patch the Makefile just after running configure
##---------------------------------------------------------------------
ConfigStamp2 = $(ConfigStamp)2

configure:: $(ConfigStamp2)

$(ConfigStamp2): $(ConfigStamp)
	$(_v) ed - ${OBJROOT}/Makefile < $(FIX)/Makefile.ed
	$(_v) $(TOUCH) $(ConfigStamp2)

##---------------------------------------------------------------------
# Fixup a lot of problems after the install
##---------------------------------------------------------------------
VERS = 2.3
BUILD = $(OBJROOT)/build
APPS = /Applications
DEVAPPS = /Developer/Applications
USRBIN = /usr/bin
BUILDAPPLETNAME = BuildApplet.app
PYTHONAPPNAME = Python.app
PYTHONLAUNCHERNAME = PythonLauncher.app
FRAMEWORKS = /System/Library/Frameworks
PYFRAMEWORK = $(FRAMEWORKS)/Python.framework
VERSIONSVER = $(PYFRAMEWORK)/Versions/$(VERS)
RESOURCESVERS = $(VERSIONSVER)/Resources
ENGLISHLPROJVERS = $(RESOURCESVERS)/English.lproj
LIBPYTHONVERS = $(VERSIONSVER)/lib/python$(VERS)
PYTHONAPP = $(RESOURCESVERS)/$(PYTHONAPPNAME)
PACONTENTS = $(PYTHONAPP)/Contents
PAMACOS = $(PACONTENTS)/MacOS
PARESOURCES = $(PACONTENTS)/Resources
PAENGLISHLPROJ = $(PARESOURCES)/English.lproj
MACPYTHON = $(APPS)/MacPython-$(VERS)
DEVMACPYTHON = $(DEVAPPS)/MacPython-$(VERS)
PYTHONLAUNCHER = $(MACPYTHON)/$(PYTHONLAUNCHERNAME)
PLCONTENTS = $(PYTHONLAUNCHER)/Contents
PLRESOURCES = $(PLCONTENTS)/Resources
PLENGLISHLPROJ = $(PLRESOURCES)/English.lproj
BUILDAPPLET = $(DEVMACPYTHON)/$(BUILDAPPLETNAME)
BACONTENTS = $(BUILDAPPLET)/Contents
BAMACOS = $(BACONTENTS)/MacOS
RUNPYTHON = DYLD_FRAMEWORK_PATH=$(OBJROOT) $(OBJROOT)/python.exe
BYTE2UTF16 = $(RUNPYTHON) $(FIX)/byte2utf16.py
UTF162BYTE = $(RUNPYTHON) $(FIX)/utf162byte.py

fixup-after-install: delete-stuff \
		     move-things-around \
		     strip-installed-files \
		     make-utf16 \
		     remove-bogus-file \
		     fix-empty-file \
		     fix-inappropriate-executables \
		     fix-BAInfo \
		     fix-PythonApp \
		     fix-CFBundleShortVersionString \
		     fix-CFBundleName \
		     fix-paths \
		     fix-buildapplet \
		     make-usr-bin \
		     make-Library-Python \
		     fix-permissions

delete-stuff:
	rm -rf $(DSTROOT)/System/usr

move-things-around:
	mv -f $(DSTROOT)/System/$(APPS) $(DSTROOT)$(APPS)
	install -d $(DSTROOT)$(DEVMACPYTHON)
	mv -f $(DSTROOT)$(MACPYTHON)/$(BUILDAPPLETNAME) $(DSTROOT)$(BUILDAPPLET)

strip-installed-files:
	strip -x $(DSTROOT)$(VERSIONSVER)/Python
	strip -x $(DSTROOT)$(VERSIONSVER)/bin/python*
	strip -x $(DSTROOT)$(LIBPYTHONVERS)/config/python.o
	strip -x $(DSTROOT)$(LIBPYTHONVERS)/lib-dynload/*.so

make-utf16:
	for i in $(DSTROOT)$(ENGLISHLPROJVERS) $(DSTROOT)$(PAENGLISHLPROJ); do \
	    mv $$i/InfoPlist.strings $$i/temp-ip.strings; \
	    $(BYTE2UTF16) $$i/temp-ip.strings $$i/InfoPlist.strings; \
	    rm -f $$i/temp-ip.strings; \
	done

remove-bogus-file:
	rm -rf $(DSTROOT)$(LIBPYTHONVERS)/test/testtar.tar

fix-empty-file:
	echo '#' > $(DSTROOT)$(LIBPYTHONVERS)/bsddb/test/__init__.py

fix-inappropriate-executables:
	find $(DSTROOT)$(PLENGLISHLPROJ) -type f -exec chmod a-x {} \;

fix-BAInfo:
	ed - $(DSTROOT)$(BACONTENTS)/Info.plist < $(FIX)/bainfo.ed

fix-PythonApp:
	mv -f $(DSTROOT)$(PAMACOS)/python $(DSTROOT)$(PAMACOS)/X; \
	    mv -f $(DSTROOT)$(PAMACOS)/X $(DSTROOT)$(PAMACOS)/Python
	ed - $(DSTROOT)$(PACONTENTS)/Info.plist < $(FIX)/painfo.ed

fix-CFBundleShortVersionString:
	$(UTF162BYTE) $(DSTROOT)$(PLENGLISHLPROJ)/InfoPlist.strings $(DSTROOT)$(PLENGLISHLPROJ)/temp.ip.strings
	ed - $(DSTROOT)$(PLENGLISHLPROJ)/temp.ip.strings < $(FIX)/plsvs.ed
	$(BYTE2UTF16) $(DSTROOT)$(PLENGLISHLPROJ)/temp.ip.strings $(DSTROOT)$(PLENGLISHLPROJ)/InfoPlist.strings
	rm -f $(DSTROOT)$(PLENGLISHLPROJ)/temp.ip.strings
	$(UTF162BYTE) $(DSTROOT)$(ENGLISHLPROJVERS)/InfoPlist.strings $(DSTROOT)$(ENGLISHLPROJVERS)/temp.ip.strings
	ed - $(DSTROOT)$(ENGLISHLPROJVERS)/temp.ip.strings < $(FIX)/2.3svs.ed
	$(BYTE2UTF16) $(DSTROOT)$(ENGLISHLPROJVERS)/temp.ip.strings $(DSTROOT)$(ENGLISHLPROJVERS)/InfoPlist.strings
	rm -f $(DSTROOT)$(ENGLISHLPROJVERS)/temp.ip.strings
	$(UTF162BYTE) $(DSTROOT)$(PAENGLISHLPROJ)/InfoPlist.strings $(DSTROOT)$(PAENGLISHLPROJ)/temp.ip.strings
	ed - $(DSTROOT)$(PAENGLISHLPROJ)/temp.ip.strings < $(FIX)/pasvs.ed
	$(BYTE2UTF16) $(DSTROOT)$(PAENGLISHLPROJ)/temp.ip.strings $(DSTROOT)$(PAENGLISHLPROJ)/InfoPlist.strings
	rm -f $(DSTROOT)$(PAENGLISHLPROJ)/temp.ip.strings

fix-CFBundleName:
	ed - $(DSTROOT)$(PLCONTENTS)/Info.plist < $(FIX)/plbn.ed

##---------------------------------------------------------------------
# adjustSLF.ed removes DSTROOT, leaving /System/Library/Frameworks.  It
# also removes -arch xxx flags.
##---------------------------------------------------------------------
fix-paths:
	ed - $(DSTROOT)$(LIBPYTHONVERS)/config/Makefile < $(FIX)/adjustSLF.ed
	ed - $(DSTROOT)$(PYDOCORIG) < $(FIX)/fixusrbin.ed

fix-buildapplet:
	ed - $(DSTROOT)$(BAMACOS)/BuildApplet < $(FIX)/buildapplet.ed
	rm -f $(DSTROOT)$(BAMACOS)/python
	ln -sf ../../../../../../System/Library/Frameworks/Python.framework/Versions/2.3/Resources/Python.app/Contents/MacOS/Python $(DSTROOT)$(BAMACOS)/python

PYDOC = $(USRBIN)/pydoc
PYDOCORIG = $(PYFRAMEWORK)/Versions/$(VERS)/bin/pydoc

make-usr-bin:
	install -d $(DSTROOT)$(USRBIN)
	ln -sf python$(VERS) $(DSTROOT)$(USRBIN)/python
	ln -sf ../../System/Library/Frameworks/Python.framework/Versions/$(VERS)/bin/python $(DSTROOT)$(USRBIN)/python$(VERS)
	ln -sf pythonw$(VERS) $(DSTROOT)$(USRBIN)/pythonw
	install -p $(FIX)/pythonw$(VERS) $(DSTROOT)$(USRBIN)
	install -p $(DSTROOT)$(PYDOCORIG) $(DSTROOT)$(PYDOC)

LIBRARYPYTHON = /Library/Python
LIBRARYPYTHONVERS = $(LIBRARYPYTHON)/$(VERS)
SITEPACKAGES = $(LIBPYTHONVERS)/site-packages

make-Library-Python:
	install -d $(DSTROOT)$(LIBRARYPYTHON)
	mv -f $(DSTROOT)$(SITEPACKAGES) $(DSTROOT)$(LIBRARYPYTHONVERS)
	ln -sf ../../../../../../../..$(LIBRARYPYTHONVERS) $(DSTROOT)$(SITEPACKAGES)

fix-permissions:
	for i in Applications Developer Library; do \
	    chgrp -Rf admin $(DSTROOT)/$$i; \
	    chmod -Rf g+w $(DSTROOT)/$$i; \
	done
