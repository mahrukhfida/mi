# Note that this is NOT a relocatable package
# packaging/rpm/SPECS/wireshark.spec.  Generated from wireshark.spec.in by configure.
# configure options: --disable-wireshark

%bcond_with	qt
%bcond_without	qt5
%bcond_without	gtk2
%bcond_with	gtk3
%bcond_with	lua

# Set these to 1 if you want to ensure your package includes support for them:
%global with_adns 0
%global with_c_ares 1
%global with_portaudio 0

# Set at most one of these two:
# Note that setcap requires rpmbuild 4.7.0 or later.
%global setuid_dumpcap 0
%global setcap_dumpcap 1

# Set to 1 if you want a group called 'wireshark' which users must be a member
# of in order to run dumpcap.  Only used if setuid_dumpcap or setcap_dumpcap
# are set.
%global use_wireshark_group 1


Summary:	Wireshark is the world's foremost protocol analyzer
Name:		wireshark
Version:	2.0.13
Release:	1
License:	GPLv2+
Group:		Applications/Internet
Source:		https://wireshark.org/download/src/%{name}-%{version}.tar.bz2
# Or this URL for automated builds:
#Source:	https://wireshark.org/download/automated/src/%{name}-%{version}.tar.bz2
URL:		https://www.wireshark.org/
Packager:	Gerald Combs <gerald[AT]wireshark.org>
# Some distributions create a wireshark-devel package; get rid of it
Obsoletes:	wireshark-devel

BuildRoot:	/tmp/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:	autoconf >= 2.60
BuildRequires:	automake
BuildRequires:	libtool
BuildRequires:	gcc
BuildRequires:	flex
BuildRequires:	bison
BuildRequires:	python
BuildRequires:	perl

BuildRequires:	glib2-devel >= 2.16.0
Requires:	glib2 >= 2.16.0
BuildRequires:	libpcap-devel
Requires:	libpcap
BuildRequires:	zlib-devel
Requires:	zlib

%if %{with_c_ares}
%if 0%{?suse_version}
# SuSE uses these package names (yes 2!):
BuildRequires:	libcares-devel
Requires:	libcares2
%else
# ... while Red Hat uses this one:
# (What other RPM-based distros do will have to be determined...)
BuildRequires:	c-ares-devel
Requires:	c-ares
%endif
%endif
%if %{with_adns}
BuildRequires:	adns-devel
Requires:	adns
%endif
%if %{with lua}
BuildRequires:	lua-devel < 5.3
Requires:	lua < 5.3
%endif

# Uncomment these if you want to be sure you get them...
#BuildRequires:	krb5-devel
#BuildRequires:	libsmi-devel
#BuildRequires:	pcre-devel
#BuildRequires:	libselinux
#BuildRequires:	gnutls-devel
#BuildRequires:	libcap-devel

%if %{use_wireshark_group}
%if 0%{?suse_version}
# SuSE's groupadd is in this package:
Requires(pre):	pwdutils
%else
# ... while Red Hat's is in this one:
Requires(pre):	shadow-utils
%endif
%endif

%if %{setcap_dumpcap}
# Actually we require rpmbuild (the program) >= 4.7.0 but the package name
# where we can find it varies.  So we check the 'rpm' version because either
# rpmbuild is in that package (e.g., in older distros) or it's in the
# 'rpm-build' package which generally requires a matching version of 'rpm'.
#
# All of this is to save users the trouble of getting through an full compile
# only to have rpmbuild barf because it doesn't understand capabilities.
BuildRequires:	rpm >= 4.7.0
%endif

# NOTE: the below description has been copied to wireshark.appdata.xml (in the
# top-level directory).
%description
Wireshark allows you to examine protocol data stored in files or as it is
captured from wired or wireless (WiFi or Bluetooth) networks, USB devices,
and many other sources.  It supports dozens of protocol capture file formats
and understands more than a thousand protocols.

It has many powerful features including a rich display filter language
and the ability to reassemble multiple protocol packets in order to, for
example, view a complete TCP stream, save the contents of a file which was
transferred over HTTP or CIFS, or play back an RTP audio stream.

