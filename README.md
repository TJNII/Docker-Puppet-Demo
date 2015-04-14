Docker Puppet Demo
==================

This repo contains a Docker build environment which builds a container which, in turn, starts Gitlab via Docker containers.
This container configures Puppet modules to run Gitlab via the [garethr/docker](https://forge.puppetlabs.com/garethr/docker) Puppet module controlling the [sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab) Docker container.
An older version of garethr/docker is in use as it is known stable.  This is included as a Git submodule.
The container also installs an older version of Docker (1.2.0) which is known stable with this version of garethr/docker and matches the Docker version of the host for the demo.

The container is intended to be run with the host Docker socket volume mapped in, Puppet will not start Docker.
As such Gitlab must be stopped before the container is stopped, otherwise Gitlab will continue to run on the host.
This container will also vreate /gitlab/ on the host for gitlab data, which should be removed after the demo.
Running Docker in the container is possible but not done in the demo due to host/container mismatch issues.

Authors
-------

- Tom Noonan II (Tom@tjnii.com)
