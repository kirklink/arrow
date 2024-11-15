ARG DART_VARIANT=3
ARG BUILD_ENV

FROM dart:${DART_VARIANT} AS base


# BUILD_ENV = production
FROM base AS environment-production
ENV BUILD_ENV=production


# BUILD_ENV = development
FROM base AS environment-development
ENV BUILD_ENV=development


FROM environment-${BUILD_ENV} AS final
RUN echo "Building for ${BUILD_ENV} environment"

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to 
# the Docker socket if "overrideCommand": false is set in devcontainer.json. 
# The script will also execute CMD if you need to alter startup behaviors.
# ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
# CMD [ "sleep", "infinity" ]