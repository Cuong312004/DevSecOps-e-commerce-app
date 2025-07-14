#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

mkdir -p ../reports

echo -e "${GREEN}Starting Checkov scan for staging...${NC}"

checkov -d ../terraform/envs/staging --no-color > ../reports/checkov-staging.txt

echo -e "${GREEN}Report saved to reports/checkov-staging.txt${NC}"

if [ -d "../terraform/envs/production" ]; then
  echo -e "${GREEN}Starting Checkov scan for production...${NC}"
  checkov -d ../terraform/envs/production --no-color > ../reports/checkov-production.txt
  echo -e "${GREEN}Report saved to reports/checkov-production.txt${NC}"
fi
