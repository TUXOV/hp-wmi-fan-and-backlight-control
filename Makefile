
# Module name
obj-m += hp-wmi.o

# Kernel build directory
KDIR := /lib/modules/$(shell uname -r)/build

# Current directory
PWD := $(shell pwd)

# Get package info from dkms.conf
DKMS_CONF := $(PWD)/dkms.conf
PKGNAME := $(shell grep -oP 'PACKAGE_NAME="\K[^"]+' $(DKMS_CONF) 2>/dev/null)
VERSION := $(shell grep -oP 'PACKAGE_VERSION="\K[^"]+' $(DKMS_CONF) 2>/dev/null)

# akmod/kmod packaging
AKMOD_TOPDIR := $(PWD)/akmod-build
AKMOD_SPEC := $(PWD)/hp-wmi-fan-and-backlight-control-kmod.spec

# Default target
all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

# Clean target
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	rm -rf *.pkg.tar.zst akmod-build

install: all
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install
	depmod -a

install-dkms:
	dkms add .
	dkms build -m $(PKGNAME) -v $(VERSION)
	dkms install -m $(PKGNAME) -v $(VERSION)

install-arch:
	makepkg -si

# Build the akmod RPM. Installing it registers the module with akmods, which
# builds it for the running kernel and rebuilds it for future kernels.
akmod:
	rm -rf $(AKMOD_TOPDIR)
	mkdir -p $(AKMOD_TOPDIR)/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
	rpmbuild -bb \
		--define "_topdir $(AKMOD_TOPDIR)" \
		--define "_sourcedir $(PWD)" \
		--define "_specdir $(PWD)" \
		$(AKMOD_SPEC)
	@echo
	@echo "Install the akmod package with:"
	@echo "  sudo dnf install $(AKMOD_TOPDIR)/RPMS/*/*.rpm"
	@echo
	@echo "(The akmod RPM depends on the common package in the same directory,"
	@echo " so install all of them in one transaction.)"

# Build only the source RPM used by akmods.
akmod-srpm:
	mkdir -p $(AKMOD_TOPDIR)/SRPMS
	rpmbuild -bs \
		--define "_topdir $(AKMOD_TOPDIR)" \
		--define "_sourcedir $(PWD)" \
		--define "_specdir $(PWD)" \
		$(AKMOD_SPEC)
	@echo "SRPM written to $(AKMOD_TOPDIR)/SRPMS"

uninstall:
	rm -f /lib/modules/$(shell uname -r)/extra/hp-wmi.ko
	depmod -a

uninstall-dkms:
	dkms remove -m $(PKGNAME) -v $(VERSION) --all
	rm -rf /usr/src/$(PKGNAME)-$(VERSION)

uninstall-akmod:
	-dnf remove -y 'akmod-hp-wmi*' 'kmod-hp-wmi*' hp-wmi-fan-and-backlight-control-kmod

.PHONY: all clean install install-dkms install-arch akmod akmod-srpm \
	uninstall uninstall-dkms uninstall-akmod