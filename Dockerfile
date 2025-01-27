#install packages for build layer
FROM golang:1.19-alpine as builder

ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.2.3/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.2.3/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep d6904bc0082d6510f1e032fc1fd55ffadc9378d963e199afe0f93dd2667c0160
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep bb8ffda690b15765c396266721e45516cb3021146fd4de46f7daeda5b0d82c86

RUN apk add --no-cache git gcc make perl jq libc-dev linux-headers libgcc

#Set architecture
RUN apk --print-arch > ./architecture
RUN cp /lib/libwasmvm_muslc.$(cat ./architecture).a /lib/libwasmvm_muslc.a
RUN rm ./architecture

#build binary
WORKDIR /src
COPY . .
RUN go mod download

#install binary
RUN make install

#build main container
FROM alpine:latest
RUN apk add --update --no-cache ca-certificates curl libgcc
COPY --from=builder /go/bin/* /usr/local/bin/

#configure container
VOLUME /apps/data
WORKDIR /root/.injectived/peggo

#default command
CMD peggo orchestrator
