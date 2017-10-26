#!/bin/bash

set -e
set -x

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
  asciidoc \
  autoconf \
  bash \
  build-essential \
  curl \
  expect \
  exuberant-ctags \
  g++ \
  gettext \
  libaio1 \
  libaio-dev \
  nfs-common \
  openssl \
  tcl \
  tmux \
  vim \
  xmlto \
  xsltproc \
  zlib1g-dev \
  zsh

sudo chown -R ubuntu:ubuntu /opt/
mkdir -p /opt/dev /opt/sw

MAKE="make -j$(( ${NCPUS:-1} + 1 ))"


#
# Node.js
# 
NODEJS_VERSION='8.7.0'
NODEJS_BASENAME="node-v${NODEJS_VERSION}-linux-x64"
NODEJS_FILENAME="${NODEJS_BASENAME}.tar.xz"

wget "http://nodejs.org/dist/v${NODEJS_VERSION}/${NODEJS_FILENAME}" \
  -O "/tmp/${NODEJS_FILENAME}"
cd /tmp
tar xvJf "${NODEJS_FILENAME}"
mv "/tmp/${NODEJS_BASENAME}" /opt/
ln -s "/opt/${NODEJS_BASENAME}" /opt/nodejs

# Keep these blocks in sync
{
  export PATH="/opt/nodejs/bin:${PATH}"
  export NODE_PATH='/opt/nodejs/lib/node_modules'
  export NODE_PATH="${NODE_PATH}:/opt/dev/node_modules"
  export NODE_PATH="${NODE_PATH}:/opt/dev/lib/node_modules"
  export NODE_PATH="${NODE_PATH}:/usr/local/lib/node_modules"
}
{
  echo '# Node.js'
  echo "export PATH=\"/opt/nodejs/bin:${PATH}\""
  echo "export NODE_PATH='/opt/nodejs/lib/node_modules'"
  echo "export NODE_PATH=\"${NODE_PATH}:/opt/dev/node_modules\""
  echo "export NODE_PATH=\"${NODE_PATH}:/opt/dev/lib/node_modules\""
  echo "export NODE_PATH=\"${NODE_PATH}:/usr/local/lib/node_modules\""
  echo
} | tee -a "${HOME}/.bashrc.local" >> "${HOME}/.zshrc.local"

npm install -g \
  ts-protoc-gen \
  typescript


#
# Git
#
GIT_VERSION='2.9.5'
GIT_BASENAME="git-${GIT_VERSION}"
GIT_FILENAME="${GIT_BASENAME}.tar.xz"

wget "https://www.kernel.org/pub/software/scm/git/${GIT_FILENAME}" \
  -O "/tmp/${GIT_FILENAME}"
cd /tmp
tar xvJf "${GIT_FILENAME}"
mv "/tmp/${GIT_BASENAME}" /opt/sw/
ln -s "/opt/sw/${GIT_BASENAME}" /opt/sw/git

mkdir -p /opt/git/
cd /opt/sw/git
${MAKE} configure
./configure --prefix=/opt/git
${MAKE} all doc
sudo ${MAKE} install install-doc

# Keep these blocks in sync
{
  export PATH="/opt/git/bin:${PATH}"
  export MANPATH="/opt/git/share:${MANPATH}"
  export LD_LIBRARY_PATH="/opt/git/lib:${LD_LIBRARY_PATH}"
}
{
  echo '# Git'
  echo "export PATH=\"/opt/git/bin:${PATH}\""
  echo "export MANPATH=\"/opt/git/share:${MANPATH}\""
  echo "export LD_LIBRARY_PATH=\"/opt/git/lib:${LD_LIBRARY_PATH}\""
  echo
} | tee -a "${HOME}/.bashrc.local" >> "${HOME}/.zshrc.local"


#
# Manually add a key to the agent.
#
eval $(ssh-agent -s)
source ${HOME}/.ssh/identities/git/id_rsa.passphrase
expect  < <(cat <<EOF
  spawn ssh-add ${HOME}/.ssh/identities/git/id_rsa.pub
  expect "Enter passphrase for ${HOME}/.ssh/id_rsa.pub: "
  send "${GITHUB_RSA_PASSPHRASE}"
EOF
)


#
# ssh-ident
#
mkdir -p /opt/sw
cd /opt/sw
# TODO(epaniagua): Make this more robust, eg by using a submodule or a copy of the source for a specific version.
git clone git@github.com:ccontavalli/ssh-ident.git
cp /vagrant/ssh-ident "${HOME}/.ssh-ident"
ln -s /opt/sw/ssh-ident/ssh-ident "${HOME}/bin/ssh"


#
# Environment
#
export PATH="${HOME}/bin:${PATH}"


#
# Almost done!
#
echo
echo
echo "Only a few steps left:"
echo "1) Clone your repo under /opt/dev."
echo "2) If commiting using a different account than your host, change your email for git commits with"
echo "   $ git config --global user.email 'whatever-it@should.be'"
