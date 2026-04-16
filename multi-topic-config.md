# Multi-Topic Configuration Guide

## Overview

The Logstash configuration now supports consuming from multiple Kafka telemetry topics simultaneously. This guide explains how to configure and test multi-topic streaming.

## Configuration Options

### Option 1: Explicit Topic List (Current Configuration)

Edit `logstash.conf` line 5 to specify exact topics:

```conf
topics => ["telemetry-topic", "telemetry-topic-2", "telemetry-topic-3"]
```

**Pros:**
- Explicit control over which topics to consume
- Clear and predictable behavior
- Recommended for production

**Cons:**
- Requires manual updates when adding new topics
- Need to restart Logstash container after changes

### Option 2: Pattern-Based Subscription

To automatically subscribe to all topics matching a pattern, uncomment line 7 and comment line 5:

```conf
# topics => ["telemetry-topic", "telemetry-topic-2", "telemetry-topic-3"]
topics_pattern => "telemetry-.*"
```

**Pros:**
- Automatically discovers new topics matching the pattern
- No configuration changes needed for new topics

**Cons:**
- Less explicit control
- May consume from unintended topics if naming isn't careful

## Key Features Enabled

### 1. Topic Metadata Capture

`decorate_events => true` adds Kafka metadata to each event:
- `[@metadata][kafka][topic]` - Source topic name
- `[@metadata][kafka][partition]` - Partition number
- `[@metadata][kafka][offset]` - Message offset
- `[@metadata][kafka][key]` - Message key (if present)

### 2. Source Topic Field

The `source_topic` field is automatically added to all documents:

```json
{
  "tranTime": "2024-02-15T10:00:00Z",
  "executeTime": 1500,
  "source_topic": "telemetry-topic-2",
  ...
}
```

This allows filtering by topic in Kibana dashboards.

### 3. Topic-Specific Processing

You can add custom logic for different topics in the filter section:

```conf
if [@metadata][kafka][topic] == "telemetry-topic-2" {
  mutate {
    add_field => { "service_name" => "payment-service" }
  }
}
```

### 4. Topic-Based Index Routing

**Option A: Single Unified Index (Default)**
All topics stored together:
```conf
index => "telemetry-%{+YYYY.MM.dd}"
```
Result: `telemetry-2024.02.15`

**Option B: Topic-Specific Indices**
Separate indices per topic:
```conf
index => "%{source_topic}-%{+YYYY.MM.dd}"
```
Results:
- `telemetry-topic-2024.02.15`
- `telemetry-topic-2-2024.02.15`
- `telemetry-topic-3-2024.02.15`

**Option C: Conditional Routing**
Different indices based on topic matching:
```conf
if [@metadata][kafka][topic] =~ /^service-/ {
  elasticsearch {
    index => "services-%{+YYYY.MM.dd}"
  }
} else {
  elasticsearch {
    index => "telemetry-%{+YYYY.MM.dd}"
  }
}
```

## Setup Instructions

### 1. Create Multiple Topics on Kafka Server

```bash
# Create additional topics
kafka-topics --create --topic telemetry-topic-2 \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1

kafka-topics --create --topic telemetry-topic-3 \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1

# Verify topics exist
kafka-topics --list --bootstrap-server localhost:9092
```

### 2. Configure Logstash

Edit `logstash.conf`:
- Line 5: Add your topic names to the array
- Line 77: Choose indexing strategy (unified vs topic-specific)
- Lines 56-65: Optionally add topic-specific processing logic

### 3. Restart Logstash Container

```bash
docker-compose restart logstash

# Verify Logstash is consuming from all topics
docker-compose logs -f logstash
```

## Testing

### Test Each Topic Individually

**Topic 1:**
```bash
kafka-console-producer --topic telemetry-topic --bootstrap-server localhost:9092
```
```json
{"tranTime":"2024-02-15T10:00:00Z","executeTime":1200,"serviceName":"auth-service"}
```

**Topic 2:**
```bash
kafka-console-producer --topic telemetry-topic-2 --bootstrap-server localhost:9092
```
```json
{"tranTime":"2024-02-15T10:01:00Z","executeTime":3500,"serviceName":"payment-service"}
```

**Topic 3:**
```bash
kafka-console-producer --topic telemetry-topic-3 --bootstrap-server localhost:9092
```
```json
{"tranTime":"2024-02-15T10:02:00Z","executeTime":800,"serviceName":"notification-service"}
```

### Verify in Elasticsearch

**Check indices:**
```bash
curl -u elastic:pertamina http://localhost:9200/_cat/indices?v
```

**Query by topic:**
```bash
curl -u elastic:pertamina -X GET "http://localhost:9200/telemetry-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "term": {
      "source_topic.keyword": "telemetry-topic-2"
    }
  }
}
'
```

### Verify in Kibana

1. Open Kibana: http://localhost:5601
2. Navigate to Discover
3. Create index pattern: `telemetry-*`
4. Search/filter by `source_topic` field
5. Create visualizations grouped by topic

## Monitoring Consumer Group

Check consumer group status:

```bash
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group telemetry-monitor \
  --describe
```

Expected output shows all topics with their lag:
```
TOPIC              PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
telemetry-topic    0          150             150             0
telemetry-topic-2  0          200             200             0
telemetry-topic-3  0          175             175             0
```

## Advanced Configurations

### Different Consumer Groups per Topic

If topics need independent processing:

```conf
input {
  kafka {
    topics => ["telemetry-topic"]
    group_id => "telemetry-monitor-1"
    ...
  }
  kafka {
    topics => ["telemetry-topic-2"]
    group_id => "telemetry-monitor-2"
    ...
  }
}
```

### Topic-Specific Codecs

For different data formats:

```conf
input {
  kafka {
    topics => ["telemetry-topic"]
    codec => json
  }
  kafka {
    topics => ["telemetry-topic-xml"]
    codec => plain
  }
}
```

### Partition Assignment

For better parallelism with multiple partitions:

```conf
kafka {
  topics => ["telemetry-topic"]
  consumer_threads => 4  # One thread per partition
}
```

## Troubleshooting

**Logstash not consuming from new topic:**
- Verify topic exists: `kafka-topics --list --bootstrap-server localhost:9092`
- Check Logstash logs: `docker-compose logs logstash | grep -i topic`
- Ensure topic name matches exactly (case-sensitive)
- Restart Logstash after config changes

**Consumer lag increasing:**
- Check Logstash processing performance
- Consider increasing `consumer_threads`
- Verify Elasticsearch isn't the bottleneck
- Monitor with: `kafka-consumer-groups --describe`

**Missing source_topic field:**
- Ensure `decorate_events => true` is set in input
- Verify filter section includes the mutate block
- Restart Logstash after changes

**Pattern not matching topics:**
- Test pattern with: `kafka-topics --list --bootstrap-server localhost:9092 | grep -E "pattern"`
- Ensure pattern is a valid Java regex
- Remember: patterns are case-sensitive

## Best Practices

1. **Topic Naming Convention**: Use consistent prefixes (e.g., `telemetry-*`, `service-*`)
2. **Index Strategy**: Start with unified indices, split only if needed for retention/performance
3. **Consumer Group**: Use single group for related topics to maintain ordering
4. **Monitoring**: Set up alerts for consumer lag
5. **Testing**: Always test new topics in non-production first
6. **Documentation**: Document what each topic contains and its purpose
