FROM node:12.18-alpine AS builder
RUN apk add --no-cache curl build-base python3 python2 sqlite
ARG VERSION
RUN mkdir /build && \
    curl -fsSL "https://github.com/sct/overseerr/archive/${VERSION}.tar.gz" | tar xzf - -C "/build" --strip-components=1 && \
    cd /build && \
    yarn --frozen-lockfile && \
    yarn build && \
    yarn install --production --ignore-scripts --prefer-offline && \
    yarn cache clean

FROM ghcr.io/hotio/base@sha256:92ed5514d8dae810198a48454d99f182a81e65b02b6bef0a504847f52cadbe1a

EXPOSE 5055

RUN apk add --no-cache yarn

COPY --from=builder /build/dist "${APP_DIR}/dist"
COPY --from=builder /build/.next "${APP_DIR}/.next"
COPY --from=builder /build/node_modules "${APP_DIR}/node_modules"

ARG VERSION
ENV COMMIT_TAG=${VERSION}
RUN curl -fsSL "https://github.com/sct/overseerr/archive/${VERSION}.tar.gz" | tar xzf - -C "${APP_DIR}" --strip-components=1 && \
    rm -rf "${APP_DIR}/config" && ln -s "${CONFIG_DIR}/app" "${APP_DIR}/config" && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
