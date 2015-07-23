# The MIT License (MIT)
# Copyright (c) 2015 Teem2 LLC

export DALI_BUILD_HOME=~/dali-nodejs
export DALI_MAKE_CORS=4
export TIZEN_USER=rteem

mkdir $DALI_BUILD_HOME
cd $DALI_BUILD_HOME

source setenv
echo "setenv sourced, DESKTOP_PREFIX=$DESKTOP_PREFIX"

# dali-adaptor build
cd $DALI_BUILD_HOME
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-adaptor
cd dali-adaptor
git checkout devel/master
cd $DALI_BUILD_HOME/dali-adaptor/build/tizen
autoreconf --install
./configure 'CXXFLAGS=-O0 -g' --enable-gles=20 --enable-profile=UBUNTU --prefix=$DESKTOP_PREFIX --enable-debug --with-node-js=/home/dali/node-v0.12.4/deps/uv/include/
make install -j$DALI_MAKE_CORS

# dali-toolkit build
cd $DALI_BUILD_HOME
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-toolkit
cd dali-toolkit
git checkout devel/master
cd $DALI_BUILD_HOME/dali-toolkit/build/tizen
autoreconf --install
./configure --prefix=$DESKTOP_PREFIX --enable-debug 
make install -j$DALI_MAKE_CORS

# dali-demos
cd $DALI_BUILD_HOME
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-demo
cd dali-demo
git checkout devel/master
# DALi demo does not work with current version of DALi + Node.js
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








