#!/bin/bash

echo "🚀 Starting BCP Conference Monitoring Stack..."

# Stop any existing containers
echo "🧹 Cleaning up existing containers..."
podman compose down 2>/dev/null || true

# Start the monitoring stack
echo "📊 Starting Jaeger, Prometheus, and Grafana..."
podman compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Check if services are running
echo "🔍 Checking services..."

# Check Jaeger
if curl -s http://localhost:16686 > /dev/null; then
    echo "✅ Jaeger: http://localhost:16686"
else
    echo "❌ Jaeger: Not ready yet"
fi

# Check Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo "✅ Prometheus: http://localhost:9090"
else
    echo "❌ Prometheus: Not ready yet"
fi

# Check Grafana
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Grafana: http://localhost:3000"
else
    echo "❌ Grafana: Not ready yet"
fi

echo ""
echo "🎉 Monitoring stack is ready!"
echo ""
echo "📊 Services:"
echo "- Grafana: http://localhost:3000 (admin/admin)"
echo "- Prometheus: http://localhost:9090"
echo "- Jaeger: http://localhost:16686"
echo ""
echo "🔧 Make sure your Quarkus services are running:"
echo "- Sessions: http://localhost:8081"
echo "- Speakers: http://localhost:8082"
echo ""
echo "📈 Dashboard: 'BCP Conference Metrics Dashboard'"
echo "   - Custom metric: callsToGetSessions"
echo "   - HTTP metrics, JVM metrics, and more"
echo ""
echo "🛑 To stop: podman compose down"
