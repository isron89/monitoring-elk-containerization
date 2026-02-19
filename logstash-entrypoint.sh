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
# Extract first Kafka broker from KAFKA_BOOTSTRAP_SERVERS
KAFKA_HOST=$(echo "$KAFKA_BOOTSTRAP_SERVERS" | cut -d',' -f1 | cut -d':' -f1)
KAFKA_PORT=$(echo "$KAFKA_BOOTSTRAP_SERVERS" | cut -d',' -f1 | cut -d':' -f2)

# Default to 9092 if port not specified
if [ -z "$KAFKA_PORT" ] || [ "$KAFKA_PORT" = "$KAFKA_HOST" ]; then
  KAFKA_PORT=9092
fi

echo "Checking connectivity to Kafka at $KAFKA_HOST:$KAFKA_PORT..."
for i in {1..30}; do
  if timeout 2 bash -c "echo > /dev/tcp/$KAFKA_HOST/$KAFKA_PORT" 2>/dev/null; then
    echo "Kafka is accessible!"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "WARNING: Could not verify Kafka connectivity after 30 attempts."
    echo "Proceeding anyway - Logstash will retry connections automatically."
  else
    echo "Waiting for Kafka (attempt $i/30)"
    sleep 2
  fi
done

echo "Waiting for all services to stabilize..."
sleep 15

echo "Starting Logstash..."
exec /usr/local/bin/docker-entrypoint
