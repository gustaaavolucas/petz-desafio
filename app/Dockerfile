FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY . .
RUN go mod init helloapp || true
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /bin/app main.go

FROM gcr.io/distroless/base-debian12
WORKDIR /app
COPY --from=builder /bin/app /app/app
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/app"]
