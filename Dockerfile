FROM bluedata/centos7:latest

## Installing and configuring PostgresSQL Database

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum -y install postgresql96-server postgresql96-contrib && \
    /usr/pgsql-9.6/bin/postgresql96-setup initdb

COPY pg_hba.conf /var/lib/pgsql/9.6/data/pg_hba.conf

RUN systemctl enable postgresql-9.6 && \
    systemctl start postgresql-9.6 && \
    echo postgres:postgres | chpasswd && \
    sudo -Hu postgres createuser concourse && \
    sudo -Hu postgres psql -c "ALTER USER concourse WITH ENCRYPTED password 'concourse';" && \
    sudo -Hu postgres psql -c "CREATE DATABASE concourse OWNER concourse;"


## Downloading and installing Concourse CI

RUN wget https://github.com/concourse/concourse/releases/download/v3.4.1/concourse_linux_amd64 -O /usr/bin/concourse && \
    wget https://github.com/concourse/concourse/releases/download/v3.4.1/fly_linux_amd64 -O /usr/bin/fly && \
    chmod +x /usr/bin/concourse /usr/bin/fly

## Generate and Setup RSA Keys
RUN mkdir /opt/concourse && \
    ssh-keygen -t rsa -q -N '' -f /opt/concourse/session_signing_key && \
    ssh-keygen -t rsa -q -N '' -f /opt/concourse/tsa_host_key && \
    ssh-keygen -t rsa -q -N '' -f /opt/concourse/worker_key && \
    cp /opt/concourse/worker_key.pub /opt/concourse/authorized_worker_keys


## Configuring Environment and Systemd Service

COPY web.env /opt/concourse/
COPY worker.env /opt/concourse

RUN chmod 600 /opt/concourse/*.env && \
    adduser --system concourse && \
    chown -R concourse:concourse /opt/concourse

COPY concourse-worker.service /etc/systemd/system/concourse-worker.service
COPY concourse-web.service /etc/systemd/system/concourse-web.service
