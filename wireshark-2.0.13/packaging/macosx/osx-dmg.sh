#!/bin/bash
#
# USAGE
# osx-dmg [-s] -p /path/to/Wireshark.app
#
# The script creates a read-write disk image,
# copies Wireshark into it, customizes its appearance using a
# previously created .DS_Store file (wireshark.ds_store),
# and then compresses the disk image for distribution.
#
# Copied from Inkscape.
#
# AUTHORS
#	Jean-Olivier Irisson <jo.irisson@gmail.com>
#	Michael Wybrow <mjwybrow@users.sourceforge.net>
#
# Copyright (C) 2006-2007
# Released under GNU GPL, read the file 'COPYING' for more information
#
#
# How to update the disk image layout:
# ------------------------------------
#
# Modify the 'dmg_background.svg' file and generate a new
# 'dmg_background.png' file.
#
# Update the AppleScript file 'dmg_set_style.scpt'.
#
# Run this script with the '-s' option.  It will apply the
# 'dmg_set_style.scpt' AppleScript file, and then prompt the
# user to check the window size and position before writing
# a new 'wireshark.ds_store' file to work around a bug in Finder
# and AppleScript.  The updated 'wireshark.ds_store' will need
# to be commited to the repository when this is done.
#

# Defaults
set_ds_store=false
ds_store_root="root.ds_store"
app_bundle="Wireshark.app"
rw_name="RWwireshark.dmg"
volume_name="Wireshark"
src_dir="."
tmp_dir="/tmp/dmg-$$"
auto_open_opt=

# Qt defaults
readme_name="Read_me_first_qt.rtf"
bundle_bin_name="Wireshark"

if [ -f /Applications/Xcode.app/Contents/Applications/PackageMaker.app/Contents/MacOS/PackageMaker ]
then
	#
	# Xcode 4 and later, with the "Auxiliary Tools for Xcode"
	# download from developer.apple.com.  (There are no such
	# downloads for Mavericks or later, but PackageMaker from
	# the Late July 2012 download for Mountain Lion appears to
	# work on Yosemite.)
	#
	packagemaker=/Applications/Xcode.app//Contents/Applications/PackageMaker.app/Contents/MacOS/PackageMaker
elif [ -f /Applications/Xcode.app/Developer/Tools/packagemaker ]
then
	packagemaker=/Applications/Xcode.app/Developer/Tools/packagemaker
elif [ -f /Applications/Xcode.app/Developer/usr/bin/packagemaker ]
then
	packagemaker=/Applications/Xcode.app/Developer/usr/bin/packagemaker
elif [ -f /Developer/Tools/packagemaker ]
then
	packagemaker=/Developer/Tools/packagemaker
elif [ -f /Developer/usr/bin/packagemaker ]
then
	packagemaker=/Developer/usr/bin/packagemaker
elif [ -f /usr/bin/packagemaker ]
then
	packagemaker=/usr/bin/packagemaker
elif [ -f /usr/local/bin/packagemaker ]
then
	packagemaker=/usr/local/bin/packagemaker
fi
if [ -z "$packagemaker" ]
then
	echo "$0: couldn't find PackageMaker" 1>&2
	exit 1
fi

# Help message
#----------------------------------------------------------
help()
{
echo -e "
Create a custom dmg file to distribute Wireshark

USAGE
	$0 [-s] -p /path/to/Wireshark.app

OPTIONS
	-h,--help
		Display this help message.
	-s
		Set a new apperance (do not actually create a bundle).
	-b,--app-bundle
		Set the path to the Wireshark.app that should be copied
		in the dmg.
	-qt,--qt-flavor
		Use the Qt flavor. This is the default.
	-gtk,--gtk-flavor
		Use the GTK+ flavor.
	-S,--source-directory
		If this is an out-of-tree build, set this to the path
		to the packaging/macosx source directory.
"
}

# Parse command line arguments
while [ "$1" != "" ]
do
	case $1 in
	  	-h|--help)
			help
			exit 0 ;;
	  	-s)
			set_ds_store=true ;;
	  	-b|--app-bundle)
			app_bundle="$2"
			shift 1 ;;
		-qt|--qt-flavor)
			;;
		-gtk|--gtk-flavor)
			readme_name="Read_me_first_gtk.rtf"
			bundle_bin_name="wireshark-bin"
			;;
		-S|--source-directory)
			src_dir="$2"
			shift 1 ;;
		*)
			echo "Invalid command line option"
			exit 2 ;;
	esac
	shift 1
done


# Safety checks
if [ ! -e "$app_bundle" ]; then
	echo "Cannot find application bundle: $app_bundle"
	exit 1
fi

# Get the architecture
ws_bin="$app_bundle/Contents/MacOS/$bundle_bin_name"
case `file $ws_bin` in
	*Mach-O*64-bit*x86_64*)
		architecture="Intel 64"
		;;
	*Mach-O*i386*)
		architecture="Intel 32"
		;;
	*Mach-O*ppc64*)
		architecture="PPC 64"
		;;
	*Mach-O*ppc*)
		architecture="PPC 32"
		;;
	*)
		echo "Cannot determine architecture of $ws_bin; file reports:"
		file $ws_bin
		exit 1
		;;
