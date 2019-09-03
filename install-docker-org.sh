#!/bin/bash

set -ex

BASE_DIR=./

echo $(ls)
WIRESHARK_VERSION="2.0.8"
BUILD_DEPS="python-pip build-essential pkg-config wget bison flex libglib2.0-dev libpython2.7-dev libpcap-dev"
RUN_DEPS="libpython2.7"

# Install deps
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --force-yes --no-install-recommends --no-install-suggests $RUN_DEPS $BUILD_DEPS
pip install pyserial crcmod xmltodict


# Compile wireshark
cd $BASE_DIR
wget https://www.wireshark.org/download/src/all-versions/wireshark-$WIRESHARK_VERSION.tar.bz2
tar -xjvf wireshark-$WIRESHARK_VERSION.tar.bz2
rm wireshark-$WIRESHARK_VERSION.tar.bz2
WIRESHARK_SRC_PATH=$BASE_DIR/wireshark-$WIRESHARK_VERSION
cd $WIRESHARK_SRC_PATH
#cp /opt/mi/Make* ./epan/dissectors/

./configure --enable-wireshark=no  --without-zlib --with-portaudio=no --with-krb5=no --without-plugins  --enable-editcap=no --enable-dumpcap=no --enable-capinfos=no --enable-mergecap=no --enable-text2pcap=no  --with-ssl=no --disable-glibtest --enable-usr-local=no --with-gnutls-prefix=no


#./configure --disable-wireshark
make -j 8 install
strip --strip-unneeded /usr/local/lib/lib*.so
ldconfig

# Compile dm_collector_c
cd $BASE_DIR/dm_collector_c
rm -f dm_collector_c.so
g++ -g -fPIC -shared *.cpp `pkg-config --libs --cflags python-2.7` -DEXPOSE_INTERNAL_LOGS=1 -o dm_collector_c.so
cp dm_collector_c.so ../mobile_insight/monitor/dm_collector/

# Compile ws_dissector
cd $BASE_DIR/ws_dissector
rm -f ws_dissector
g++ ws_dissector.cpp packet-aww.cpp `pkg-config --libs --cflags glib-2.0` -I"${WIRESHARK_SRC_PATH}" -lwireshark -lwsutil -lwiretap -o ws_dissector
strip ws_dissector

# Remove wireshark
rm -rf $WIRESHARK_SRC_PATH

# Install MobileInsight
cd $BASE_DIR
python setup.py install

# Cleanup
apt-get purge -y --force-yes $BUILD_DEPS
apt-get clean -y --force-yes clean
apt-get -y --force-yes autoremove
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc /usr/share/man /usr/share/locale /var/cache/debconf/*-old
