# Deployment Architecture

## Deployment Overview

This document defines the comprehensive deployment architecture, infrastructure requirements, and operational strategies for the system. It covers containerization, orchestration, environments, monitoring, and deployment pipelines.

## Infrastructure Architecture

### Cloud Architecture
```mermaid
graph TB
    subgraph "Production Environment"
        subgraph "Load Balancer"
            ALB[Application Load Balancer]
            NLB[Network Load Balancer]
        end
        
        subgraph "Kubernetes Cluster"
            subgraph "Application Pods"
                API1[API Gateway Pod]
                API2[API Gateway Pod]
                AUTH1[Auth Service Pod]
                AUTH2[Auth Service Pod]
                USER1[User Service Pod]
                USER2[User Service Pod]
                TASK1[Task Service Pod]
                TASK2[Task Service Pod]
                NOTIF1[Notification Pod]
            end
        end
        
        subgraph "Managed Services"
            RDS[(RDS PostgreSQL)]
            REDIS[(ElastiCache Redis)]
            ES[(OpenSearch)]
            S3[(S3 Storage)]
        end
        
        subgraph "Message Queue"
            SQS[Amazon SQS]
            SNS[Amazon SNS]
        end
    end
    
    subgraph "Monitoring"
        PROM[Prometheus]
        GRAF[Grafana]
        JAEGER[Jaeger Tracing]
    end
    
    ALB --> API1
    ALB --> API2
    API1 --> AUTH1
    API1 --> USER1
    API1 --> TASK1
    API2 --> AUTH2
    API2 --> USER2
    API2 --> TASK2
    
    AUTH1 --> RDS
    AUTH1 --> REDIS
    USER1 --> RDS
    USER1 --> S3
    TASK1 --> RDS
    TASK1 --> ES
    
    NOTIF1 --> SQS
    SQS --> SNS
```

### Environment Strategy
```yaml
environments:
  development:
    purpose: "Local development and testing"
    infrastructure: "Docker Compose"
    resources:
      cpu: "2 cores per service"
      memory: "1GB per service"
    databases:
      postgresql: "Local container"
      redis: "Local container"
    monitoring: "Basic logging"
  
  testing:
    purpose: "Automated testing and QA"
    infrastructure: "Kubernetes (1 node)"
    resources:
      cpu: "1 core per service"
      memory: "512MB per service"
    databases:
      postgresql: "Managed service (small)"
      redis: "Managed service (small)"
    monitoring: "Full monitoring stack"
  
  staging:
    purpose: "Production-like testing"
    infrastructure: "Kubernetes (3 nodes)"
    resources:
      cpu: "2 cores per service"
      memory: "2GB per service"
    databases:
      postgresql: "Managed service (medium)"
      redis: "Managed service (medium)"
    monitoring: "Full monitoring + alerting"
  
  production:
    purpose: "Live production system"
    infrastructure: "Kubernetes (6+ nodes)"
    resources:
      cpu: "4 cores per service"
      memory: "4GB per service"
    databases:
      postgresql: "Managed service (large, HA)"
      redis: "Managed service (large, cluster)"
    monitoring: "Full observability stack"
```

## Containerization Strategy

### Docker Configuration
```dockerfile
# Multi-stage build for Node.js services
FROM node:18-alpine AS builder

# Create app directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY src/ ./src/
COPY tsconfig.json ./

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

# Set user
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Expose port
EXPOSE 3000

# Start application
CMD ["node", "dist/index.js"]
```

### Service-Specific Images
```yaml
services:
  api_gateway:
    image: "project/api-gateway:latest"
    build_context: "./services/api-gateway"
    port: 3000
    resources:
      limits: { cpu: "500m", memory: "1Gi" }
      requests: { cpu: "250m", memory: "512Mi" }
  
  auth_service:
    image: "project/auth-service:latest"
    build_context: "./services/auth"
    port: 3001
    resources:
      limits: { cpu: "400m", memory: "800Mi" }
      requests: { cpu: "200m", memory: "400Mi" }
  
  user_service:
    image: "project/user-service:latest"
    build_context: "./services/user"
    port: 3002
    resources:
      limits: { cpu: "600m", memory: "1.2Gi" }
      requests: { cpu: "300m", memory: "600Mi" }
```

## Kubernetes Deployment

### Namespace Organization
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    purpose: monitoring
```

### Deployment Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: production
  labels:
    app: auth-service
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
        version: v1
    spec:
      serviceAccountName: auth-service
      containers:
      - name: auth-service
        image: project/auth-service:v1.2.3
        imagePullPolicy: Always
        ports:
        - containerPort: 3001
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: secret
        resources:
          requests:
            memory: "400Mi"
            cpu: "200m"
          limits:
            memory: "800Mi"
            cpu: "400m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
        - name: temp-volume
          mountPath: /tmp
      volumes:
      - name: config-volume
        configMap:
          name: auth-service-config
      - name: temp-volume
        emptyDir: {}
      nodeSelector:
        kubernetes.io/arch: amd64
      tolerations:
      - key: "app"
        operator: "Equal"
        value: "auth"
        effect: "NoSchedule"
```

