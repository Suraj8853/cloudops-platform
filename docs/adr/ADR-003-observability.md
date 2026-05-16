# ADR-003: Prometheus vs CloudWatch — When to Use Each

## Status
Accepted

## Context
The CloudOps Platform requires comprehensive observability across both 
application-level and infrastructure-level metrics. Two tools are available:
Prometheus (open-source, pull-based) and AWS CloudWatch (managed, AWS-native).

## Decision
Use both Prometheus and CloudWatch for different layers of observability.

## Prometheus — Application & Kubernetes Layer
**Use for:**
- Custom application metrics (url_shortener_requests_total, redirect duration)
- Kubernetes workload metrics (pod CPU/memory, deployment replicas, HPA scaling)
- Redis cache metrics (hit rate, memory usage)
- PromQL-based alerting (HighErrorRate, APIPodDown, HighMemoryUsage)
- Grafana dashboards for real-time application monitoring

**Why Prometheus:**
- Pull-based scraping via ServiceMonitors — no agent needed in app code
- Rich query language (PromQL) for complex aggregations
- Native Kubernetes integration via Prometheus Operator
- Free and open-source

## CloudWatch — AWS Infrastructure Layer
**Use for:**
- ALB metrics (5xx error rate, request count, latency)
- RDS metrics (CPU, connections, storage)
- EKS node metrics (CPU, memory via Container Insights)
- CloudWatch Logs (EKS control plane logs, application logs via Fluent Bit)

**Why CloudWatch:**
- AWS managed services publish metrics here natively — no extra setup
- Integrated with SNS for email/PagerDuty alerting
- Required for AWS-native services (RDS, ALB) that don't expose Prometheus endpoints
- Free tier covers basic metrics

## Consequences
- Two alerting systems to maintain
- Grafana can query both (CloudWatch datasource available)
- Overlap exists for node metrics — Prometheus node-exporter vs CloudWatch agent
- For node metrics, prefer Prometheus for dashboards, CloudWatch for billing/compliance
