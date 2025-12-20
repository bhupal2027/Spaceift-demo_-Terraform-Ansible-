# 🚀 Deploying Terraform + Ansible to Spacelift

A complete beginner-friendly guide to deploy infrastructure using Terraform and configure it with Ansible on Spacelift, with automatic stack dependencies.

---

## 📋 Table of Contents

1. [What This Guide Does](#what-this-guide-does)
2. [Prerequisites](#prerequisites)
3. [Architecture Overview](#architecture-overview)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Troubleshooting](#troubleshooting)
6. [Key Concepts](#key-concepts)
7. [Additional Resources](#additional-resources)

---

## 🎯 What This Guide Does

This guide shows you how to:
- Connect your GitHub repository to Spacelift
- Deploy infrastructure using Terraform (e.g., EC2 instances)
- Automatically configure that infrastructure using Ansible
- Set up dependencies so Ansible runs **only after** Terraform succeeds
- Pass outputs from Terraform to Ansible automatically

**End Result**: Push code to GitHub → Spacelift provisions infrastructure → Spacelift automatically configures it!

---

## ✅ Prerequisites

Before starting, make sure you have:

- [ ] **GitHub Account** with your repository
- [ ] **Spacelift Account** (free tier works fine)
- [ ] **AWS Account** (or other cloud provider)
- [ ] **SSH Key Pair** for accessing instances
- [ ] **Basic knowledge** of Git, Terraform, and Ansible

### Required Repository Structure

Your repository should have this structure:
```
your-repo/
├── terraform/           # Terraform code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
└── ansible/            # Ansible code
    ├── playbook.yml
    ├── inventory/
    └── ...
```

---

## 🏗️ Architecture Overview

```
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│          Spacelift                  │
│                                     │
│  ┌─────────────────┐               │
│  │  Terraform      │               │
│  │  Stack          │               │
│  │  (Provisions)   │               │
│  └────────┬────────┘               │
│           │                         │
│           │ Outputs (IPs, IDs)     │
│           ▼                         │
│  ┌─────────────────┐               │
│  │  Ansible        │               │
│  │  Stack          │               │
│  │  (Configures)   │               │
│  └─────────────────┘               │
│                                     │
└─────────────────────────────────────┘
           │
           ▼
    ☁️ Cloud Provider (AWS/Azure/GCP)
```

**How it works:**
1. You push code to GitHub
2. Spacelift detects changes
3. Terraform stack runs first (creates infrastructure)
4. Terraform outputs instance IPs/IDs
5. Ansible stack automatically triggers
6. Ansible receives IPs/IDs and configures instances

---

## 📖 Step-by-Step Setup

### Step 1: Connect GitHub to Spacelift

#### 1.1 Start Integration
1. Log into Spacelift: `https://[your-account].app.spacelift.io`
2. Click hamburger menu (☰) → **"Integrations"** → **"Source Control"**
3. Click **"GitHub"** card → **"Set up GitHub"**
4. Choose **"Set up via wizard (recommended)"**

#### 1.2 Configure Integration
1. Select **GitHub.com**
2. Choose **personal** or **organization** account
3. Click **"Continue"**

#### 1.3 Create GitHub App
1. Enter a unique name (e.g., `spacelift-integration-myproject`)
   - ⚠️ **Note**: This name cannot be changed later!
2. Choose **Integration type**: "Default (all spaces)"
3. Click **"Create GitHub app"**

#### 1.4 Authorize on GitHub
1. You'll be redirected to GitHub
2. Select which repositories Spacelift can access
3. Click **"Install & Authorize"**

✅ **Success!** GitHub is now connected to Spacelift.

---

### Step 2: Create a Context for Shared Configuration

**What's a Context?** Think of it as a shared storage for credentials and settings that multiple stacks can use.

#### 2.1 Create the Context
1. Click hamburger menu → **"Contexts"**
2. Click **"Create context"**
3. Fill in:
   - **Name**: `ssh-and-cloud-config`
   - **Description**: "SSH keys and cloud credentials"
   - **Space**: Select your space
4. Click **"Create"**

#### 2.2 Add SSH Private Key (for Ansible)
1. In your context, click **"Mounted files"** tab
2. Click **"Add mounted file"**
3. Fill in:
   - **Path**: `/mnt/workspace/ssh-key`
   - **Content**: Paste your **SSH private key** (entire content of `~/.ssh/id_rsa`)
   - **Mark as secret**: ✅ Check this box
4. Click **"Save"**

**How to get your SSH private key:**
```bash
# Linux/Mac
cat ~/.ssh/id_rsa

# Windows PowerShell
Get-Content ~\.ssh\id_rsa
```

#### 2.3 Add Environment Variables
1. Click **"Environment"** tab
2. Add these variables:

| Variable Name | Value | Secret? | Purpose |
|--------------|-------|---------|---------|
| `TF_VAR_public_key` | Your SSH **public key** content | No | Terraform will deploy this to instances |
| `ANSIBLE_PRIVATE_KEY_FILE` | `/mnt/workspace/ssh-key` | No | Tells Ansible where to find the key |
| `ANSIBLE_HOST_KEY_CHECKING` | `False` | No | Disables host key checking |
| `AWS_ACCESS_KEY_ID` | Your AWS access key | ✅ Yes | For Terraform to access AWS |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | ✅ Yes | For Terraform to access AWS |
| `AWS_DEFAULT_REGION` | `us-east-1` (or your region) | No | AWS region to deploy to |

**How to get your SSH public key:**
```bash
# Linux/Mac
cat ~/.ssh/id_rsa.pub

# Windows PowerShell
Get-Content ~\.ssh\id_rsa.pub
```

It looks like: `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... user@hostname`

✅ **Success!** Your shared configuration is ready.

---

### Step 3: Create Terraform Stack

#### 3.1 Start Stack Creation
1. Click **"Stacks"** in the sidebar
2. Click **"Add stack"**

#### 3.2 Configure Stack Basics
1. **Name**: `terraform-infrastructure`
2. **Space**: Select your space
3. Click **"Continue"**

#### 3.3 Connect to GitHub Repository
1. **VCS Provider**: Select your GitHub integration
2. **Repository**: Select your repository
3. **Branch**: `main` (or your default branch)
4. **Project root**: `terraform` (path to your Terraform code in the repo)
5. Click **"Continue"**

#### 3.4 Configure Backend
1. Choose **"Spacelift managed state"** (recommended)
2. Click **"Continue"**

#### 3.5 Define Behavior
1. **Vendor**: Select **"Terraform"**
2. **Terraform version**: Choose your version (or "Latest")
3. **Autodeploy**: Leave **unchecked** (you'll trigger manually at first)
4. Click **"Continue"**

#### 3.6 Review and Create
1. Review all settings
2. Click **"Create stack"**

#### 3.7 Attach Context
1. In your new stack, click **"Contexts"** tab
2. Click **"Attach context"**
3. Select `ssh-and-cloud-config`
4. Set **Priority**: `0`
5. Click **"Attach"**

✅ **Success!** Terraform stack is ready.

---

### Step 4: Create Ansible Stack

#### 4.1 Start Stack Creation
1. Click **"Add stack"** again

#### 4.2 Configure Stack Basics
1. **Name**: `ansible-configuration`
2. **Space**: Same space as Terraform stack
3. Click **"Continue"**

#### 4.3 Connect to GitHub Repository
1. **VCS Provider**: Your GitHub integration
2. **Repository**: Same repository
3. **Branch**: `main`
4. **Project root**: `ansible` (path to your Ansible code)
5. Click **"Continue"**

#### 4.4 Configure Backend
1. Not applicable for Ansible
2. Click **"Continue"**

#### 4.5 Define Behavior
1. **Vendor**: Select **"Ansible"**
2. **Playbook**: Enter your playbook filename (e.g., `site.yml` or `playbook.yml`)
3. Click **"Continue"**

#### 4.6 Review and Create
1. Review settings
2. Click **"Create stack"**

#### 4.7 Attach Context
1. Click **"Contexts"** tab
2. Click **"Attach context"**
3. Select `ssh-and-cloud-config`
4. Set **Priority**: `0`
5. Click **"Attach"**

✅ **Success!** Ansible stack is ready.

---

### Step 5: Configure Stack Dependencies (The Magic!)

This is where automation happens! We'll make Ansible run automatically after Terraform succeeds.

#### 5.1 Add Dependency
1. Go to your **Terraform stack** (`terraform-infrastructure`)
2. Click **"Dependencies"** tab
3. Click **"Add dependency"**
4. Select your `ansible-configuration` stack
5. Click **"Add"**

#### 5.2 Map Terraform Outputs to Ansible Inputs

**Important**: Your Terraform code must have outputs defined. For example, in `outputs.tf`:
```hcl
output "instance_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.example[*].public_ip
}

output "instance_ids" {
  description = "Instance IDs"
  value       = aws_instance.example[*].id
}
```

Now map these outputs:

1. In the Dependencies section, click **"Add output reference"**
2. Configure:
   - **Output name**: `instance_ips` (from Terraform)
   - **Input name**: `INSTANCE_IPS` (environment variable for Ansible)
   - **Trigger always**: Leave unchecked (Ansible only runs if IPs change)
3. Click **"Save"**
4. Repeat for other outputs like `instance_ids`

**What this does:** When Terraform finishes, it sends `instance_ips` to Ansible as the environment variable `INSTANCE_IPS`.

✅ **Success!** Dependency is configured.

---

### Step 6: Deploy! 🚀

#### 6.1 Trigger Terraform Stack
1. Go to your **Terraform stack**
2. Click **"Trigger"** (top right button)
3. Select **"Proposed run"** (this is like `terraform plan`)
4. Wait for the plan to complete

#### 6.2 Review and Confirm
1. Review what Terraform will create
2. Check for any errors
3. If everything looks good, click **"Confirm"**
4. Terraform will now provision your infrastructure

#### 6.3 Watch the Magic Happen
1. Monitor Terraform run until it shows **"Finished"**
2. Automatically, your **Ansible stack** will start!
3. Go to your Ansible stack to see it running
4. Ansible will configure the infrastructure Terraform just created

#### 6.4 Review Results
- Check Terraform logs to see what was created
- Check Ansible logs to see configuration tasks
- Both stacks should show **"Finished"** status

🎉 **Success!** Your infrastructure is provisioned AND configured!

---

## 🔧 Troubleshooting

### Problem 1: "No value for required variable"

**Error Message:**
```
Error: No value for required variable
  on variables.tf line 1:
   1: variable "public_key" {
The root module input variable "public_key" is not set
```

**Solution:**
1. Go to your Terraform stack → **"Environment"** tab
2. Add variable:
   - **Name**: `TF_VAR_public_key`
   - **Value**: Your SSH public key content
3. Trigger a new run

**Why it happens:** Terraform needs your SSH public key to deploy to instances, but you didn't provide it.

---

### Problem 2: Ansible Can't Connect to Instances

**Error Message:**
```
UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

**Solution:**
1. Verify your SSH private key is in the context at `/mnt/workspace/ssh-key`
2. Check that `ANSIBLE_PRIVATE_KEY_FILE` points to `/mnt/workspace/ssh-key`
3. Ensure AWS security groups allow SSH (port 22) from Spacelift IPs
4. Verify the key pair matches (public key on instance, private key in Spacelift)

---

### Problem 3: Ansible Stack Doesn't Auto-Trigger

**Symptoms:** Terraform finishes but Ansible doesn't start

**Solution:**
1. Check that Terraform run was **successful** (not failed/discarded)
2. Verify dependency is configured in Terraform stack → **"Dependencies"** tab
3. Check that output references are correctly mapped
4. Ensure both stacks are in the same Space

---

### Problem 4: Missing Terraform Outputs

**Symptoms:** Ansible runs but doesn't have IP addresses

**Solution:**
1. Check that your Terraform code has `outputs.tf` with proper outputs
2. Go to Terraform stack → **"Dependencies"** tab → verify output references
3. Ensure outputs are not null (check Terraform logs)

---

### Problem 5: AWS Credentials Invalid

**Error Message:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solution:**
1. Go to your context → **"Environment"** tab
2. Verify these are set correctly:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_DEFAULT_REGION`
3. Test credentials locally: `aws sts get-caller-identity`

---

## 💡 Key Concepts

### What is a Stack?
A **stack** is Spacelift's representation of your infrastructure code. It connects your GitHub repository to your cloud provider. Think of it as a pipeline for your code.

### What is a Context?
A **context** is a shared storage for configuration. Instead of adding the same credentials to 10 different stacks, you add them once to a context and attach that context to all 10 stacks.

### What are Dependencies?
**Dependencies** create workflows between stacks. When Stack A finishes, it automatically triggers Stack B and passes data to it. This creates automated pipelines.

### What are Output References?
**Output references** define what data gets passed from one stack to another. For example, Terraform outputs instance IPs, and Ansible receives them as environment variables.

### Understanding SSH Keys

| Key Type | File | Used By | Purpose |
|----------|------|---------|---------|
| **Public Key** | `id_rsa.pub` | Terraform | Deployed TO instances (allows connections) |
| **Private Key** | `id_rsa` | Ansible | Used to connect FROM Spacelift to instances |

Both keys must be from the **same key pair**!

---

## 📚 Additional Resources

### Official Documentation
- [Spacelift GitHub Integration](https://docs.spacelift.io/integrations/source-control/github)
- [Spacelift Ansible Support](https://docs.spacelift.io/vendors/ansible)
- [Stack Dependencies](https://docs.spacelift.io/concepts/stack/stack-dependencies.html)
- [Contexts](https://docs.spacelift.io/concepts/configuration/context.html)

### Helpful Tutorials
- [Using Terraform & Ansible Together](https://spacelift.io/blog/using-terraform-and-ansible-together)
- [Spacelift Getting Started](https://docs.spacelift.io/getting-started)

### Community
- [Spacelift Community Slack](https://spacelift.io/community)
- [GitHub Discussions](https://github.com/spacelift-io)

---

## ✅ Quick Setup Checklist

Use this checklist to track your progress:

- [ ] GitHub integration configured
- [ ] Context created with SSH keys
- [ ] Context has cloud provider credentials
- [ ] Terraform stack created
- [ ] Terraform stack has context attached
- [ ] Ansible stack created
- [ ] Ansible stack has context attached
- [ ] Dependency configured (Terraform → Ansible)
- [ ] Output references mapped
- [ ] First successful Terraform run
- [ ] First successful Ansible auto-trigger
- [ ] Infrastructure verified working

---

## 🤝 Contributing

Found an error or want to improve this guide? Contributions are welcome!

1. Fork the repository
2. Make your changes
3. Submit a pull request

---

## 📝 License

This guide is provided as-is for educational purposes.

---

## 🆘 Need Help?

If you're stuck:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [Spacelift Documentation](https://docs.spacelift.io)
3. Ask in [Spacelift Community Slack](https://spacelift.io/community)
4. Open an issue in this repository

---

**Happy Deploying! 🚀**