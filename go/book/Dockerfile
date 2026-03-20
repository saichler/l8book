FROM saichler/builder:latest AS build

COPY main.go /home/src/github.com/saichler/build/main.go
RUN go mod init
RUN GOPROXY=direct GOPRIVATE=github.com go mod tidy
RUN go build -o book

FROM saichler/book-security:latest AS final
COPY --from=build /home/src/github.com/saichler/build/book /home/run/book
COPY ./web /home/run/web

ENTRYPOINT ["/home/run/book"]