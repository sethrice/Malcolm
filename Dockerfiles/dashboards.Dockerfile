FROM opensearchproject/opensearch-dashboards:2.13.0

LABEL maintainer="malcolm@inl.gov"
LABEL org.opencontainers.image.authors='malcolm@inl.gov'
LABEL org.opencontainers.image.url='https://github.com/cisagov/Malcolm'
LABEL org.opencontainers.image.documentation='https://github.com/cisagov/Malcolm/blob/master/README.md'
LABEL org.opencontainers.image.source='https://github.com/cisagov/Malcolm'
LABEL org.opencontainers.image.vendor='Cybersecurity and Infrastructure Security Agency'
LABEL org.opencontainers.image.title='ghcr.io/cisagov/malcolm/opensearch-dashboards'
LABEL org.opencontainers.image.description='Malcolm container providing OpenSearch Dashboards'

ARG DEFAULT_UID=1000
ARG DEFAULT_GID=1000
ENV DEFAULT_UID $DEFAULT_UID
ENV DEFAULT_GID $DEFAULT_GID
ENV PUSER "opensearch-dashboards"
ENV PGROUP "opensearch-dashboards"
ENV PUSER_PRIV_DROP true

ENV TERM xterm

ENV TINI_VERSION v0.19.0
ENV OSD_TRANSFORM_VIS_VERSION 2.13.0

ARG NODE_OPTIONS="--max_old_space_size=4096"
ENV NODE_OPTIONS $NODE_OPTIONS

ENV PATH="/data:${PATH}"

USER root

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
ADD https://github.com/lguillaud/osd_transform_vis/releases/download/$OSD_TRANSFORM_VIS_VERSION/transformVis-$OSD_TRANSFORM_VIS_VERSION.zip /tmp/transformVis.zip

RUN yum upgrade -y && \
    yum install -y curl-minimal psmisc findutils util-linux openssl rsync python3 zip unzip && \
    yum remove -y vim-* && \
    usermod -a -G tty ${PUSER} && \
    # Malcolm manages authentication and encryption via NGINX reverse proxy
    /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin remove securityDashboards --allow-root && \
    cd /tmp && \
        # unzip transformVis.zip opensearch-dashboards/transformVis/opensearch_dashboards.json opensearch-dashboards/transformVis/package.json && \
        # sed -i "s/2\.12\.0/2\.13\.0/g" opensearch-dashboards/transformVis/opensearch_dashboards.json && \
        # sed -i "s/2\.12\.0/2\.13\.0/g" opensearch-dashboards/transformVis/package.json && \
        # zip transformVis.zip opensearch-dashboards/transformVis/opensearch_dashboards.json opensearch-dashboards/transformVis/package.json && \
        cd /usr/share/opensearch-dashboards/plugins && \
        /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin install file:///tmp/transformVis.zip --allow-root && \
        rm -rf /tmp/transformVis /tmp/opensearch-dashboards && \
    chown --silent -R ${PUSER}:${PGROUP} /usr/share/opensearch-dashboards && \
    chmod +x /usr/bin/tini && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY --chmod=755 shared/bin/docker-uid-gid-setup.sh /usr/local/bin/
COPY --chmod=755 shared/bin/service_check_passthrough.sh /usr/local/bin/
COPY --from=ghcr.io/mmguero-dev/gostatic --chmod=755 /goStatic /usr/bin/goStatic
COPY --chmod=755 dashboards/scripts/docker_entrypoint.sh /usr/local/bin/
ADD dashboards/opensearch_dashboards.yml /usr/share/opensearch-dashboards/config/opensearch_dashboards.orig.yml
ADD dashboards/scripts/docker_entrypoint.sh /usr/local/bin/
ADD scripts/malcolm_utils.py /usr/local/bin/

ENTRYPOINT ["/usr/bin/tini", \
            "--", \
            "/usr/local/bin/docker-uid-gid-setup.sh", \
            "/usr/local/bin/service_check_passthrough.sh", \
            "-s", "dashboards", \
            "/usr/local/bin/docker_entrypoint.sh"]

CMD ["/usr/share/opensearch-dashboards/opensearch-dashboards-docker-entrypoint.sh"]

EXPOSE 5601

# to be populated at build-time:
ARG BUILD_DATE
ARG MALCOLM_VERSION
ARG VCS_REVISION
ENV BUILD_DATE $BUILD_DATE
ENV MALCOLM_VERSION $MALCOLM_VERSION
ENV VCS_REVISION $VCS_REVISION

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$MALCOLM_VERSION
LABEL org.opencontainers.image.revision=$VCS_REVISION