esac

# Set the version
version="2.0.13"
if [ -z "$version" ] ; then
	echo "VERSION not set"
	exit 1
fi

echo -e "\nCREATE WIRESHARK PACKAGE\n"
pkg_title="$volume_name $version $architecture"
pkg_file="$pkg_title.pkg"
rm -rf "$pkg_file"
$packagemaker --doc "Wireshark_package.pmdoc" \
    --title "$pkg_title" \
    --id "org.wireshark.pkg.Wireshark" \
    --version "$version" \
    --target 10.5 \
    --verbose || exit 1

if [ -n "$CODE_SIGN_IDENTITY" ] ; then
	pkg_file_unsigned="$pkg_title UNSIGNED.pkg"

	echo -e "Signing $pkg_file"
	mv "$pkg_file" "$pkg_file_unsigned" || exit 1
	productsign --sign "Developer ID Installer: $CODE_SIGN_IDENTITY" "$pkg_file_unsigned" "$pkg_file" || exit 1
	spctl --assess --type install "$pkg_file" || exit 1
	pkgutil --check-signature "$pkg_file" || exit 1
	shasum "$pkg_file"
	rm -rf "$pkg_dir_unsigned" "$pkg_file_unsigned" "$pkg_file_flattened"
else
	echo "Code signing not performed (no identity)"
fi

echo -e "\nCREATE WIRESHARK DISK IMAGE\n"
img_name="$pkg_title.dmg"

# Create temp directory with desired contents of the release volume.
rm -rf "$tmp_dir"
mkdir "$tmp_dir" || exit 1

echo -e "Copying files to temp directory"
# Copy the installer package
cp "$pkg_file" "$tmp_dir"/ || exit 1
# Copy the readme
cp "$src_dir/$readme_name" "$tmp_dir"/"Read me first.rtf" || exit 1

# If the appearance settings are not to be modified we just copy them
if [ ${set_ds_store} = "false" ]; then
	# Copy the .DS_Store file which contains information about
	# window size, appearance, etc.  Most of this can be set
	# with Apple script but involves user intervention so we
	# just keep a copy of the correct settings and use that instead.
	cp $src_dir/$ds_store_root "$tmp_dir/.DS_Store" || exit 1
	auto_open_opt=-noautoopen
fi

# Create a new RW image from the temp directory.
echo -e "Creating a temporary disk image"
rm -f "$rw_name"
/usr/bin/hdiutil create -srcfolder "$tmp_dir" -volname "$volume_name" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "$rw_name" || exit 1

# We're finished with the temp directory, remove it.
rm -rf "$tmp_dir"

# Mount the created image.
MOUNT_DIR="/Volumes/$volume_name"
DEV_NAME=`/usr/bin/hdiutil attach -readwrite -noverify $auto_open_opt  "$rw_name" | egrep '^/dev/' | sed 1q | awk '{print $1}'`

# Have the disk image window open automatically when mounted.
bless -openfolder /Volumes/$volume_name

# In case the apperance has to be modified, mount the image and apply the base settings to it via Applescript
if [ ${set_ds_store} = "true" ]; then
	/usr/bin/osascript dmg_set_style.scpt

	open "/Volumes/$volume_name"
	# BUG: one needs to move and close the window manually for the
	# changes in appearance to be retained...
        echo "
        **************************************
        *  Please move the disk image window *
        *    to the center of the screen     *
        *   then close it and press enter    *
        **************************************
        "
        read -e DUMB

	# .DS_Store files aren't written till the disk is unmounted, or finder is restarted.
	hdiutil detach "$DEV_NAME"
	auto_open_opt=-noautoopen
	DEV_NAME=`/usr/bin/hdiutil attach -readwrite -noverify $auto_open_opt  "$rw_name" | egrep '^/dev/' | sed 1q | awk '{print $1}'`
	echo
	cp /Volumes/$volume_name/.DS_Store ./$ds_store_root
	SetFile -a v ./$ds_store_root
	echo "New $ds_store_root written. Re-run $0 without the -s option to use them"

	# Unmount the disk image.
	hdiutil detach "$DEV_NAME"
	rm -f "$rw_name"

	exit 0
fi

# Unmount the disk image.
hdiutil detach "$DEV_NAME"

# Create the offical release image by compressing the RW one.
echo -e "Compressing the final disk image"

# TODO make this a command line option
if [ -e "$img_name" ]; then
	echo "$img_name already exists."
	rm -i "$img_name"
fi
/usr/bin/hdiutil convert "$rw_name" -format UDZO -imagekey zlib-level=9 -o "$img_name" || exit 1
rm -f "$rw_name"

#if [ -n "$CODE_SIGN_IDENTITY" ] ; then
#	echo -e "Signing the $img_name"
#	codesign --sign "$CODE_SIGN_IDENTITY" --verbose "$img_name" || exit 1
#	codesign --verify --verbose "$img_name" || exit 1
#fi

exit 0
