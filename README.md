# DevSecOps Industry Best Practices

`17636-D | 2026 | Professor Jonathan Aldrich | Soobin Rho`

<br>

A pet store web app built alongside with the implementation of the current industry best practices in DevSecOps.

<br>

| Service | Purpose |
| --------------- | ----------- |
| **Hetzner** | An Ubuntu box with 4 vCPU, 8GB RAM, and 80GB SSD. |
| **Ansible** | Automation for deploying the infrastructure (Infrastructure as Code). |
| **Jenkins** | Automation for continuous integration and continuous delivery. |
| **ZAP (Zed Attack Proxy)** | Vulnerability scanning and penetration testing tool specialized for web applications. |
| **Grafana** | Observability and data visualization platform that can ingest data from Prometheus, Elasticsearch, Postgres, etc. |
| **Prometheus** | Monitoring and alerting toolkit that collect and store the metrics data. |
| **SonarQube** | Code static analysis for security and metrics. |

<br>
<br>

> Automation is critical to supply chain security. Automating as much of the software supply chain as possible can significantly reduce the possibility of human error and configuration drift ...
> <br><br>
> The build environments used in a supply chain should be clearly
defined, with limited scope. The human and machine identities operating
in those environments should be granted only the minimum permissions
required to complete their assigned tasks ...
> <br><br>
> All entities operating in the supply chain environment must be required to mutually authenticate using hardened authentication mechanisms with regular key rotation.
> <br><br>
> \- "Deployment and Operations for Software Engineers" by Len Bass and John Klein

<br>

## How to deploy

```bash
# Build and deploy everything for this project.
make all

# Only run the build process.
make build

# Only run the deployment process.
make deploy

# Cleanup for after done with this project.
make cleanup
```

<br>

## Resources

- **The CNCF Security Technical Advisory Group's Supply Chain Best Practices**: https://github.com/cncf/tag-security#publications
- **NSA / CISA Kubernetes Hardening Guide**: https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF

<br>
