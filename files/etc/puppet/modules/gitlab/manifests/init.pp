# This module starts the gitlab app via multiple containers
# At this time it is only safe to run on one host
class gitlab (
  $gitlab_version,
  $gitlab_image           = 'sameersbn/gitlab',
  $postgres_version,
  $postgres_image         = 'sameersbn/postgresql',
  $redis_version,
  $redis_image            = 'sameersbn/redis',
  $run                    = true,
  $gitlab_init_name       = 'gitlab_gitlab',
  $postgres_init_name     = 'gitlab_postgres',
  $redis_init_name        = 'gitlab_redis',
  $storage_path,
  $gitlab_uid             = 200,
  $gitlab_gid             = 200,
  ) {
  
  docker::image { $gitlab_image:
    image_tag => $gitlab_version
  }

  docker::image { $postgres_image:
    image_tag => $postgres_version
  }

  docker::image { $redis_image:
    image_tag => $redis_version
  }

  # Define image and volumes as variables so we can use it in the helper template
  $gitlab_tagged_image   = "${gitlab_image}:${gitlab_version}"
  $postgres_tagged_image = "${postgres_image}:${postgres_version}"
  $redis_tagged_image    = "${redis_image}:${redis_version}"

  # Set up storage directories
  $gitlab_data_dir     = "$storage_path/gitlab_data"
  $gitlab_postgres_dir = "$storage_path/gitlab_postgres"
  $gitlab_redis_dir    = "$storage_path/gitlab_redis"
  
  file { $gitlab_data_dir:
    ensure  => directory,
    owner   => $gitlab_uid,
    group   => $gitlab_gid,
    mode    => '0775',
  }

  # Don't enforce UID/GID on these as the continer takes them over.
  file { [ $gitlab_postgres_dir, $gitlab_redis_dir ]:
    ensure  => directory,
    mode    => '0775',
  }

  # Run the Redis container
  docker::run { $redis_init_name:
    image        => $redis_tagged_image,
    volumes      => [ "${gitlab_redis_dir}:/var/lib/redis" ],
    require      => [ File[$gitlab_redis_dir],
                      ],
    # I'm not sure if I should care about Redis shutting down, and don't want to find out the hard way.
    stop_timeout => 300,
    running      => $run,
  }

  # Run the database
  docker::run { $postgres_init_name:
    image        => $postgres_tagged_image,
    volumes      => [ "${gitlab_postgres_dir}:/var/lib/postgresql" ],
    require      => [ File[$gitlab_postgres_dir],
                      ],
    env          => [ 'DB_NAME=gitlabhq_production',
                      'DB_USER=gitlab',
                      'DB_PASS=Password123', # AFAICT this isn't used.
                      ],
    # Let the db stop plz
    stop_timeout => 300,
    running      => $run,
  }

  # Run the gitlab app
  # This is the big one with all the tunables.
  $redis_cid_file    = "/var/run/docker-${redis_init_name}.cid"
  $postgres_cid_file = "/var/run/docker-${postgres_init_name}.cid"
  docker::run { $gitlab_init_name:
    image        => $gitlab_tagged_image,
    volumes      => [ "${gitlab_data_dir}:/home/git/data",
                      ],
    require      => [ File[$gitlab_data_dir],
                      Docker::Run[$redis_init_name],
                      Docker::Run[$postgres_init_name],
                      ],
    # This is a dirty, dirty hack to work around a couple bugs.
    # If you pass the use_name parameter to docker docker::run name is available, but the container can't be restarted
    # (Which is bad)(Currently unreported, need to test new version)
    # The cid is esposed via the cidfile, but that is not usable for linking: https://github.com/docker/docker/issues/5186
    # So map the cid to the name and use that via chicanery
    # As this is going in a init script (sh) we can embed some sh nonsense.
    links        => [ "\$(docker inspect \$(cat ${redis_cid_file}) | python -c 'import json, sys; print json.load(sys.stdin)[0][\"Name\"][1:]'):redisio",
                      "\$(docker inspect \$(cat ${postgres_cid_file}) | python -c 'import json, sys; print json.load(sys.stdin)[0][\"Name\"][1:]'):postgresql",
                      ],
    # Gitlab listens on 22, which will conflict on just about every server
    # Bind to a specific address to allow host sshd to still listen on port 22
    ports        => [ "80:80",
                      "443:443",
                      "22:22",
                      ],
    env          => [
                     #
                     # GITLAB TUNABLES
                     #
                     
                     # UID/GID mapping
                     "USERMAP_UID=$gitlab_uid",
                     "USERMAP_GID=$gitlab_gid",

                     # SMTP Settings
                     'SMTP_ENABLED=false',

                     # General config
                     'GITLAB_PROJECTS_LIMIT=10000',
                     'NGINX_MAX_UPLOAD_SIZE=128M',
                     'GITLAB_PROJECTS_VISIBILITY=internal',
                     ],

    running      => $run,
    
  }
}

