#!/bin/bash
set -e

echo "Waiting for Elasticsearch to be ready..."
until curl -s -u elastic:pertamina http://elasticsearch:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
  echo "Elasticsearch is unavailable - sleeping"
  sleep 5
done

echo "Elasticsearch is ready!"

echo "Creating kibana_system user..."
curl -X POST -u elastic:pertamina "http://elasticsearch:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "pertamina"
  }'

echo ""
echo "Kibana user password set successfully!"

echo "Creating logstash_writer role with proper permissions..."
curl -X POST -u elastic:pertamina "http://elasticsearch:9200/_security/role/logstash_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["manage_index_templates", "monitor", "manage_ilm"],
    "indices": [
      {
        "names": ["telemetry-*", "logstash-*"],
        "privileges": ["write", "create", "create_index", "manage", "manage_ilm"]
      }
    ]
  }'

echo ""
echo "Logstash role created successfully!"

echo "Creating logstash_writer user..."
curl -X POST -u elastic:pertamina "http://elasticsearch:9200/_security/user/logstash_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "pertamina",
    "roles": ["logstash_writer"],
    "full_name": "Logstash Writer User"
  }'

echo ""
echo "Logstash user created successfully!"
echo "Setup complete!"