This package contains command-line utilities, plugins, and documentation for
Wireshark. A Qt and a GTK+ graphical user interface are packaged separately.

%if %{with qt} || %{with qt5}
%package	qt
Summary:	Wireshark's Qt-based GUI
Group:		Applications/Internet
%if %{with qt5}
%if 0%{?suse_version}
Requires: libQt5Core5
Requires: libQt5Gui5
Requires: libQt5Widgets5
Requires: libQt5PrintSupport5
Requires: libQt5Multimedia5
BuildRequires: libQt5Core-devel
BuildRequires: libQt5Gui-devel
BuildRequires: libQt5Widgets-devel
BuildRequires: libQt5PrintSupport-devel
BuildRequires: libqt5-qtmultimedia-devel
%else
Requires:	qt5-qtbase
Requires:	qt5-qtbase-gui
Requires:	qt5-qtmultimedia
BuildRequires:	qt5-qtbase-devel
BuildRequires:	qt5-qtmultimedia-devel
%endif
%else
%if %{with qt}
%if 0%{?suse_version}
Requires:	libqt4 >= 4.7.0
BuildRequires:	libqt4-devel >= 4.7.0
%else
Requires:	qt >= 4.7.0
BuildRequires:	qt-devel >= 4.7.0
%endif
%endif
%endif
Requires:	%{name} = %{version}-%{release}
Requires:	xdg-utils
Requires:	hicolor-icon-theme
BuildRequires:	desktop-file-utils
Requires(post):	desktop-file-utils
Requires(post): /usr/sbin/update-alternatives
Requires(postun): /usr/sbin/update-alternatives
BuildRequires:	gcc-c++
%if 0%{?suse_version}
# Need this for SuSE's suse_update_desktop_file macro
BuildRequires:	update-desktop-files
%endif

%description qt
This package contains the Qt Wireshark GUI and desktop integration files.
%endif

%if %{with gtk2} || %{with gtk3}
%package	gtk
Summary:	Wireshark's GTK+-based GUI
Group:		Applications/Internet
# This package used to be called wireshark-gnome.  Tell the system about
# the rename.  The Provides line is optional to help people find the new
# package.
Provides:	wireshark-gnome
Obsoletes:	wireshark-gnome
%if %{with gtk3}
Requires:	gtk3 >= 3.0.0
BuildRequires:	gtk3-devel >= 3.0.0
%else
%if %{with gtk2}
Requires:	gtk2 >= 2.12.0
BuildRequires:	gtk2-devel >= 2.12.0
%endif
%endif
Requires:	%{name} = %{version}-%{release}
Requires:	xdg-utils
Requires:	hicolor-icon-theme
BuildRequires:	desktop-file-utils
Requires(post):	desktop-file-utils
Requires(post): /usr/sbin/update-alternatives
Requires(postun): /usr/sbin/update-alternatives
%if 0%{?suse_version}
# Need this for SuSE's suse_update_desktop_file macro
BuildRequires:	update-desktop-files
%endif
%if %{with_portaudio}
BuildRequires:	portaudio-devel
Requires:	portaudio
%endif

# Uncomment these if you want to be sure you get them...
#BuildRequires:	GeoIP-devel
#Requires:	GeoIP
# Add this for more readable fonts on some distributions/versions
#Requires:	dejavu-sans-mono-fonts

%description gtk
This package contains the GTK+ Wireshark GUI and desktop integration files.
%endif


%prep
%setup -q -n %{name}-%{version}

# Don't specify the prefix here: configure is a macro which expands to set
# the prefix and everything else too.  If you need to change the prefix
# set _prefix (note the underscore) either in this file or on rpmbuild's
# command-line.
%configure \
  --with-gnu-ld \
%if %{with_c_ares}
  --with-c-ares \
%endif
%if %{with_adns}
  --with-adns \
%endif
%if %{with lua}
  --with-lua \
%endif
%if %{with_portaudio}
  --with-portaudio \
%endif
%if %{with qt}
  --with-qt=4 \
