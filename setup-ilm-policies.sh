#!/bin/bash
# Setup ILM Policies for different environments

ES_URL="http://localhost:9200"
ES_USER="elastic"
ES_PASS="pertamina"

echo "==========================================="
echo "Setting up ILM Policies"
echo "==========================================="
echo ""

# Create Dev Policy (7 days retention)
echo "Creating Dev Policy (7 days retention)..."
curl -X PUT -u $ES_USER:$ES_PASS "$ES_URL/_ilm/policy/mypertamina-dev-policy" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

echo ""
echo "✓ Dev Policy created (delete after 7 days)"
echo ""

# Create Staging Policy (30 days retention)
echo "Creating Staging Policy (30 days retention)..."
curl -X PUT -u $ES_USER:$ES_PASS "$ES_URL/_ilm/policy/mypertamina-staging-policy" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "set_priority": {
            "priority": 50
          },
          "readonly": {}
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

echo ""
echo "✓ Staging Policy created (delete after 30 days)"
echo ""

# Create Production Policy (90 days retention)
echo "Creating Production Policy (90 days retention)..."
curl -X PUT -u $ES_USER:$ES_PASS "$ES_URL/_ilm/policy/mypertamina-prod-policy" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "set_priority": {
            "priority": 50
          },
          "readonly": {}
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

echo ""
echo "✓ Production Policy created (delete after 90 days)"
echo ""

# Create Index Templates
echo "Creating Index Templates..."
echo ""

# Dev Template
echo "Creating template for Dev indices..."
curl -X PUT -u $ES_USER:$ES_PASS "$ES_URL/_index_template/mypertamina-dev-template" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["mypertamina-dev-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "index.lifecycle.name": "mypertamina-dev-policy",
      "index.lifecycle.rollover_alias": "mypertamina-dev"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "tranTime": { "type": "date" },
        "executeTime": { "type": "long" },
        "serverName": { "type": "keyword" },
        "serverPort": { "type": "integer" },
        "reqMethod": { "type": "keyword" },
        "uri": { "type": "keyword" },
        "url": { "type": "text" },
        "respHttpStatus": { "type": "integer" },
        "respStatus": { "type": "keyword" },
        "service": { "type": "keyword" },
        "userId": { "type": "keyword" },
        "customerId": { "type": "keyword" },
        "eventCode": { "type": "keyword" },
        "source": { "type": "keyword" },
        "source_topic": { "type": "keyword" },
        "clientIp": { "type": "ip" },
        "traceId": { "type": "keyword" },
        "spanId": { "type": "keyword" }
      }
    }
  }
}'

echo ""
echo "✓ Dev template created"
echo ""

# Staging Template
echo "Creating template for Staging indices..."
curl -X PUT -u $ES_USER:$ES_PASS "$ES_URL/_index_template/mypertamina-staging-template" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["mypertamina-staging-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "index.lifecycle.name": "mypertamina-staging-policy",
      "index.lifecycle.rollover_alias": "mypertamina-staging"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "tranTime": { "type": "date" },
        "executeTime": { "type": "long" },
        "serverName": { "type": "keyword" },
        "serverPort": { "type": "integer" },
        "reqMethod": { "type": "keyword" },
        "uri": { "type": "keyword" },
        "url": { "type": "text" },
        "respHttpStatus": { "type": "integer" },
        "respStatus": { "type": "keyword" },
        "service": { "type": "keyword" },
        "userId": { "type": "keyword" },
        "customerId": { "type": "keyword" },
        "eventCode": { "type": "keyword" },
        "source": { "type": "keyword" },
        "source_topic": { "type": "keyword" },
        "clientIp": { "type": "ip" },
        "traceId": { "type": "keyword" },
        "spanId": { "type": "keyword" }
      }
    }
  }
}'

echo ""
echo "✓ Staging template created"
echo ""

# Production Template
echo "Creating template for Production indices..."
curl -X PUT -u $ES_USER:$ES_PASS "$ES_URL/_index_template/mypertamina-prod-template" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["mypertamina-prod-*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "index.lifecycle.name": "mypertamina-prod-policy",
      "index.lifecycle.rollover_alias": "mypertamina-prod"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "tranTime": { "type": "date" },
        "executeTime": { "type": "long" },
        "serverName": { "type": "keyword" },
        "serverPort": { "type": "integer" },
        "reqMethod": { "type": "keyword" },
        "uri": { "type": "keyword" },
        "url": { "type": "text" },
        "respHttpStatus": { "type": "integer" },
        "respStatus": { "type": "keyword" },
        "service": { "type": "keyword" },
        "userId": { "type": "keyword" },
        "customerId": { "type": "keyword" },
        "eventCode": { "type": "keyword" },
        "source": { "type": "keyword" },
        "source_topic": { "type": "keyword" },
        "clientIp": { "type": "ip" },
        "traceId": { "type": "keyword" },
        "spanId": { "type": "keyword" }
      }
    }
  }
}'

echo ""
echo "✓ Production template created"
echo ""

echo "==========================================="
echo "✅ ILM Setup Complete!"
echo "==========================================="
echo ""
echo "ILM Policies created:"
echo "  📋 mypertamina-dev-policy      → Delete after 7 days"
echo "  📋 mypertamina-staging-policy  → Delete after 30 days"  
echo "  📋 mypertamina-prod-policy     → Delete after 90 days"
echo ""
echo "Index Templates created:"
echo "  📄 mypertamina-dev-template"
echo "  📄 mypertamina-staging-template"
echo "  📄 mypertamina-prod-template"
echo ""
echo "Lifecycle phases:"
echo ""
echo "🔥 HOT Phase (All environments):"
echo "   - Active data, writable"
echo "   - Rollover after 1 day or 50GB"
echo ""
echo "🌡️  WARM Phase (Staging: 7d, Prod: 7d):"
echo "   - Read-only"
echo "   - Lower priority"
echo ""
echo "❄️  COLD Phase (Production only: 30d):"
echo "   - Archived data"
echo "   - Lowest priority"
echo ""
echo "🗑️  DELETE Phase:"
echo "   - Dev: 7 days"
echo "   - Staging: 30 days"
echo "   - Production: 90 days"
echo ""
echo "Next step: Restart Logstash"
echo "  docker-compose restart logstash"
echo ""
