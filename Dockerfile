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

LABEL maintainer="Thomas Queste <tom@tomsquest.com>" \
      org.label-schema.name="Radicale Docker Image" \
      org.label-schema.description="Enhanced Docker image for Radicale, the CalDAV/CardDAV server" \
      org.label-schema.url="https://github.com/Kozea/Radicale" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$COMMIT_ID \
      org.label-schema.vcs-url="https://github.com/tomsquest/docker-radicale" \
      org.label-schema.schema-version="1.0"

RUN install_packages curl \
        git \
        openssh-server \
        gosu \
        wget \
        python3-tz \
        python3-pip \
        python3
RUN install_packages gcc \
        python3-dev \
        libffi-dev \
        libc-dev-bin
RUN python3 -m pip install --upgrade pip\
    && python3 -m pip install radicale==$VERSION passlib[becrypt]
RUN apt-get remove gcc python3-dev libffi-dev libc-dev-bin -y
RUN addgroup --gid $BUILD_GID radicale\
    && adduser --disabled-password --disabled-login --shell /bin/false --no-create-home --uid 2999 --ingroup radicale radicale \
    && mkdir -p /config /data \
    && chmod -R 770 /data \
    && chown -R radicale:radicale /data \
    && rm -fr /root/.cache

COPY config /config/config

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail http://localhost:5232 || exit 1
VOLUME /config /data
EXPOSE 5232

COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["radicale", "--config", "/config/config"]
