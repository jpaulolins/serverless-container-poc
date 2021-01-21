FROM golang:1.15 AS build
WORKDIR /example
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o main

FROM public.ecr.aws/c2t6n2x5/serverlessish:2 AS s

FROM gcr.io/distroless/static


COPY --from=s /opt/extensions/serverlessish /opt/extensions/serverlessish
COPY --from=build /example/main /main

ENV PORT=8081 

ENTRYPOINT ["/main"]
