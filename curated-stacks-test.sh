#!/bin/bash

API="https://recommender.api.openshift.io/api/v1"

BOOSTER="vertx-http-booster"

echo "Testing" $BOOSTER

# Cleanup before cloning the repo.
if [ -d "$BOOSTER" ]; then
    echo "Warning:"
    echo "The directory $BOOSTER exists which needs to be cleaned up."
    read -r -p  "Should I remove $BOOSTER and continue testing? [y/N]" response
    echo $response
    if [[ "$response" != "y" ]]; then
        exit
    fi
    rm -rf $BOOSTER
    echo "Removed $BOOSTER"
fi
git clone https://github.com/openshiftio-vertx-boosters/$BOOSTER
cd $BOOSTER

STACK_ID=$(curl -sH "Authorization: Bearer $OSIO_TOKEN" -F "manifest[]=@./pom.xml" $API/stack-analyses | jq .id)
echo "Analysis started. Request ID: $STACK_ID"

# Polling stack-anaylsis every minute
while : ; do
  STACK_REQUEST_RESPONSE=$(curl -sH "Authorization: Bearer $OSIO_TOKEN" $API/stack-analyses/$STACK_ID)
  echo STACK_REQUEST_RESPONSE = $STACK_REQUEST_RESPONSE
  ERROR=$(echo $STACK_REQUEST_RESPONSE | jq .error)
  if [ "$ERROR" == "" ]; then
      echo "stack analysis for $STACK_ID done"
      break
  fi
  echo "stack analysis with id: $STACK_ID in progress."
  echo "trying again in:"
  for i in {60..1};do echo -ne "$i\033[0K\r" && sleep 1; done
done

#TOOD write the actual test

