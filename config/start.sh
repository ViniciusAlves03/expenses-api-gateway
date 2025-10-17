#!/usr/bin/env bash

# ---------------------------- VARIABLES --------------------------------------- #

GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m"

KONG_DECLARATIVE_CONFIG=${KONG_DECLARATIVE_CONFIG:-/etc/kong/kong.yaml}
# ---------------------------- FUNCTIONS --------------------------------------- #

print_message() {
	echo -e "$2$1$NC"
}

check_postgres() {
	while [ $(nc -vz ${KONG_PG_HOST} 5432; echo $?) != 0 ]; do
    print_message "PostgreSQL not start.." "${RED}"
    sleep 5
  done
  print_message "PostgreSQL started!" "${GREEN}"
}

configure_kong() {
	while [ $(nc -vz localhost 8001; echo $?) != 0 ]; do
    print_message "Kong not start.." "${RED}"
    sleep 5
  done
  print_message "Kong started!" "${GREEN}"
  deck gateway sync ${KONG_DECLARATIVE_CONFIG} --skip-consumers
  [ $? != 0 ] && {
    print_message "Problems to configure Kong on mode ${ENVIRONMENT}!" "${RED}";
    exit 1
  }
  print_message "Kong configured!" "${GREEN}"
}
# ------------------------------------------------------------------------------ #

# ------------------------------- MAIN ----------------------------------------- #

check_postgres
kong migrations bootstrap
kong migrations up
kong migrations finish
configure_kong &
rm -rf /usr/local/kong/worker_events.sock
/docker-entrypoint.sh kong docker-start

# ------------------------------------------------------------------------------ #
