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

echo "Starting test at: "$(date)
STACK_ID=$(curl -sH "Authorization: Bearer $OSIO_TOKEN" -F "manifest[]=@./pom.xml" $API/stack-analyses | jq -r .id)
echo "Analysis started. Request ID: $STACK_ID"

# Polling stack-anaylsis every minute
ATTEMPT=0
while : ; do
  ATTEMPT=$((ATTEMPT + 1))
  STACK_REQUEST_RESPONSE=$(curl -sH "Authorization: Bearer $OSIO_TOKEN" $API/stack-analyses/$STACK_ID)
  ERROR=$(echo $STACK_REQUEST_RESPONSE | jq .error)
  echo err $ERROR
  echo resp $STACK_REQUEST_RESPONSE
  if [[ $ERROR == "null" ]]; then
      echo "stack analysis for $STACK_ID done"
      break
  fi
  echo "stack analysis with id: $STACK_ID in progress."
  echo "This was the attempt nr.: $ATTEMPT. Trying again in:"
  for i in {20..1};do echo -ne "$i\033[0K\r" && sleep 1; done
done
echo "stack analysis done at " $(date)

SIMILAR_STACKS=$(echo $STACK_REQUEST_RESPONSE | jq .recommendation.recommendations.similar_stacks)
echo "SIMILAR_STACKS:" $SIMILAR_STACKS
if [ "$SIMILAR_STACKS" != "[]" ]; then
    echo "Failure:" $BOOSTER "shouldn't have any recommendations."
fi

echo "Done. Exit."

