# The MIT License (MIT)
# Copyright (c) 2015 Teem2 LLC

export DALI_BUILD_HOME=~/dali-nodejs
export DALI_MAKE_CORS=4
export TIZEN_USER=rteem

mkdir $DALI_BUILD_HOME
cd $DALI_BUILD_HOME


rm -rf *

# get dali-core repo first
git clone ssh://$TIZEN_USER@review.tizen.org:29418/platform/core/uifw/dali-core
cd dali-core
git checkout devel/master
cd $DALI_BUILD_HOME

# Fix for the dali_env script failing when running gclient-sync
sed -i 's/  if($ret >> 8)/#  This line fails, therefore commented out\n#  if($ret >> 8)/' dali-core/build/scripts/dali_env

# Fix the problem with the git checkout of a specific version
sed -i 's/run_command( "git checkout ". $v8Version );/run_command( "git checkout" );\nrun_command( "git fetch" );\nrun_command( "git checkout ". $v8Version );/' dali-core/build/scripts/dali_env

# Set the number of processes for the V8 build process to $DALI_MAKE_CORS
sed -i "s/make -j8/make -j$DALI_MAKE_CORS/" dali-core/build/scripts/dali_env

# disable v8 build
# sed -i.bak "s/check_source_packages();/# disabled V8 build\n# check_source_packages();/" dali-core/build/scripts/dali_env

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

# stop here, and continue with dali-node-step2.sh
exit









