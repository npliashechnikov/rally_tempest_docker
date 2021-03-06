FROM rallyforge/rally:latest
MAINTAINER Oleksii Butenko <obutenko@mirantis.com>

WORKDIR /var/lib
USER root
RUN git clone https://git.openstack.org/openstack/tempest -b 16.1.0 && \
    pip install tempest==16.1.0
    
WORKDIR /home/rally

COPY skip_lists /var/lib/skip_lists
COPY tempest_conf /var/lib/tempest_conf
COPY run_tempest.sh /usr/bin/run-tempest

ENTRYPOINT ["run-tempest"]
