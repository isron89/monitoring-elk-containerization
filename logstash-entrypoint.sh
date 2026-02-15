#!/bin/bash
set -e

echo "Waiting for Elasticsearch to be fully ready..."
for i in {1..60}; do
  if curl -s -u logstash_writer:pertamina http://elasticsearch:9200/_cluster/health 2>/dev/null | grep -q '"status":"green"\|"status":"yellow"'; then
    echo "Elasticsearch is ready!"
    break
  fi
  echo "Elasticsearch is not ready yet - sleeping (attempt $i/60)"
  sleep 2
done

echo "Testing Elasticsearch connectivity with logstash_writer credentials..."
if ! curl -s -u logstash_writer:pertamina http://elasticsearch:9200/ 2>/dev/null | grep -q "cluster_name"; then
  echo "ERROR: Cannot connect to Elasticsearch with logstash_writer credentials!"
  exit 1
fi
echo "Elasticsearch connection test successful!"

echo "Verifying Kafka is accessible..."
for i in {1..30}; do
  if timeout 2 bash -c "echo > /dev/tcp/kafka/9092" 2>/dev/null; then
    echo "Kafka is accessible!"
    break
  fi
  echo "Waiting for Kafka (attempt $i/30)"
  sleep 2
done

echo "Waiting for all services to stabilize..."
sleep 15

echo "Starting Logstash..."
exec /usr/local/bin/docker-entrypoint