### Service and Ingress
```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: production
  labels:
    app: auth-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3001
    protocol: TCP
    name: http
  selector:
    app: auth-service
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit-rps: "100"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-secret
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api/v1/auth
        pathType: Prefix
        backend:
          service:
            name: auth-service
            port:
              number: 80
      - path: /api/v1/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
```

## Configuration Management

### ConfigMaps and Secrets
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: auth-service-config
  namespace: production
data:
  config.yaml: |
    server:
      port: 3001
      host: "0.0.0.0"
    auth:
      jwt_expiry: "15m"
      refresh_expiry: "7d"
      max_sessions: 5
    rate_limiting:
      window_ms: 900000
      max_requests: 100
---
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
  namespace: production
type: Opaque
data:
  url: cG9zdGdyZXNxbDovL3VzZXI6cGFzcz... # base64 encoded
---
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  namespace: production
type: Opaque
data:
  secret: eW91ci1qd3Qtc2VjcmV0... # base64 encoded
```

### Environment-Specific Configuration
```yaml
# Production values
production:
  replicas:
    auth_service: 3
    user_service: 5
    task_service: 4
    notification_service: 2
  
  resources:
    auth_service:
      requests: { cpu: "200m", memory: "400Mi" }
      limits: { cpu: "400m", memory: "800Mi" }
    user_service:
      requests: { cpu: "300m", memory: "600Mi" }
      limits: { cpu: "600m", memory: "1.2Gi" }
  
  autoscaling:
    enabled: true
    min_replicas: 2
    max_replicas: 10
    cpu_threshold: 70
    memory_threshold: 80
```

## Auto-scaling Configuration

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: auth-service-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: auth-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
```

### Vertical Pod Autoscaler
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: auth-service-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: auth-service
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: auth-service
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1
        memory: 2Gi
      controlledResources: ["cpu", "memory"]
```

## CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - run: npm ci
    
    - name: Run linting
      run: npm run lint
    
    - name: Run type checking
      run: npm run typecheck
    
    - name: Run unit tests
      run: npm run test:unit
      env:
        DATABASE_URL: postgres://postgres:test@localhost:5432/testdb
        REDIS_URL: redis://localhost:6379
    
    - name: Run integration tests
      run: npm run test:integration
      env:
        DATABASE_URL: postgres://postgres:test@localhost:5432/testdb
        REDIS_URL: redis://localhost:6379
    
    - name: Generate coverage report
      run: npm run test:coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'

  build:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy to staging
      run: |
        aws eks update-kubeconfig --name staging-cluster
        kubectl set image deployment/auth-service auth-service=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:develop-${{ github.sha }} -n staging
        kubectl rollout status deployment/auth-service -n staging

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy to production
      run: |
        aws eks update-kubeconfig --name production-cluster
        kubectl set image deployment/auth-service auth-service=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:main-${{ github.sha }} -n production
        kubectl rollout status deployment/auth-service -n production
        
    - name: Run smoke tests
      run: |
        npm run test:smoke
      env:
        API_URL: https://api.example.com
```

## Monitoring and Observability

### Prometheus Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
      - "/etc/prometheus/rules/*.yml"
    
    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093
    
    scrape_configs:
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
      
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
```

### Grafana Dashboards
```json
{
  "dashboard": {
    "title": "Application Services Overview",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{ service }}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "95th percentile - {{ service }}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "Error rate - {{ service }}"
          }
        ]
      }
    ]
  }
}
```

## Disaster Recovery

### Backup Strategy
```yaml
postgresql_backup:
  automated_backups:
    retention: "7 days"
    frequency: "Every 6 hours"
  
  manual_snapshots:
    retention: "30 days"
    encryption: true
  
  cross_region_replication:
    enabled: true
    regions: ["us-west-2", "us-east-1"]

kubernetes_backup:
  velero:
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention: "72h"
    storage_location: "s3://backup-bucket/k8s-backups"
    include_namespaces: ["production", "staging"]
```

### Recovery Procedures
```yaml
rto_targets:
  critical_services: "15 minutes"
  non_critical_services: "1 hour"

rpo_targets:
  database: "15 minutes"
  file_storage: "1 hour"

recovery_steps:
  database_failure:
    1. "Assess failure scope and impact"
    2. "Activate read replica if available"
    3. "Update application configuration"
    4. "Verify service functionality"
    5. "Restore from backup if needed"
  
  complete_cluster_failure:
    1. "Provision new Kubernetes cluster"
    2. "Restore namespace configurations"
    3. "Deploy applications from images"
    4. "Restore database from backup"
    5. "Update DNS and load balancer"
    6. "Run verification tests"
```

This deployment architecture provides a comprehensive, scalable, and resilient foundation for running the application in production while maintaining development velocity and operational excellence.