FROM arm32v6/alpine:3.5

RUN apk --no-cache add nodejs

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
ENV GOLANG_VERSION 1.8.1
ENV GRAFANA_VERSION 4.4.3

COPY *.patch /go-alpine-patches/

# Install Influx DB
RUN set -eux && \
   apk update && apk upgrade && \
   apk --no-cache add fontconfig && \
   apk --virtual build-deps add build-base bash go git gcc musl-dev openssl python make nodejs-dev fontconfig-dev wget tar xz curl && \
   \
   export \
      GOROOT_BOOTSTRAP="$(go env GOROOT)" \
      GOOS="$(go env GOOS)" \
      GOARCH="$(go env GOARCH)" \
      GO386="$(go env GO386)" \
      GOARM="$(go env GOARM)" \
      GOHOSTOS="$(go env GOHOSTOS)" \
      GOHOSTARCH="$(go env GOHOSTARCH)" \
   ; \
   \
   wget -O go.tgz "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz"; \
   echo '33daf4c03f86120fdfdc66bddf6bfff4661c7ca11c5da473e537f4d69b470e57 *go.tgz' | sha256sum -c -; \
   tar -C /usr/local -xzf go.tgz; \
   rm go.tgz; \
   \
   cd /usr/local/go/src; \
   for p in /go-alpine-patches/*.patch; do \
      [ -f "$p" ] || continue; \
      patch -p2 -i "$p"; \
   done; \
   ./make.bash; \
   \
   rm -rf /go-alpine-patches; \
   \
   export PATH="/usr/local/go/bin:$PATH"; \
   go version; \
   export GOPATH="/go"; \
   mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"; \
   mkdir -p /usr/share && \
   cd /usr/share && \
   curl -L https://github.com/yangxuan8282/docker-image/releases/download/2.1.1/phantomjs-2.1.1-alpine-arm.tar.xz | tar xJ && \
   ln -s /usr/share/phantomjs/phantomjs /usr/bin/phantomjs && \
   mkdir -p $GOPATH/src/github.com/grafana && cd $GOPATH/src/github.com/grafana && \
   git clone --depth=1 https://github.com/grafana/grafana.git -b v${GRAFANA_VERSION} && \
   cd $GOPATH/src/github.com/grafana/grafana && \
   npm install -g yarn@0.19.0 && \
   npm install -g grunt-cli@1.2.0 && \
   go run build.go setup && \
   go run build.go build && \
   yarn install --pure-lockfile && \
   npm run build && \
   npm uninstall -g yarn && \
   npm uninstall -g grunt-cli && \
   npm cache clear && \
   mv ./bin/grafana-server ./bin/grafana-cli /bin/ && \
   mkdir -p /etc/grafana/json /var/lib/grafana/plugins /var/log/grafana /usr/share/grafana && \
   mv ./public_gen /usr/share/grafana/public && \
   mv ./conf /usr/share/grafana/conf && \
   apk del build-deps && cd / && rm -rf /var/cache/apk/* /usr/local/share/.cache $GOPATH /usr/local/go

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

VOLUME ["/var/lib/grafana", "/var/lib/grafana/plugins", "/var/log/grafana"]
EXPOSE 3000

ENV INFLUXDB_HOST localhost
ENV INFLUXDB_PORT 8086
ENV INFLUXDB_PROTO http
ENV INFLUXDB_USER grafana
ENV INFLUXDB_PASS password
ENV GRAFANA_USER admin
ENV GRAFANA_PASS password

COPY grafana.ini /usr/share/grafana/conf/defaults.ini
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/entrypoint.sh"]
