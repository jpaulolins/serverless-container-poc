#!/bin/sh

# Start the first process
./main &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start my server: $status"
  exit $status
fi


if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
  exec /usr/bin/aws-lambda-rie "$@"
else
  exec "$@"
fi 
