# CloudOps Platform — On-Call Runbook

## 1. How to Rollback a Deployment via GitOps

**Scenario:** Bad deployment pushed to production, need to rollback.

**Steps:**
```bash
# Find the last good commit in cloudops-gitops
cd cloudops-gitops
git log --oneline manifests/api/deployment.yaml

# Revert the bad commit
git revert <bad-commit-sha>
git push origin main

# ArgoCD detects the change and auto-syncs
# Verify rollback
kubectl rollout status deployment/cloudops-api -n cloudops-prod
```

**Why this works:** ArgoCD continuously reconciles cluster state with Git.
Reverting in Git = rolling back in the cluster. Full audit trail preserved.

---

## 2. Alert Triage Guide

### HighErrorRate (warning)
**What it means:** >5% of API requests returning 4xx/5xx for 5 minutes.

**Steps:**
1. Check Grafana Error Rate panel — which route is failing?
2. Check API logs: `kubectl logs -n cloudops-prod -l app=api --tail=100`
3. Check recent deployments in ArgoCD UI
4. If bad deploy → rollback via GitOps (see Section 1)
5. If Redis issue → check `kubectl exec redis-0 -n cloudops-prod -- redis-cli ping`

---

### APIPodDown (critical)
**What it means:** Zero ready API pods — service completely down.

**Steps:**
1. Check pod status: `kubectl get pods -n cloudops-prod`
2. Check events: `kubectl describe deployment cloudops-api -n cloudops-prod`
3. Check logs: `kubectl logs -n cloudops-prod -l app=api --previous`
4. Common causes:
   - OOMKilled → increase memory limit in deployment.yaml
   - ImagePullBackOff → check ECR credentials
   - CrashLoopBackOff → check application logs
5. If needed → rollback via GitOps

---

### HighMemoryUsage (warning)
**What it means:** API memory >80% of 512Mi limit for 5 minutes.

**Steps:**
1. Check memory: `kubectl top pods -n cloudops-prod`
2. Check for memory leak in recent code changes
3. Temporary fix: `kubectl rollout restart deployment/cloudops-api -n cloudops-prod`
4. Long-term fix: increase memory limit or fix memory leak in code

---

## 3. On-Call Checklist

**When you receive a Slack alert:**
- [ ] Acknowledge the alert in Slack
- [ ] Check Grafana dashboard for context
- [ ] Check Prometheus alerts page: `http://prometheus:9090/alerts`
- [ ] Check ArgoCD for recent deployments
- [ ] Follow alert-specific triage guide above
- [ ] Document what happened and how you fixed it
- [ ] Create GitHub issue if code fix needed
- [ ] Update runbook if new failure mode discovered

---

## 4. Useful Commands

```bash
# Check all pods
kubectl get pods --all-namespaces

# Check API logs
kubectl logs -n cloudops-prod -l app=api --tail=50

# Check Redis
kubectl exec -n cloudops-prod redis-0 -- redis-cli info stats

# Force ArgoCD sync
argocd app sync cloudops-api

# Check HPA status
kubectl get hpa -n cloudops-prod

# Check resource usage
kubectl top pods -n cloudops-prod
kubectl top nodes
```
