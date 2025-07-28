#!/bin/bash
# Setup Redis cluster
echo "yes" | redis-cli -a changeme --cluster create \
    127.0.0.1:6379 \
    127.0.0.1:6380 \
    127.0.0.1:6381 \
    --cluster-replicas 0
