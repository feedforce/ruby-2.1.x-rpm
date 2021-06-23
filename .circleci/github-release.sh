#!/bin/sh

set -xe

RUBY_VERSION=$(grep '^Version: ' ruby-${1}.spec | awk '{ print $NF }')

get_github_release() {
  version=v0.7.5
  wget https://github.com/meterup/github-release/releases/download/${version}/linux-amd64-github-release.bz2
  bzip2 -d linux-amd64-github-release.bz2
  chmod +x linux-amd64-github-release
  mkdir -p $HOME/bin
  mv linux-amd64-github-release $HOME/bin/github-release
}

get_github_release
cp $CIRCLE_ARTIFACTS/*.rpm .

#
# Upload rpm files and build a release note
#

print_rpm_markdown() {
  RPM_FILE=$1
  cat <<EOS
* $RPM_FILE
    * sha256: $(openssl sha256 $RPM_FILE | awk '{print $2}')
EOS
}

upload_rpm() {
  RPM_FILE=$1
  $HOME/bin/github-release upload --user $CIRCLE_PROJECT_USERNAME \
    --repo $CIRCLE_PROJECT_REPONAME \
    --tag $RUBY_VERSION \
    --name "$RPM_FILE" \
    --file $RPM_FILE
}

cat <<EOS > description.md
Use at your own risk!

Build on CentOS 7

EOS

# CentOS 7

# Upload RPM files only aarch64
for i in *.el7.centos.aarch64.rpm; do
  upload_rpm $i
done

# Prepare to edit description
for i in *.el7.centos.*.rpm; do
  print_rpm_markdown $i >> description.md
done

#
# Make the release note to complete!
#

$HOME/bin/github-release edit \
  --user $CIRCLE_PROJECT_USERNAME \
  --repo $CIRCLE_PROJECT_REPONAME \
  --tag $RUBY_VERSION \
  --name "Ruby-${RUBY_VERSION}" \
  --description "$(cat description.md)"
