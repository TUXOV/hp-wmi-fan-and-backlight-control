%global debug_package %{nil}
%global buildforkernels akmod

%global prjname hp-wmi
%global pkgname hp-wmi-fan-and-backlight-control
%global pkgver %(grep -oP 'PACKAGE_VERSION="\K[^"]+' %{_sourcedir}/dkms.conf 2>/dev/null || echo 0.0.4)

Name:           %{pkgname}-kmod
Summary:        Kernel module for HP laptop fan and keyboard backlight control
Version:        %{pkgver}
Release:        1%{?dist}
License:        GPL-2.0-or-later
URL:            https://github.com/TUXOV/hp-wmi-fan-and-backlight-control
Source0:        hp-wmi.c
Source1:        Makefile
Source2:        LICENSE
Source3:        README.md
Source4:        dkms.conf

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  elfutils-libelf-devel
BuildRequires:  kmodtool

# The generated packages require this common package. The main package
# provides it, which avoids needing a separate base package.
Provides:       hp-wmi-kmod-common = %{?epoch:%{epoch}:}%{version}-%{release}

# kmodtool generates the akmod/kmod subpackages and the per-kernel build
# variables. It is expanded here so that the generated package definitions are
# part of this spec.
%{expand:%(kmodtool --target %{_target_cpu} --kmodname %{prjname} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"} 2>/dev/null)}

%description
This package contains the common files for the hp-wmi kernel module, which
adds manual fan control and zoned keyboard RGB backlight control for HP
Omen/Victus laptops.

The actual kernel modules are provided by the akmod/kmod subpackages.

%prep
%{?kmodtool_check}

# Print the kmodtool output for debugging purposes.
kmodtool --target %{_target_cpu} --kmodname %{prjname} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"} 2>/dev/null

cp %{SOURCE2} %{SOURCE3} .

for kernel_version in %{?kernel_versions}; do
    mkdir -p _kmod_build_${kernel_version%%___*}
    cp %{SOURCE0} %{SOURCE1} _kmod_build_${kernel_version%%___*}/
done

%build
for kernel_version in %{?kernel_versions}; do
    make V=1 %{?_smp_mflags} -C ${kernel_version##*___} \
        M=${PWD}/_kmod_build_${kernel_version%%___*} modules
done

%install
for kernel_version in %{?kernel_versions}; do
    mkdir -p %{buildroot}%{kmodinstdir_prefix}/${kernel_version%%___*}/%{kmodinstdir_postfix}
    install -D -m 755 _kmod_build_${kernel_version%%___*}/hp-wmi.ko \
        %{buildroot}%{kmodinstdir_prefix}/${kernel_version%%___*}/%{kmodinstdir_postfix}/hp-wmi.ko
done

%{?akmod_install}

%files
%license LICENSE
%doc README.md

%changelog
* Wed Oct 21 2026 Edip Hazuri <edip@medip.dev> - 0.0.4-1
- Initial akmod/kmod package
