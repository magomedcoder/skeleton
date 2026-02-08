FROM alpine:3.23 AS builder

ARG GOLANG_VERSION=1.25.3
ARG PROTOC_VERSION=30.2

RUN apk update && \
    apk add --no-cache make openssh bash musl-dev openssl-dev ca-certificates unzip && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*

RUN wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -O /tmp/protoc.zip && \
    unzip -o /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip

RUN wget https://go.dev/dl/go$GOLANG_VERSION.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz && \
    rm go$GOLANG_VERSION.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV PATH=$PATH:/go/bin

RUN mkdir /usr/src

RUN mkdir /usr/src/legion

WORKDIR /usr/src/legion

COPY ../.. ./

RUN make install

RUN make gen-go-proto

RUN make build && make build-runner

FROM alpine:3.23

COPY --from=builder /usr/src/legion/build /usr/bin

RUN mkdir /etc/legion

RUN mkdir /var/log/legion

RUN chmod 775 /var/log/legion

EXPOSE 50051 50052

CMD ["sh"]
