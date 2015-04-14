# This is a simple role class to call the modules needed to install Gitlab via Docker modules
class roles::gitlab (
   $storage_path = '/gitlab',
) {

# For the demo we're mapping in the Docker socket: Don't start Docker
# (This is possible, but Debian host & Cent Container aren't playing nice.)
#  # Ensure Docker is up and running
#  class { '::docker': 
#     use_upstream_package_source => false,
#  }

  # Ensure the Gitlab data source path is present
  file { $storage_path:
     ensure => directory,
  }

  # Run Gitlab!
  class { '::gitlab':
       gitlab_version         => '7.9.2',
       gitlab_image           => 'sameersbn/gitlab',
       postgres_version       => '9.4',
       postgres_image         => 'sameersbn/postgresql',
       redis_version          => '2015-04-12',
       redis_image            => 'sameersbn/redis',
       storage_path           => $storage_path,
  }
}
