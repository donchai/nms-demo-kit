#!/bin/bash

#nginx -g "daemon off;"

/bin/su -s /bin/sh -c "/usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_mhz 2000000 total_xml_memory 307200000 total_umu_max_size 3129344 sys_max_account_id 1024 no_static_config 2>&1 >> /var/log/app_protect/bd-socket-plugin.log &" nginx
nginx

sleep 2

PARM="--server-grpcport $NIM_GRPC_PORT --server-host $NIM_HOST"

if [[ ! -z "$NIM_INSTANCEGROUP" ]]; then
   PARM="${PARM} --instance-group $NIM_INSTANCEGROUP"
fi

if [[ ! -z "$NIM_TAGS" ]]; then
   PARM="${PARM} --tags $NIM_TAGS"
fi

# Enable NGINX App Protect WAF Status Reporting
echo -e "

nginx_app_protect:
  # Report interval for NGINX App Protect details - the frequency the NGINX Agent checks NGINX App Protect for changes.
  report_interval: 15s
" >> /etc/nginx-agent/nginx-agent.conf

nginx-agent $PARM
