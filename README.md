# Personal Portfolio Website (AWS + Terraform)

This repository contains the infrastructure and source code for my personal portfolio website, deployed on AWS using Terraform infrastructure-as-code. The site is hosted on Amazon S3, delivered globally via Amazon CloudFront, secured with SSL using AWS Certificate Manager, and routed using Amazon Route 53.

The goal of this project is to demonstrate practical cloud infrastructure skills, automation, and best practices for deploying and managing a production-ready static website.

---

## Architecture Overview

- **Amazon S3** – Hosts static website files (HTML, CSS, images)
- **Amazon CloudFront** – Global CDN for fast and secure content delivery
- **AWS Certificate Manager (ACM)** – SSL/TLS certificate for HTTPS
- **Amazon Route 53** – DNS management and domain routing
- **Terraform** – Infrastructure-as-code for provisioning and managing AWS resources

All infrastructure is defined and managed declaratively using Terraform.

---

## Features

- Fully private S3 bucket (no public access)
- Secure CloudFront access using Origin Access Identity (OAI)
- HTTPS enabled using ACM (us-east-1 for CloudFront compatibility)
- Custom domain configured with Route 53
- Automatic content uploads to S3 via Terraform
- Versioned infrastructure with repeatable deployments

---

## Project Structure

```text
portfolio-site/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
|   ├── terraform.tfstate
│   └── outputs.tf
├── website/
│   ├── index.html
│   ├── resume.pdf
│   └── profile.jpg
└── README.md
