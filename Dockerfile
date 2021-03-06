FROM registry.access.redhat.com/rhel7:latest

RUN groupadd -r rabbitmq && useradd -r -d /var/lib/rabbitmq -m -g rabbitmq rabbitmq

#erlang + rabbitmq
ENV RABBIT_VERSION 3.6.4
RUN rpm -Uvh --replacepkgs https://www.rabbitmq.com/releases/erlang/erlang-18.3-1.el7.centos.x86_64.rpm && \
    rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc && \
    curl -s "http://www.rabbitmq.com/releases/rabbitmq-server/v$RABBIT_VERSION/rabbitmq-server-$RABBIT_VERSION-1.noarch.rpm" > "/tmp/rabbitmq-server-$RABBIT_VERSION-1.noarch.rpm" && \
    yum -y install "/tmp/rabbitmq-server-$RABBIT_VERSION-1.noarch.rpm" --setopt=rhel-7-server-rt-beta-rpms.skip_if_unavailable=true && \
    yum -y clean all && \
    rm "/tmp/rabbitmq-server-$RABBIT_VERSION-1.noarch.rpm"

# Setup gosu for easier command execution 
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.6/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.6/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

#set perms/mounts for rabbit
RUN mkdir -p /var/lib/rabbitmq /etc/rabbitmq \
&& chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /etc/rabbitmq \
&& chmod 777 /var/lib/rabbitmq /etc/rabbitmq
VOLUME /var/lib/rabbitmq

#enable management console with login of admin:minos-ops
RUN echo '[ { rabbit, [ { loopback_users, [ ] }, {default_user,<<"admin">>}, {default_pass,<<"minos-ops">>} ] } ].' > /etc/rabbitmq/rabbitmq.config

#logs to stdout
ENV RABBITMQ_LOGS=- RABBITMQ_SASL_LOGS=-

ENV PATH /usr/lib/rabbitmq/bin:$PATH
ENV HOME /var/lib/rabbitmq

#useful plugins
#the plugin installer does not send correct signals for docker apparently hence the 2>&1
RUN rabbitmq-plugins enable --offline rabbitmq_management rabbitmq_shovel rabbitmq_shovel_management 2>&1

EXPOSE 15671 15672 4369 5671 5672 25672

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
 
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rabbitmq-server"]
