#!/bin/bash

# Get list of pgpool-II database backend name which you want to monitor.
#
APP_NAME="$1"
PGPOOLSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

BACKENDDB="show pool_nodes"
TIME=` date +%s`

case "$APP_NAME" in
         pgpool.nodes)
                 pool_nodes=$(psql -A --field-separator=',' -t -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -c "${BACKENDDB}")
                 if [ $? -ne 0 ]; then
                    echo 3        exit
                 fi

                 sending_data=$(for backendrecord in $(echo $pool_nodes); do
                                  BACKENDID=`echo $backendrecord | awk -F, '{print $1}'`
                                  BACKENDNAME=`echo $backendrecord | awk -F, '{print $2}'`
                                  BACKENDPORT=`echo $backendrecord | awk -F, '{print $3}'`
                                  BACKEND=ID_${BACKENDID}_${BACKENDNAME}_${BACKENDPORT}
                                  BACKENDSTATE=`echo $backendrecord | awk -F, '{print $4}'`
                                  BACKENDWEIGHT=`echo $backendrecord | awk -F, '{print $5}'`
                                  BACKENDROLE=`echo $backendrecord | awk -F, '{print $6}'`
                                  echo -e "\"$HOST_NAME\" pgpool.backend.status[${BACKEND}] $TIME $BACKENDSTATE"
                                  echo -e "\"$HOST_NAME\" pgpool.backend.weight[${BACKEND}] $TIME $BACKENDWEIGHT"
                                  echo -e "\"$HOST_NAME\" pgpool.backend.role[${BACKEND}] $TIME $BACKENDROLE"
                               done
                               )
          ;;
          *)
                 echo "'$APP_NAME' did not match anything." >&2                ;;
esac

result=$(echo "$sending_data" | zabbix_sender -v -T -z localhost -i - 2>&1)
response=$(echo "$result" | awk -F ';' '$1 ~ /^info/ && match($1,/[0-9].*$/) {sum+=substr($1,RSTART,RLENGTH)} END {print sum}')
if [ -n "$response" ]; then
	echo "$response"
else
	echo "$result"
fi
