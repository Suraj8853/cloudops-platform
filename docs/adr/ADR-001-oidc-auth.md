# ADR-001: Use OIDC for GitHub Actions AWS Authentication

## Status
Accepted

## Context
GitHub Actions needs AWS access to push Docker images to ECR as part of the CI pipeline.
The pipeline runs on every code push and requires permissions to authenticate with AWS ECR.
We needed a secure way to grant this access without storing long-lived AWS credentials in GitHub.

## Decision
We decided to use OIDC (OpenID Connect) authentication. When the pipeline runs, 
GitHub generates a JWT token which AWS verifies through the GitHub OIDC identity 
provider configured in IAM. AWS then issues a short-lived session token scoped 
to the specific GitHub repository, allowing the pipeline to access ECR without 
storing any credentials.

## Alternatives Considered

### Option 1 — IAM Access Keys
IAM access keys are long-lived credentials that must be stored as GitHub secrets.
If leaked through logs, a compromised repo, or a security breach, an attacker gains
permanent AWS access until the key is manually rotated. They could push malicious
images to ECR, delete repositories, or escalate privileges across the AWS account.

### Option 2 — OIDC (Chosen)
OIDC issues short-lived session tokens (15 minutes) that expire automatically.
The IAM role trust policy locks the token to a specific GitHub repository and branch —
a token from a different repo cannot assume the role. No credentials are stored
anywhere. Nothing to leak, nothing to rotate.


## Consequences

### Positive
- No credentials stored anywhere — eliminates entire class of secret leak vulnerabilities
- Tokens expire automatically — no manual rotation required
- Scoped to specific repo and branch — blast radius of any compromise is minimal
- Full audit trail — every token request is logged in AWS CloudTrail

### Negative
- Slight latency added to pipeline startup — AWS must verify the JWT with GitHub's 
  identity provider before issuing a session token
- More complex initial setup — requires configuring OIDC provider in AWS IAM and 
  creating a trust policy with the correct conditions
- If GitHub's identity provider has an outage — pipeline cannot authenticate to AWS