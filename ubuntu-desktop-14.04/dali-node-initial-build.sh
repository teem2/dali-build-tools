#!/bin/bash
# The MIT License (MIT)
# Copyright (c) 2015 Teem2 LLC
#
# Ubuntu 14.04 Bash build script for DALi 3D Framework with Node.js support
#
# Required software for the build:
#   + Node.js 4.2.6
#     https://github.com/nodejs/node/releases/tag/v4.2.6
#     Build from source following these instructions
#     https://github.com/joyent/node/wiki/installation#building-on-linux
#     The Node.js source code should be in folder:
#     /home/$USER/node-4.2.6
#     If you have the Node.js source code in a different location, you can
#     adjust the node_folder variable below.
#
#   + yuidocjs 0.5
#     sudo npm install -g yuidocjs@0.5
#
#   + node-gyp
#     sudo npm install -g node-gyp

### CONFIGURATON OPTIONS ###
export DALI_BUILD_HOME=~/dali-nodejs
node_folder=`echo "/home/$USER"`/node-4.2.6
# Enable network logging for Dali adaptor. Possible values: 0 | 1
enable_network_logging=1 

# Configure your Tizen Gerrit account name. Follow the development
# environment setup guide, you plan to use your own account.
# https://source.tizen.org/development/developer-guide/environment-setup
export TIZEN_USER=rteem


### SCRIPT STARTS ###
mkdir $DALI_BUILD_HOME
cd $DALI_BUILD_HOME

rm -rf *

# get dali-core repo first
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-core
cd dali-core
cd $DALI_BUILD_HOME


# parallel make
export NUMCPUS=`grep -c '^processor' /proc/cpuinfo`
# Since modern CPUs should support hyperthreading, we can use at
# least use double the number of CPUs -1 for 'make':
export DALI_MAKE_CORS=`python -c "print (int(${NUMCPUS} * 2 - 1))"`
echo "System has $NUMCPUS CPU cores with, running build with $DALI_MAKE_CORS processes."
# Set the number of processes for the V8 build process to $DALI_MAKE_CORS
sed -i "s/make -j8/make -j$DALI_MAKE_CORS/" dali-core/build/scripts/dali_env


# Initiate dali environment setup
dali-core/build/scripts/dali_env -c
dali-env/opt/bin/dali_env -s > setenv
source setenv
echo "setenv sourced, DESKTOP_PREFIX=$DESKTOP_PREFIX"

# dali-core build
cd $DALI_BUILD_HOME/dali-core/build/tizen
autoreconf --install
./configure --prefix=$DESKTOP_PREFIX --enable-debug
make install -j$DALI_MAKE_CORS

# dali-adaptor build
cd $DALI_BUILD_HOME
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-adaptor
cd dali-adaptor
cd $DALI_BUILD_HOME/dali-adaptor/build/tizen
autoreconf --install

if [ $enable_network_logging -eq 1 ]
then
    ./configure 'CXXFLAGS=-O0 -g' --enable-gles=20 --enable-profile=UBUNTU --prefix=$DESKTOP_PREFIX --enable-debug  --with-libuv=$node_folder/deps/uv/include/ --enable-networklogging
else
    ./configure 'CXXFLAGS=-O0 -g' --enable-gles=20 --enable-profile=UBUNTU --prefix=$DESKTOP_PREFIX --enable-debug  --with-libuv=$node_folder/deps/uv/include/
fi


make install -j$DALI_MAKE_CORS

# dali-toolkit build
cd $DALI_BUILD_HOME
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-toolkit
cd dali-toolkit
cd $DALI_BUILD_HOME/dali-toolkit/build/tizen
autoreconf --install
./configure --prefix=$DESKTOP_PREFIX --enable-debug
make install -j$DALI_MAKE_CORS

# dali-demos
cd $DALI_BUILD_HOME
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-demo
cd dali-demo
cd $DALI_BUILD_HOME/dali-demo/build/tizen
cmake -DCMAKE_INSTALL_PREFIX=$DESKTOP_PREFIX .
make install -j$DALI_MAKE_CORS

# Build Node.js example
cd $DALI_BUILD_HOME/dali-toolkit/node-addon
node-gyp rebuild
cp $DALI_BUILD_HOME/dali-adaptor/adaptors/common/feedback/default-feedback-theme.json .
npm install netflix-roulette

# Build JavaScript API docs
cd $DALI_BUILD_HOME/dali-toolkit/plugins/dali-script-v8/docs
yuidoc --config yuidoc.json -e ".cpp,.js,.md"  -o generated .. \ ../../../docs/content/shared-javascript-and-cpp-documentation/

cd $DALI_BUILD_HOME/dali-toolkit/build/tizen/docs
make
