#!/bin/bash
response="$(aws eks list-clusters --region us-west-2 --output text | grep -i dominion-cluster 2>&1)" 
if [[ $? -eq 0 ]]; then
    echo "Success: Dominion-cluster exist"
else
    echo "Error: Dominion-cluster does not exist"
fi