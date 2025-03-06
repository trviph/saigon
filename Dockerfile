FROM golang:1.24-alpine AS build

WORKDIR /
# Download pre-built Hugo binary from GitHub
ENV HUGO_VERSION=0.145.0
RUN apk add --update openssl \
    && wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_withdeploy_${HUGO_VERSION}_Linux-64bit.tar.gz \
    && tar xvzf ./hugo_extended_withdeploy_${HUGO_VERSION}_Linux-64bit.tar.gz

FROM scratch AS run

ENV HUGO_ENVIRONMENT=production
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /hugo /hugo

WORKDIR /hugo-server

COPY . .

CMD [ "/hugo", "server", "--renderToMemory", "--minify" ]
