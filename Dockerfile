FROM golang:1.24-alpine AS build
WORKDIR /server
ENV HUGO_ENVIRONMENT=production
RUN apk add --update --no-cache alpine-sdk
RUN CGO_ENABLED=1 go install -tags extended github.com/gohugoio/hugo@latest
COPY . .
CMD [ "hugo", "server", "--renderToMemory", "--minify", "--port=10000", "--bind=localhost" ]
