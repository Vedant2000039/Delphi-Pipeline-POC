#!/bin/bash
echo "Starting deployment..."

ENV=$1

if [ -z "$ENV" ]; then
  echo "Environment not specified!"
  exit 1
fi

case $ENV in
  dev)
    echo "Deploying to Development environment..."
    # put your dev deployment commands here
    ;;
  qa)
    echo "Deploying to QA environment..."
    # put your QA deployment commands here
    ;;
  prod)
    echo "Deploying to Production environment..."
    # put your production deployment commands here
    ;;
  *)
    echo "Unknown environment: $ENV"
    exit 1
    ;;
esac

echo "Deployment finished for $ENV."