%else
%if %{with qt5}
  --with-qt=5 \
%else
  --without-qt \
%endif
%endif
%if %{with gtk2}
  --with-gtk2 \
%else
  --without-gtk2 \
%endif
%if %{with gtk3}
  --with-gtk3 \
%else
  --without-gtk3 \
%endif
  --disable-warnings-as-errors

# Remove rpath.  It's prohibited in Fedora[1] and anyway we don't need it (and
# sometimes it gets in the way).
# [1] https://fedoraproject.org/wiki/Packaging:Guidelines#Beware_of_Rpath
sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool
sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool

# Suggestion: put this in your ~/.rpmmacros (without the hash sign, of course):
# %_smp_mflags -j %(grep -c processor /proc/cpuinfo)
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install

# If we're being installed in an unusual prefix tell the loader where
# to find our libraries.
%if "%{_prefix}" != "/usr"
	%define install_ld_so_conf 1
	mkdir -p $RPM_BUILD_ROOT/etc/ld.so.conf.d
	echo %{_libdir} > $RPM_BUILD_ROOT/etc/ld.so.conf.d/wireshark.conf
%endif

%if %{with qt} || %{with qt5}
# Change the program name for 'alternatives'
mv %{buildroot}%{_bindir}/wireshark %{buildroot}%{_bindir}/wireshark-qt
%endif
%if %{with qt} || %{with qt5} || %{with gtk2} || %{with gtk3}
# Create the 'alternative' file
touch %{buildroot}%{_bindir}/wireshark
%if 0%{?suse_version}
# SuSE's packaging conventions
# (http://en.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros#.25suse_update_desktop_file)
# require this:
%suse_update_desktop_file %{name}
%else
# Fedora's packaging guidelines (https://fedoraproject.org/wiki/Packaging:Guidelines)
# require this (at least if desktop-file-install was not used to install it).
desktop-file-validate %{buildroot}%{_datadir}/applications/wireshark.desktop
desktop-file-validate %{buildroot}%{_datadir}/applications/wireshark-gtk.desktop
%endif
%endif

%clean
rm -rf $RPM_BUILD_ROOT

%pre
%if %{use_wireshark_group}
getent group wireshark >/dev/null || groupadd -r wireshark
%endif
# If we have a pre-alternatives wireshark binary out there, get rid of it.
# (With 'alternatives' %{_bindir}/wireshark should be a symlink.)
if [ -f %{_bindir}/wireshark ]
then
	rm -f %{_bindir}/wireshark
fi

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%if %{with qt} || %{with qt5}
%post qt
update-desktop-database %{_datadir}/applications &> /dev/null || :
update-mime-database %{_datadir}/mime &> /dev/null || :
touch --no-create %{_datadir}/icons/hicolor &>/dev/null || :
/usr/sbin/update-alternatives --install %{_bindir}/wireshark \
  %{name} %{_bindir}/wireshark-qt 50

%postun qt
update-desktop-database %{_datadir}/applications &> /dev/null ||:
update-mime-database %{_datadir}/mime &> /dev/null || :
if [ $1 -eq 0 ] ; then
	/usr/sbin/update-alternatives --remove %{name} %{_bindir}/wireshark-qt
fi
%endif

%if %{with gtk2} || %{with gtk3}
%post gtk
update-desktop-database %{_datadir}/applications &> /dev/null ||:
update-mime-database %{_datadir}/mime &> /dev/null || :
touch --no-create %{_datadir}/icons/hicolor &>/dev/null || :
gtk-update-icon-cache -t %{_datadir}/icons/hicolor &>/dev/null || :
/usr/sbin/update-alternatives --install %{_bindir}/wireshark \
  %{name} %{_bindir}/wireshark-gtk 10

%postun gtk
update-desktop-database %{_datadir}/applications &> /dev/null ||:
update-mime-database %{_datadir}/mime &> /dev/null || :
if [ $1 -eq 0 ] ; then
	touch --no-create %{_datadir}/icons/hicolor &>/dev/null || :
	gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :
	/usr/sbin/update-alternatives --remove %{name} %{_bindir}/wireshark-gtk
