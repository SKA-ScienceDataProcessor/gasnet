GASNET_VERSION = GASNet-1.26.0

ifeq ($(ICTYPE)x,x)
ifeq ($(findstring daint,$(shell uname -n)),daint)
ICTYPE = aries
CROSS_CONFIGURE = cross-configure-crayxc-linux
else
ifeq ($(findstring titan,$(shell uname -n)),titan)
ICTYPE = gemini
CROSS_CONFIGURE = cross-configure-crayxe-linux
else
ICTYPE = default
endif
endif
endif

RELEASE_CONFIG = configs/config.$(ICTYPE).release

.PHONY: release

release : release/config.status
	make -C release install

release/config.status : $(RELEASE_CONFIG) $(GASNET_VERSION)/configure
ifdef CROSS_CONFIGURE
# Cray systems require cross-compiling fun
	mkdir -p release
	# WAH for issue with new Cray cc/CC not including PMI stuff
	echo '#!/bin/bash' > release/cc.custom
	echo 'cc "$$@" $$CRAY_UGNI_POST_LINK_OPTS $$CRAY_PMI_POST_LINK_OPTS -Wl,--as-needed,-lugni,-lpmi,--no-as-needed' >> release/cc.custom
	chmod a+x release/cc.custom
	echo '#!/bin/bash' > release/CC.custom
	echo 'CC "$$@" $$CRAY_UGNI_POST_LINK_OPTS $$CRAY_PMI_POST_LINK_OPTS -Wl,--as-needed,-lugni,-lpmi,--no-as-needed' >> release/CC.custom
	chmod a+x release/CC.custom
	# use our custom cc/CC wrappers and also force -fPIC
	/bin/sed "s/'\(cc\)'/'\1.custom -fPIC'/I" < $(GASNET_VERSION)/other/contrib/$(CROSS_CONFIGURE) > $(GASNET_VERSION)/cross-configure
	cd release; PATH=`pwd`:$$PATH /bin/sh ../$(GASNET_VERSION)/cross-configure --prefix=`pwd` `cat $(realpath $(RELEASE_CONFIG))`
else
# normal configure path
	mkdir -p release
	cd release; MPI_CC=mpicc MPI_CFLAGS=-fPIC CC='mpicc -fPIC' CXX='mpicxx -fPIC' ../$(GASNET_VERSION)/configure --prefix=`pwd` `cat $(realpath $(RELEASE_CONFIG))`
endif

$(GASNET_VERSION)/configure : $(GASNET_VERSION).tar.gz
	tar -zxf $<
	touch -c $@
