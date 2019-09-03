#!/bin/bash
BASE_DIR=./
PREFIX=/usr/local
echo $(pwd)
# A copy of Wireshark sources will be put inside the MobileInsight source folder
WIRESHARK_SRC_PATH=$(pwd)/wireshark-2.0.13


# Make sure compile environment and other dependencies are installed
# Install deps
apt-get update
pip install pyserial crcmod xmltodict
sudo apt-get -y install pkg-config wget libglib2.0-dev bison flex libpcap-dev

# Download necessary source files to compile ws_dissector
# Make sure the package version is in accordance to the version that was
# installed previously
wget https://www.wireshark.org/download/src/all-versions/wireshark-2.0.13.tar.bz2
tar -xjvf wireshark-2.0.13.tar.bz2
rm wireshark-2.0.13.tar.bz2


# Generate config.h for Wireshark 2.0.8
cd ${WIRESHARK_SRC_PATH}
#./configure --enable-wireshark=no  --without-zlib --with-portaudio=no --with-krb5=no --without-plugins  --enable-editcap=no --enable-dumpcap=no --enable-capinfos=no --enable-mergecap=no --enable-text2pcap=no  --with-ssl=no --disable-glibtest --enable-usr-local=no --with-gnutls-prefix=no


#./configure --disable-wireshark
#make -j 8 install
#strip --strip-unneeded /usr/local/lib/lib*.so
#ldconfig

./configure --disable-wireshark > /dev/null 2>&1

echo "Check if wireshark dynamic library exists in system path......"

FindWiresharkLibrary=true

if ldconfig -p | grep "libwireshark.so "; then
    echo "Found libwireshark.so!";
else
    echo "Didn't find libwireshark.so";
    FindWiresharkLibrary=false
fi

if ldconfig -p | grep "libwiretap.so "; then
    echo "Found libwiretap.so!";
else
    echo "Didn't find libwiretap.so";
    FindWiresharkLibrary=false
fi

if ldconfig -p | grep "libwsutil.so "; then
    echo "Found libwsutil.so!";
else
    echo "Didn't find libwsutil.so";
    FindWiresharkLibrary=false
fi

if [ "$FindWiresharkLibrary" = false ] ; then
    echo "Compile wireshark 2.0.13 from source code, it may take a few minutes......"
    make > /dev/null 2>&1  || exit 1
    sudo make install  > /dev/null 2>&1
fi

sudo rm /etc/ld.so.cache
sudo ldconfig

#Compile ws_dissector
echo $(pwd)
cd ..
cd ws_dissector
echo $(pwd)
rm -f ws_dissector
g++ ws_dissector.cpp packet-aww.cpp -o ws_dissector `pkg-config --libs --cflags glib-2.0` -I"${WIRESHARK_SRC_PATH}" -L"${PREFIX}/lib" -lwireshark -lwsutil -lwiretap
strip ws_dissector #changes

echo "installing wireshark dissector to ${PREFIX}/bin"
sudo cp ws_dissector ${PREFIX}/bin/
sudo chmod 755 ${PREFIX}/bin/ws_dissector


# Install compiled MobileInsight desktop version
cd ..
echo $(pwd)
sudo python setup.py install

# Run example
echo ""
echo "Successfully installed the newest version of MobileInsight desktop version!"
echo "Testing the offline analysis example."
cd examples
echo $(pwd)
python offline-analysis-example.py

echo ""

