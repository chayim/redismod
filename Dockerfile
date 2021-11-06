
ARG REDIS_VER=6.2.6
ARG ARCH=x64
ARG OSNICK=bullseye
ARG VARIANT=edge

FROM redislabs/redisai:${VARIANT}-cpu-x64-bionic as redisai
FROM redislabs/redisearch:${VARIANT} as redisearch
FROM redislabs/redisgraph:${VARIANT} as redisgraph
FROM redislabs/redistimeseries:${VARIANT} as redistimeseries
FROM redislabs/rejson:${VARIANT} as rejson
FROM redislabs/rebloom:${VARIANT} as rebloom
FROM redislabs/redisgears:${VARIANT} as redisgears
FROM redisfab/redis:${REDIS_VER}-${ARCH}-${OSNICK}

ARG REDIS_VER
ARG ARCH
ARG OSNICK
ARG VARIANT

ENV REDIS_MODULES_DIR /usr/lib/redis/modules
ENV REDISGEARS_MODULE_DIR /var/opt/redislabs/lib/modules
ENV REDISGEARS_PY_DIR /var/opt/redislabs/modules/rg

ENV REDISGEARS_DEPS git
ENV REDISGRAPH_DEPS libgomp1

RUN set -ex ;\
    apt-get -qq update ;\
    apt-get install -q -y --no-install-recommends ${REDISGRAPH_DEPS} ${REDISGEARS_DEPS} ;\
	rm -rf /var/cache/apt

RUN mkdir -p $REDIS_MODULES_DIR $REDISGEARS_PY_DIR
RUN chown -R redis:redis $REDIS_MODULES_DIR $REDISGEARS_PY_DIR

COPY --from=redisai ${REDIS_MODULES_DIR}/redisai.so ${REDIS_MODULES_DIR}/
COPY --from=redisai ${REDIS_MODULES_DIR}/backends ${REDIS_MODULES_DIR}/backends
COPY --from=redisearch ${REDIS_MODULES_DIR}/redisearch.so ${REDIS_MODULES_DIR}/
COPY --from=redisgraph ${REDIS_MODULES_DIR}/redisgraph.so ${REDIS_MODULES_DIR}/
COPY --from=redistimeseries ${REDIS_MODULES_DIR}/redistimeseries.so ${REDIS_MODULES_DIR}/
COPY --from=rejson ${REDIS_MODULES_DIR}/rejson.so ${REDIS_MODULES_DIR}/
COPY --from=rebloom ${REDIS_MODULES_DIR}/redisbloom.so ${REDIS_MODULES_DIR}/
COPY --from=redisgears --chown=redis:redis ${REDISGEARS_MODULE_DIR}/redisgears.so ${REDIS_MODULES_DIR}/
COPY --from=redisgears --chown=redis:redis ${REDISGEARS_PY_DIR}/ ${REDISGEARS_PY_DIR}/

ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 6379
CMD ["--loadmodule", "/usr/lib/redis/modules/redisai.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisearch.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisgraph.so", \
    "--loadmodule", "/usr/lib/redis/modules/redistimeseries.so", \
    "--loadmodule", "/usr/lib/redis/modules/rejson.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisbloom.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisgears.so", \
    "Plugin", "/var/opt/redislabs/modules/rg/plugin/gears_python.so"]
