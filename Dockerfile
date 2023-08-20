FROM ubuntu:20.04
ARG NIM_VERSION=2.6.0-698150575~focal
ARG ACM_VERSION=1.3.1-723963411~focal
ARG SM_VERSION=1.1.0-721727090~focal

ARG BUILD_WITH_SECONDSIGHT=false
ARG ADD_ACM
ARG ADD_SM

ARG NGINX_CERT
ARG NGINX_KEY

# Initial setup
RUN apt-get install -y -q apt-utils && apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q build-essential git nano curl jq wget gawk \
                nginx lsb-release rsyslog systemd apt-transport-https ca-certificates netcat

# Modules download and setup

RUN mkdir -p /etc/ssl/nginx
COPY $NGINX_CERT /etc/ssl/nginx/nginx-repo.crt
COPY $NGINX_KEY /etc/ssl/nginx/nginx-repo.key

RUN printf "deb https://pkgs.nginx.com/nms/ubuntu `lsb_release -cs` nginx-plus\n" | tee /etc/apt/sources.list.d/nms.list && \
        wget -q -O /etc/apt/apt.conf.d/90pkgs-nginx https://cs.nginx.com/static/files/90pkgs-nginx && \
        cat /etc/apt/apt.conf.d/90pkgs-nginx && \
        wget -O /tmp/nginx_signing.key https://cs.nginx.com/static/keys/nginx_signing.key && \
        apt-key add /tmp/nginx_signing.key && \
        apt-get update && \
        apt-get install -y nms-instance-manager=${NIM_VERSION} && \
        curl -s http://hg.nginx.org/nginx.org/raw-file/tip/xml/en/security_advisories.xml > /usr/share/nms/cve.xml && \
        # Optional API Connectivity Manager
        if [ "${ADD_ACM}" = "true" ] ; then \
        apt-get -y install nms-api-connectivity-manager=${ACM_VERSION}; fi && \
        # Optional Security Monitoring
        if [ "${ADD_SM}" = "true" ] ; then \
        apt-get -y install nms-sm=${SM_VERSION}; fi 

COPY ./container/startNMS.sh /deployment/
RUN chmod +x /deployment/startNMS.sh


# Optional Second Sight
WORKDIR /deployment
RUN if [ "$BUILD_WITH_SECONDSIGHT" = "true" ] ; then \
        apt-get install -y -q build-essential python3-pip python3-dev python3-simplejson git nano curl && \
        pip3 install fastapi uvicorn requests clickhouse-driver python-dateutil flask && \
        touch /deployment/counter.enabled && \
        git clone https://github.com/F5Networks/SecondSight && \
        cp SecondSight/f5tt/app.py . && \
        cp SecondSight/f5tt/bigiq.py . && \
        cp SecondSight/f5tt/cveDB.py . && \
        cp SecondSight/f5tt/f5ttCH.py . && \
        cp SecondSight/f5tt/f5ttfs.py . && \
        cp SecondSight/f5tt/nms.py . && \
        cp SecondSight/f5tt/utils.py . && \
        rm -rf SecondSight; fi

WORKDIR /deployment
CMD /deployment/startNMS.sh
