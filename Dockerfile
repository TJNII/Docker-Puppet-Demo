FROM centos:centos6

MAINTAINER Tom Noonan II <tom@tjnii.com>

# Install repos to be used
RUN yum install -y http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm epel-release

# Update the base image
RUN yum update -y

# Install Puppet & deps
RUN yum install -y puppet git tar hostname

# Install Docker 1.2.0 which is compatable with the older garther-puppet module (modified) in use.
# Docker is a hot project and they're always chinging things, so stable version combinations must be tracked.
# This also matches the version to the host OS for the demo (less risk)
RUN yum install -y http://ftp.cse.buffalo.edu/pub/epel/6/x86_64/docker-io-1.2.0-3.el6.x86_64.rpm

# Overlay config files & Puppet modules
COPY files/ /

# Install some needed modules
RUN puppet module install puppetlabs/stdlib

# Apply the settings with puppet delay, and then stop gitlab.
# Be sure to stop Gitlab if the demo maps in the host socket.
CMD puppet apply --modulepath=/etc/puppet/modules/ -e "class { 'roles::gitlab': }" && sleep 6h; ls /etc/init.d/docker-gitlab-* | while read line; do $line stop; done
