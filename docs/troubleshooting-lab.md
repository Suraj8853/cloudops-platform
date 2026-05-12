# Troubleshooting Lab — Phase 3D

## Scenario 1 — OOMKilled

### What happened
Set memory limit to 5Mi on the API deployment. New pods 
immediately OOMKilled because the Node.js app requires 
significantly more than 5Mi to start.

### How I detected it
```bash
kubectl get pods -n cloudops-prod
# showed: OOMKilled status on new pod

kubectl describe pod <pod-name> -n cloudops-prod | grep -A 10 "Last State"
# showed: Reason: OOMKilled, Exit Code: 137
```

### Root cause
Memory limit set too low (5Mi). Node.js runtime alone 
requires ~50Mi minimum. Exit code 137 = 128 + SIGKILL, 
confirming Linux OOM Killer fired.

### Fix
```bash
kubectl set resources deployment cloudops-api \
  -n cloudops-prod \
  --requests=memory=256Mi \
  --limits=memory=512Mi
```

### What saved production
RollingUpdate strategy with maxUnavailable: 0 kept old 
pods running. New OOMKilled pods never passed readiness 
probe so old pods were never removed. Zero user impact.

### Prevention
- Set resource limits based on actual app profiling
- Monitor memory usage via Prometheus alerts
- Alert when memory usage > 80% of limit




## Scenario 2 — CrashLoopBackOff (Bad Command)

### What happened
Patched deployment with wrong command `node wrongfile.js`.
File doesn't exist in container → app crashed immediately on startup.

### How I detected it
```bash
kubectl get pods -n cloudops-prod
# showed: CrashLoopBackOff on new pod

kubectl describe pod <pod> -n cloudops-prod | grep -A 10 "Last State"
# Exit Code: 1 (application error, not OOMKilled)
# Died instantly → crashed on startup

kubectl logs <pod> -n cloudops-prod --previous
# Error: Cannot find module '/app/wrongfile.js'
# code: MODULE_NOT_FOUND
```

### Root cause
Wrong command set in deployment spec — `node wrongfile.js`
instead of `node src/index.js`. Node.js couldn't find the
file and exited with code 1.

### Fix
```bash
kubectl patch deployment cloudops-api -n cloudops-prod \
  --patch '{"spec":{"template":{"spec":{"containers":[{"name":"api","command":null}]}}}}'
```
Removed command override → container used Dockerfile CMD again.

### Key learning
- Exit code 1 = application error → check logs
- Exit code 137 = OOMKilled → check describe
- CrashLoopBackOff is a symptom, not a cause
- Always check logs --previous for crashed containers
- RollingUpdate kept old pods running during failure



## Scenario 3 — ImagePullBackOff

### What happened
Changed deployment image to non-existent ECR repository
`wrong-image:latest`. Kubernetes couldn't pull the image.

### How I detected it
```bash
kubectl get pods -n cloudops-prod
# showed: ImagePullBackOff on new pod

kubectl describe pod <pod> -n cloudops-prod
# Events showed:
# "Failed to pull image: not found"
# Tried 4 times before backing off
```

### Root cause
Image `wrong-image:latest` doesn't exist in ECR.
Repository name was wrong — should be `cloudops-dev-api`.

### Fix
```bash
kubectl set image deployment cloudops-api \
  api=599476212737.dkr.ecr.ap-south-1.amazonaws.com/cloudops-dev-api:latest \
  -n cloudops-prod
```

### Key learning
- ImagePullBackOff → always use kubectl describe, not logs
- Container never starts → no logs available
- Events section shows exact failure reason
- Common causes: wrong name, wrong tag, missing ECR permissions
- RollingUpdate kept old pods running during failure




## Scenario 4 — Pending Pod (Wrong nodeSelector)

### What happened
Added nodeSelector `disktype=ssd` to deployment. No nodes
in cluster have this label — pod stuck in Pending forever.

### How I detected it
```bash
kubectl get pods -n cloudops-prod
# showed: Pending status — never moves to Running

kubectl describe pod <pod> -n cloudops-prod
# Events showed:
# "0/2 nodes are available"
# "2 node(s) didn't match Pod's node affinity/selector"
```

### Root cause
nodeSelector required label `disktype=ssd` — no node
has this label. Scheduler couldn't place the pod anywhere.

### Fix
```bash
kubectl patch deployment cloudops-api -n cloudops-prod \
  --patch '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'
```

### Key learning
- Pending = scheduling problem, not application problem
- Always check Events section in describe for scheduling failures
- "0/N nodes are available" → nodeSelector/affinity mismatch
- Pod never starts → no logs available → use describe
- RollingUpdate kept old pods running during failure



## Scenario 5 — Service Not Routing (Label Mismatch)

### What happened
Changed Service selector to `app=wrong-label`. Pods kept
running but Endpoints became empty — traffic stopped routing.

### Why this is dangerous
Pods show Running ✅ — engineers think everything is fine.
Users getting 502 errors. Root cause not obvious.

### How I detected it
```bash
kubectl get endpoints -n cloudops-prod
# cloudops-api: <none> ← no pod IPs

kubectl describe service cloudops-api -n cloudops-prod
# Selector: app=wrong-label ← suspicious!

kubectl get pods -n cloudops-prod --show-labels
# pods have: app=api ← doesn't match selector!
```

### Root cause
Service selector `app=wrong-label` didn't match
pod label `app=api` — Endpoints stayed empty.

### Fix
```bash
kubectl patch service cloudops-api -n cloudops-prod \
  --patch '{"spec":{"selector":{"app":"api"}}}'
```

### Key learning
- Pods Running but 502 errors → check Endpoints first
- kubectl describe service → check Selector field
- kubectl get pods --show-labels → check pod labels
- Selector must exactly match pod labels
- Most common real-world cause of Service routing issues