fi
%endif

%files
%defattr(-,root,root)
%doc AUTHORS COPYING ChangeLog INSTALL INSTALL.configure NEWS README*
# Don't pick up any of the wireshark (GUI) binaries here
%exclude %{_bindir}/wireshark*
%{_bindir}/*

# This generates a warning because dumpcap is listed twice. That's
# probably preferable to listing each program (and keeping the list up to
# date)...  Maybe if we can find a way to get the toplevel Makefile.am's
# bin_PROGRAMS in here?
%if %{use_wireshark_group} && %{setuid_dumpcap}
# Setuid but only executable by members of the 'wireshark' group
%attr(4750, root, wireshark) %{_bindir}/dumpcap
%else
%if %{use_wireshark_group} && %{setcap_dumpcap}
# Setcap but only executable by members of the 'wireshark' group
%attr(0750, root, wireshark) %caps(cap_net_raw,cap_net_admin=ep) %{_bindir}/dumpcap
%else
%if %{setuid_dumpcap}
# Setuid and executable by all
%attr(4755, root, root) %{_bindir}/dumpcap
%else
%if %{setcap_dumpcap}
# Setcap and executable by all
%attr(0755, root, root) %caps(cap_net_raw,cap_net_admin=ep) %{_bindir}/dumpcap
%else
# Executable by all but with no special permissions
%attr(0755, root, root) %{_bindir}/dumpcap
%endif
%endif
%endif
%endif

%{_libdir}/lib*.so*
%exclude %{_libdir}/%{name}/plugins/%{version}/*.la
%exclude %{_libdir}/*.la
%{_libdir}/wireshark
# Don't pick up the wireshark (GUI) man page
%exclude %{_mandir}/man1/wireshark.*
# Our RPMs use 'alternatives' to choose the Wireshark so it doesn't make sense
# to have 2 desktop entries: one for 'wireshark' (Qt or Gtk GUI, depending on
# configuration) and one for 'wireshark-gtk' (the Gtk GUI).
%exclude %{_datadir}/applications/wireshark-gtk.desktop
%{_mandir}/man1/*
%{_mandir}/man4/*
%{_datadir}/wireshark
%if 0%{?install_ld_so_conf}
/etc/ld.so.conf.d/wireshark.conf
%endif

%if %{with qt} || %{with qt5}
%files qt
%defattr(-,root,root)
%{_datadir}/applications/wireshark.desktop
%{_datadir}/appdata/wireshark.appdata.xml
%{_datadir}/icons/hicolor/*/apps/*
%{_datadir}/icons/hicolor/*/mimetypes/*
%{_datadir}/mime/packages/wireshark.xml
%{_bindir}/wireshark-qt
%{_mandir}/man1/wireshark.*
%ghost %{_bindir}/wireshark
%endif

%if %{with gtk2} || %{with gtk3}
%files gtk
%defattr(-,root,root)
%{_datadir}/applications/wireshark.desktop
%{_datadir}/appdata/wireshark.appdata.xml
%{_datadir}/icons/hicolor/*/apps/*
%{_datadir}/icons/hicolor/*/mimetypes/*
%{_datadir}/mime/packages/wireshark.xml
%{_bindir}/wireshark-gtk
%{_mandir}/man1/wireshark.*
%ghost %{_bindir}/wireshark
%endif

%changelog
* Tue Nov 10 2015 Jeff Morriss
- Rename the gnome package to gtk: Wireshark uses Gtk+ but isn't part of GNOME.

* Mon Sep 14 2015 Jeff Morriss
- Follow ./configure's decision on whether to configure Lua or not rather than
  forcing it to be enabled (and thus failing on some distros which don't ship
  a compatible version of Lua any more).

* Sat Sep 12 2015 Jeffrey Smith
- Begin support for Qt5

* Thu Jan 22 2015 Jeff Morriss
- Add appdata file.

* Tue Jan 20 2015 Jeff Morriss
- Make the license tag more specific: Wireshark is GPLv2+.

* Mon Jan 12 2015 Jeff Morriss
- Modernize the (base package) %description.

* Wed Dec  3 2014 Jeff Morriss
- Don't run gtk-update-icon-cache when uninstalling the Qt package.  But do run
  it when installing the gnome package.
- Tell the loader where to find our libraries if we're being installed
  someplace other than /usr .
- Attempt to get RPMs working with a prefix other than /usr (now that the
  (free)desktop files are no longer always installed /usr).  Desktop
  integration doesn't work for prefixes other than "/usr" or "/usr/local".

* Fri Aug 29 2014 Gerald Combs
- The Qt UI is now the default. Update logic and prioritization to
  reflect this.

* Mon Aug 4 2014 Jeff Morriss
- Fix RPM builds with a prefix other than /usr: The location of
  update-alternatives does not depend on Wireshark's installation prefix:
  it's always in /usr/sbin/.

* Fri Aug  1 2014 Jeff Morriss
- Remove the old wireshark binary during RPM upgrades: this is needed because
  we now declare wireshark to be %ghost so it doesn't get overwritten during an
  upgrade (but in older RPMs it was the real program).

* Tue Jul  1 2014 Jeff Morriss
- Get rid of rpath when we're building RPMs: Fedora prohibits it, we don't
  need it, and it gets in the way some times.

* Tue Nov 26 2013 Jeff Morriss
- Overhaul options handling to pull in the UI choice from ./configure.
- Make it possible to not build the GNOME package.

* Tue Nov 12 2013 Jeff Morriss
- Add a qt package using 'alternatives' to allow the administrator to choose
  which one they actually use.

* Fri Sep 20 2013 Jeff Morriss
- If we're not using gtk3 add --with-gtk2 (since Wireshark now defaults to gtk3)

* Thu Mar 28 2013 Jeff Morriss
- Simplify check for rpmbuild's version.

* Fri Mar  8 2013 Jeff Morriss
- Put all icons in hicolor
- Use SuSE's desktop-update macro.
- Actually update MIME database when Wireshark's prefix is not /usr .

* Thu Mar  7 2013 Jeff Morriss
- List more build dependencies.
- Update to work on SuSE too: some of their package names are different.

* Wed Mar  6 2013 Gerald Combs
- Enable c-ares by default

* Thu Feb  7 2013 Jeff Morriss
- Overhaul to make this file more useful/up to date.  Many changes are based
  on Fedora's .spec file.  Changes include:
  - Create a separate wireshark-gnome package (like Red Hat).
  - Control some things with variables set at the top of the file.
    - Allow the user to configure how dumpcap is installed.
    - Allow the user to choose some options including GTK2 or GTK3.
  - Greatly expand the BuildRequires entries; get the minimum versions of some
    things from 'configure'.
  - Install freedesktop files for better (free)desktop integration.

* Thu Aug 10 2006 Joerg Mayer
- Starting with X.org 7.x X11R6 is being phased out. Install wireshark
  and manpage into the standard path.

* Mon Aug 01 2005 Gerald Combs
- Add a desktop file and icon for future use

- Take over the role of packager

- Update descriptions and source locations

* Thu Oct 28 2004 Joerg Mayer
- Add openssl requirement (heimdal and net-snmp are still automatic)

* Tue Jul 20 2004 Joerg Mayer
- Redo install and files section to actually work with normal builds

* Sat Feb 07 2004 Joerg Mayer
- in case there are shared libs: include them

* Tue Aug 24 1999 Gilbert Ramirez
- changed to ethereal.spec.in so that 'configure' can update
  the version automatically

* Tue Aug 03 1999 Gilbert Ramirez <gram@xiexie.org>
- updated to 0.7.0 and changed gtk+ requirement

* Sun Jan 03 1999 Gerald Combs <gerald@zing.org>
- updated to 0.5.1

* Fri Nov 20 1998 FastJack <fastjack@i-s-o.net>
- updated to 0.5.0

* Sun Nov 15 1998 FastJack <fastjack@i-s-o.net>
- created .spec file
