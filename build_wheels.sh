#!/bin/bash
set -ex

# Install ZLib and sudo
yum install -y zlib-devel sudo
export HOME="/root"

# Install Rustup
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
export PATH="$HOME/.cargo/bin:$PATH"

# Install Stack
curl -sSL https://get.haskellstack.org/ | sh
export PATH="$HOME/.local/bin:$PATH"

# Set stack resolver to 8.6.5
mkdir -p $HOME/.stack/global-project
cp .github/stack/stack.yaml $HOME/.stack/global-project
cp packaging/0001-Allow-binaries-larger-than-32MB.patch $HOME

pushd $HOME
stack config set resolver ghc-8.6.5
popd
# TAR_OPTIONS=--no-same-owner stack setup --allow-different-user

# Compile patchelf and apply 64MB patch
pushd /root
git clone https://github.com/NixOS/patchelf
cd patchelf
git apply $HOME/0001-Allow-binaries-larger-than-32MB.patch

bash bootstrap.sh
./configure
make
make install
popd

# Compile libducklingffi
cd /io
pushd duckling-ffi

stack build
cp libducklingffi.so ../ext_lib
popd

# Produce wheels and patch binaries for redistribution
PYBIN=/opt/python/cp$(echo $PYTHON_VERSION | sed -e 's/\.//g')*/bin
# for PYBIN in /opt/python/cp{35,36,37,38,39}*/bin; do
"${PYBIN}/pip" install -U setuptools wheel setuptools-rust
"${PYBIN}/python" packaging/build_wheels.py
# done
