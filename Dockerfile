FROM bitnami/minideb:bullseye

ARG COMMIT_ID
ENV COMMIT_ID ${COMMIT_ID}

ARG VERSION
ENV VERSION ${VERSION:-3.1.8}

ARG BUILD_UID
ENV BUILD_UID ${BUILD_UID:-2999}

ARG BUILD_GID
ENV BUILD_GID ${BUILD_GID:-2999}

ARG TAKE_FILE_OWNERSHIP
ENV TAKE_FILE_OWNERSHIP ${TAKE_FILE_OWNERSHIP:-true}

LABEL maintainer="Friso Dubach <ffcdubach@gmail.com>" \
      org.label-schema.name="Radicale w/ DecSync Docker Image" \
      org.label-schema.description="Enhanced Docker imageb based on Minideb for Radicale, the CalDAV/CardDAV server, w/ DecSync plugin" \
      org.label-schema.url="https://github.com/Kozea/Radicale" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$COMMIT_ID \
      org.label-schema.vcs-url="https://github.com/frisodubach/docker-radicale-decsync" \
      org.label-schema.schema-version="1.0"

RUN install_packages curl \
        git \
        openssh-client \
        gosu \
        wget \
        python3-minimal \
        python3-tz \
        python3-pip

RUN install_packages gcc \
        python3-dev \
        libffi-dev \
        libc-dev-bin

RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install radicale==$VERSION passlib[becrypt] \
    && pip3 install radicale_storage_decsync
RUN mkdir -p /data/decsync

RUN apt-get remove --purge -y gcc python3-dev libffi-dev libc-dev-bin gcc-10 cpp-10 libgcc-10-dev linux-libc-dev
RUN apt-get -y autoremove
RUN rm -rf /var/cache/apt/archives /var/lib/apt/lists

RUN addgroup --gid $BUILD_GID radicale
RUN adduser --uid $BUILD_UID --disabled-password --disabled-login --shell /bin/false --no-create-home --ingroup radicale radicale
RUN mkdir -p /config /data
RUN chmod -R 770 /data
RUN chown -R radicale:radicale /data

COPY config /config/config

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail http://localhost:5232 || exit 1
VOLUME /config /data
EXPOSE 5232

COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["radicale", "--config", "/config/config"]
