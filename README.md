# DevSecOps Industry Best Practices

`17636-D | 2026 | Professor Jonathan Aldrich | Soobin Rho`

> I recommend you to read this file from GitHub: https://github.com/soobinrho/17636-devsecops-industry-best-practices

<br>

In this assignment, I deployed a Spring Boot sample project called Petclinic with a DevSecOps pipeline:

<br>

| Service | Purpose |
| --------| ------- |
| **Jenkins** | Enables continuous integration and continuous delivery. |
| **SonarQube** | Performs static analysis on the codebase. |
| **ZAP (Zed Attack Proxy)** | Conducts vulnerability scanning and penetration testing on a live web application as a security analysis part of the DevSecOps. Supports a myriad of plugins including reporting generation tools and OWASP PTK (Penetration Testing Kit). |
| **Prometheus** | Metrics data collection toolkit. Also supports alerts based on custom rules. |
| **Grafana** | Monitoring and data visualization platform that can ingest data from Prometheus, Elasticsearch, Postgres, etc. |
| **Ansible** | Enables Infrastructure as Code. Used for deployment to the prod server. |

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

## Overview

Whenever a commit is pushed to the `main` branch of this repository, Jenkins starts a CI/CD pipeline.

```
1. Repository Checkout (Git)
->
2. Static Analysis (SonarQube)
->
3. Vulnerability Scanning and Penetration Testing (ZAP and OWASP PTK)
->
4. Petclinic Web App Container Image Build (Docker)
->
5. Prod Deployment (Ansible)
```

<br>

## How to deploy

```bash
git clone https://github.com/soobinrho/17636-devsecops-industry-best-practices
cd 17636-devsecops-industry-best-practices

# The entirety of the piepeline has been scripted using Make. Under the hood,
# `./Makefile` deploys and configures Jenkins based on the user-defined username
# and password in `.env` and then creates a Jenkins SSH agent and connects this
# as a Jenkins node so that it can be used for all pipeline activities.

# All required Jenkins plugins are installed at Docker image build stage using
# the Jenkins Configuration as Code plugin, as well as all of the required username
# credentials (SSH private key for the Jenkins SSH agent and Jenkins login creds).
make start-build-pipeline

# WIP
pip install --include-deps ansible

# Required for running `docker compose up`
ansible-galaxy collection install community.docker

# Required for installing Docker Compose on the prod server.
ansible-galaxy role install geerlingguy.docker

# TODO: Run these in Ansible.

# Install the latest LTS (Long Term Support) version of OpenJDK,
# which as of now is OpenJDK 21.
sudo apt install openjdk-21-jdk
```

<br>

## Useful Debugging Workflows

```bash
# A bug that took me hours to fix was where SonarQube container wasn't able to
# communicate with the Jenkins container even though they were placed in the
# same Docker Compose network. Whenever manual plumbing is required in cases
# like these, we can open up a shell session in each of the containers:
make test-sh-in-jenkins-ssh-agent
make test-sh-in-jenkins-ssh-agent
make test-sh-in-jenkins

# Whenever I implement a new feature, I use this one-liner to remove all Docker
# volumes, build all required Docker images, and deploy them from scratch to
# test if the codebase works in a clean slate.
make reset

# How to clean up all Docker volumes and images for this assignment afterwards.
make clean clean-remove-volumes clean-remove-images
```

<br>

## Resources

- **The CNCF Security Technical Advisory Group's Supply Chain Best Practices**: https://github.com/cncf/tag-security#publications
- **NSA / CISA Kubernetes Hardening Guide**: https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF

<br>
