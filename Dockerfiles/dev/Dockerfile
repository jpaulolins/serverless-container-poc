FROM golang:1.15 AS build
WORKDIR /teste
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o main

FROM public.ecr.aws/c2t6n2x5/serverlessish:2 AS s

#FROM gcr.io/distroless/static

FROM alpine

RUN apk add --no-cache bash

ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie

RUN chmod 755 /usr/bin/aws-lambda-rie
COPY ./entry.sh /
RUN chmod 755 /entry.sh

COPY --from=s /opt/extensions/serverlessish /opt/extensions/serverlessish
COPY --from=build /teste/main /main

ENV PORT=8081 

ENTRYPOINT ["/entry.sh"]

