Changes Made:
Added Kafka and Zookeeper services (docker-compose.yml:4-40)

Zookeeper on port 2181
Kafka on ports 9092 (internal) and 9093 (external/localhost)
Auto-create topics enabled
Added persistent volumes for data storage
Updated Logstash configuration (logstash.conf:3)

Changed Kafka connection from "YOUR_GCP_KAFKA:9092" to "kafka:9092"
Now connects to the local Kafka instance
Updated Logstash service (docker-compose.yml:82)

Added dependency on Kafka to ensure proper startup order
Fixed filename typo

Renamed docker-dompose.yml → docker-compose.yml
How to Use:
Start all services:
docker-compose up -d

Create the telemetry topic (if not auto-created):
docker exec -it kafka kafka-topics --create --topic telemetry-topic-test --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

Test by producing a message:
docker exec -it kafka kafka-console-producer --topic telemetry-topic-test --bootstrap-server localhost:9092

Then paste a JSON message like:
{"tranTime":"2024-02-15T10:00:00Z","executeTime":1500,"message":"test"}

Check the logs:

Access the services:

Kafka: localhost:9093
Elasticsearch: http://localhost:9200 (elastic/pertamina)
Kibana: http://localhost:5601
Your complete monitoring stack is now ready with local Kafka integration!