#!/bin/bash
elasticdump \
  --input='http://address.fqdn.com:9200/index' \
  --output="$HOME/directory/file.json" \
  --type=data \
  --concurrency 1 \
  --limit 500 

#  --searchBody='{"query":{"range":{"@timestamp":{"gte":"2020-04-11T04:31:51","lt":"2025-08-04T12:00:00"}}}}'