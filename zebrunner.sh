#!/bin/bash

  setup() {
    cp configuration/minio/variables.env.original configuration/minio/variables.env
    sed -i "s#MINIO_ACCESS_KEY=changeit#MINIO_ACCESS_KEY=${ZBR_STORAGE_ACCESS_KEY}#g" configuration/minio/variables.env
    sed -i "s#MINIO_SECRET_KEY=changeit#MINIO_SECRET_KEY=${ZBR_STORAGE_SECRET_KEY}#g" configuration/minio/variables.env
  }

  shutdown() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    docker-compose --env-file .env -f docker-compose.yml down -v

    rm configuration/minio/variables.env
  }

  start() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    # create infra network only if not exist
    docker network inspect infra >/dev/null 2>&1 || docker network create infra

    if [[ ! -f configuration/minio/variables.env ]]; then
      cp configuration/minio/variables.env.original configuration/minio/variables.env
    fi

    docker-compose --env-file .env -f docker-compose.yml up -d
  }

  stop() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    docker-compose --env-file .env -f docker-compose.yml stop
  }

  down() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    docker-compose --env-file .env -f docker-compose.yml down
  }

  backup() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    cp configuration/minio/variables.env configuration/minio/variables.env.bak
    docker run --rm --volumes-from minio -v $(pwd)/backup:/var/backup "ubuntu" tar -czvf /var/backup/minio.tar.gz /data
  }

  restore() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    stop
    cp configuration/minio/variables.env.bak configuration/minio/variables.env
    docker run --rm --volumes-from minio -v $(pwd)/backup:/var/backup "ubuntu" bash -c "cd / && tar -xzvf /var/backup/minio.tar.gz"
    down
  }

  echo_warning() {
    echo "
      WARNING! $1"

  }

  echo_telegram() {
    echo "
      For more help join telegram channel: https://t.me/zebrunner
      "
  }

  echo_help() {
    echo "
      Usage: ./zebrunner.sh [option]
      Flags:
          --help | -h    Print help
      Arguments:
      	  start          Start container
      	  stop           Stop and keep container
      	  restart        Restart container
      	  down           Stop and remove container
      	  shutdown       Stop and remove container, clear volumes
      	  backup         Backup container
      	  restore        Restore container"
      echo_telegram
      exit 0
  }

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd ${BASEDIR}

case "$1" in
    setup)
        if [[ $ZBR_INSTALLER -eq 1 ]]; then
          setup
        else
          echo_warning "Setup procedure is supported only as part of Zebrunner Server (Community Edition)!"
          echo_telegram
        fi
        ;;
    start)
	start
        ;;
    stop)
        stop
        ;;
    restart)
        down
        start
        ;;
    down)
        down
        ;;
    shutdown)
        shutdown
        ;;
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    --help | -h)
        echo_help
        ;;
    *)
        echo "Invalid option detected: $1"
        echo_help
        exit 1
        ;;
esac

