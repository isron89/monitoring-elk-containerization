#!/bin/bash
# Script to create Kibana data views based on topics and timestamps

KIBANA_URL="http://localhost:5601"
ES_USER="elastic"
ES_PASSWORD="pertamina"

echo "==========================================="
echo "Topic-Based Data View Setup"
echo "==========================================="
echo ""

# Check Kibana connectivity
echo "Checking Kibana connection..."
KIBANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -u $ES_USER:$ES_PASSWORD "$KIBANA_URL/api/status")

if [ "$KIBANA_STATUS" != "200" ]; then
    echo "❌ Cannot connect to Kibana (Status: $KIBANA_STATUS)"
    exit 1
fi
echo "✓ Kibana is accessible"
echo ""

# Function to create data view
create_data_view() {
    local name=$1
    local pattern=$2
    local title=$3
    
    echo "Creating data view: $title..."
    
    # Check if exists
    EXISTING=$(curl -s -u $ES_USER:$ES_PASSWORD \
      -H "kbn-xsrf: true" \
      "$KIBANA_URL/api/data_views" | grep -o "\"title\":\"$pattern\"" || echo "")
    
    if [ -n "$EXISTING" ]; then
        echo "  ⚠ Already exists, refreshing..."
        
        # Get ID and refresh
        DATAVIEW_ID=$(curl -s -u $ES_USER:$ES_PASSWORD \
          -H "kbn-xsrf: true" \
          "$KIBANA_URL/api/data_views" | grep -B2 "\"title\":\"$pattern\"" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        if [ -n "$DATAVIEW_ID" ]; then
            curl -s -u $ES_USER:$ES_PASSWORD \
              -X POST \
              -H "kbn-xsrf: true" \
              -H "Content-Type: application/json" \
              "$KIBANA_URL/api/data_views/data_view/$DATAVIEW_ID/fields" \
              -d '{"refresh_fields": true}' > /dev/null
            echo "  ✓ Refreshed"
        fi
    else
        RESPONSE=$(curl -s -u $ES_USER:$ES_PASSWORD \
          -X POST \
          -H "kbn-xsrf: true" \
          -H "Content-Type: application/json" \
          "$KIBANA_URL/api/data_views/data_view" \
          -d "{
            \"data_view\": {
              \"title\": \"$pattern\",
              \"name\": \"$title\",
              \"timeFieldName\": \"@timestamp\"
            }
          }")
        
        if echo "$RESPONSE" | grep -q '"id"'; then
            echo "  ✓ Created successfully"
        else
            echo "  ❌ Failed to create"
        fi
    fi
}

# Create individual topic data views
echo "Creating topic-specific data views..."
echo ""

create_data_view "dev-dataview" "mypertamina-dev-*" "MyPertamina Dev"
create_data_view "staging-dataview" "mypertamina-staging-*" "MyPertamina Staging"
create_data_view "prod-dataview" "mypertamina-prod-*" "MyPertamina Production"

echo ""
echo "Creating combined data view..."
echo ""

create_data_view "all-topics-dataview" "mypertamina-*" "MyPertamina All Environments"

echo ""
echo "Checking indices in Elasticsearch..."
echo ""

# Show existing indices
curl -s -u $ES_USER:$ES_PASSWORD 'http://localhost:9200/_cat/indices?v' | grep mypertamina || echo "No mypertamina indices found yet"

echo ""
echo "==========================================="
echo "✅ Setup Complete!"
echo "==========================================="
echo ""
echo "Data views created:"
echo "  📊 MyPertamina Dev           → Pattern: mypertamina-dev-*"
echo "  📊 MyPertamina Staging       → Pattern: mypertamina-staging-*"
echo "  📊 MyPertamina Production    → Pattern: mypertamina-prod-*"
echo "  📊 MyPertamina All Environments → Pattern: mypertamina-*"
echo ""
echo "Index pattern format: {topic}-YYYY.MM.dd"
echo "Example indices:"
echo "  • mypertamina-dev-2026.03.16"
echo "  • mypertamina-staging-2026.03.16"
echo "  • mypertamina-prod-2026.03.16"
echo ""
echo "Next steps:"
echo "  1. Send test messages to create indices:"
echo "     ./sample-kafka-send.sh"
echo ""
echo "  2. Open Kibana: http://localhost:5601"
echo ""
echo "  3. Go to Discover and select a data view:"
echo "     • 'MyPertamina Dev' - Only dev environment"
echo "     • 'MyPertamina Staging' - Only staging environment"
echo "     • 'MyPertamina Production' - Only production data"
echo "     • 'MyPertamina All Environments' - All topics combined"
echo ""
echo "  4. Adjust time range to 'Last 30 days'"
echo ""
