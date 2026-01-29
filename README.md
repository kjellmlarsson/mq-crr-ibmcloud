# IBM MQ Cross-Region Replication on IBM Cloud

This repository demonstrates IBM MQ Cross-Region Replication (CRR) between two OpenShift clusters deployed on IBM Cloud, using a GitOps approach with ArgoCD and Kustomize.

## Overview

This project implements a highly available IBM MQ deployment across two geographic regions using:

- **IBM MQ Native HA with CRR**: Queue managers replicated across regions for disaster recovery
- **Uniform Clusters**: Two queue managers (QM1 and QM2) configured in a uniform cluster
- **GitOps Deployment**: ArgoCD-based continuous deployment
- **Kustomize**: Configuration management with environment-specific overlays
- **OpenShift**: Container platform with IBM Cloud infrastructure

### Architecture

The deployment consists of:

- **Two Regions**: Frankfurt (recovery) and Madrid (live)
- **Two Queue Managers per Region**: QM1 and QM2 in a uniform cluster
- **CRR Configuration**: Live/Recovery roles for cross-region replication
- **Storage**: OpenShift Data Foundation (ODF) for persistent storage
- **Monitoring**: Prometheus metrics, OpenTelemetry tracing, and IBM License Service

## Repository Structure

```
mq-crr-ibmcloud/
├── argocd/                    # ArgoCD application definitions
│   ├── common/                # Common infrastructure applications
│   └── operands/              # Region-specific operand applications
├── components/                # Reusable Kustomize components
│   ├── common/                # Common infrastructure (namespace, operators)
│   ├── mq/                    # MQ queue manager configurations
│   │   ├── base/              # Base MQ configurations
│   │   │   └── uniform-cluster-a/  # Uniform cluster setup
│   │   ├── operator/          # MQ operator subscription
│   │   └── variants/          # Configuration variants
│   │       ├── cloudprovider/ # Cloud-specific storage classes
│   │       ├── crr/           # CRR live/recovery configurations
│   │       ├── nonprod/       # Non-production settings
│   │       └── region/        # Region-specific settings
│   ├── cert-utils/            # Certificate utilities
│   ├── license-service/       # IBM License Service
│   ├── openshift-cert-manager/ # Certificate management
│   ├── openshift-monitoring/  # Monitoring configuration
│   ├── openshift-telemetry/   # OpenTelemetry setup
│   └── reloader/              # Configuration reloader
├── envs/                      # Environment-specific configurations
│   └── odf/                   # ODF storage environments
│       ├── frankfurt/         # Frankfurt region (recovery)
│       └── madrid/            # Madrid region (live)
├── media/                     # Documentation images
└── sample/                    # Sample configurations
```

## Prerequisites

- Two OpenShift clusters
- OpenShift Data Foundation (ODF) installed on both clusters
- ArgoCD installed on both clusters
- IBM MQ Operator available in cluster catalog
- `oc` CLI tool installed
- Access to IBM Entitled Registry

## Key Components

### Queue Managers

Two queue managers (QM1 and QM2) are deployed in each region:

- **Native HA**: High availability within a region
- **CRR**: Cross-region replication for disaster recovery
- **Uniform Cluster**: Automatic workload balancing between queue managers

### CRR Roles

Queue managers can operate in two roles:

- **Live**: Actively processing messages (Madrid by default)
- **Recovery**: Standby mode, receiving replicated data (Frankfurt by default)

Role configuration is managed through Kustomize variants in [`components/mq/variants/crr/`](components/mq/variants/crr/).

## Deployment

### Initial Setup

1. **Fork or clone this repository**

2. **Update ArgoCD source repository**

   Edit the `repoURL` field in both bootstrap files to point to your Git repository:
   - [`argocd/bootstrap-madrid.yaml`](argocd/bootstrap-madrid.yaml)
   - [`argocd/bootstrap-frankfurt.yaml`](argocd/bootstrap-frankfurt.yaml)

3. **Configure region-specific settings**

   Update the following files for each region:
   - [`envs/odf/frankfurt/mq/`](envs/odf/frankfurt/mq/) - Frankfurt configuration
   - [`envs/odf/madrid/mq/`](envs/odf/madrid/mq/) - Madrid configuration

4. **Update TLS certificates**

   Modify certificate patches in each environment:
   - `external-tls-qm1-patch.yaml`
   - `external-tls-qm2-patch.yaml`
   - `remote-qm1-patch.yaml`
   - `remote-qm2-patch.yaml`

### Deploy to Madrid (Live Region)

```bash

# Apply bootstrap application
oc apply -f argocd/bootstrap-madrid.yaml

```

### Deploy to Frankfurt (Recovery Region)

```bash
# Apply bootstrap application
oc apply -f argocd/bootstrap-frankfurt.yaml
```

### Verify Deployment

```bash
# Check queue manager status
oc get queuemanager -n cp4i

# Check pod status
oc get pods -n cp4i

# Check CRR status
oc describe queuemanager qm1 -n cp4i
oc describe queuemanager qm2 -n cp4i
```

## Configuration Management

### Kustomize Structure

The project uses Kustomize components and overlays:

- **Base**: Common configurations in [`components/mq/base/`](components/mq/base/)
- **Components**: Reusable configuration variants
- **Overlays**: Environment-specific customizations in [`envs/`](envs/)

### Environment Customization

Each environment ([`envs/odf/frankfurt/`](envs/odf/frankfurt/) and [`envs/odf/madrid/`](envs/odf/madrid/)) includes:

```yaml
components:
  - ../../../../components/mq/variants/cloudprovider/odf
  - ../../../../components/mq/variants/nonprod
  - ../../../../components/mq/variants/region/madrid
  - ../../../../components/mq/variants/crr/live  # or crr/recovery

resources:
  - ../../../../components/mq/base

patches:
  - target: ...
    path: remote-qm1-patch.yaml
```

## Disaster Recovery

### Switchover

To switch the live region from Madrid to Frankfurt, use the automated GitHub Action:

1. **Trigger the Switchover Workflow**
   - Navigate to the **Actions** tab in your GitHub repository
   - Select the **MQ-switchover-PR** workflow
   - Click **Run workflow** on the main branch

2. **Review the Generated Pull Request**
   - The workflow automatically creates a PR that swaps the CRR roles:
     - Madrid: `crr/live` → `crr/recovery`
     - Frankfurt: `crr/recovery` → `crr/live`
   - Review the changes in the PR to ensure correctness

3. **Merge the Pull Request**
   - Once reviewed and approved, merge the PR
   - ArgoCD will automatically sync the new configuration
   - Queue managers will switch roles

**Manual Alternative**: If you prefer manual control, you can:
1. Update Madrid environment to use `crr/recovery` variant in [`envs/odf/madrid/mq/kustomization.yaml`](envs/odf/madrid/mq/kustomization.yaml)
2. Update Frankfurt environment to use `crr/live` variant in [`envs/odf/frankfurt/mq/kustomization.yaml`](envs/odf/frankfurt/mq/kustomization.yaml)
3. Commit and push changes
4. ArgoCD will sync the new configuration

**GitHub Action Details**: The workflow is defined in [`.github/workflows/create-mq-switchover-pr.yaml`](.github/workflows/create-mq-switchover-pr.yaml) and uses `sed` to swap all occurrences of `crr/live` and `crr/recovery` in environment kustomization files.

## Additional Resources

- [IBM MQ Documentation](https://www.ibm.com/docs/en/ibm-mq/9.4)
- [MQ Operator Release History](https://www.ibm.com/docs/en/ibm-mq/9.4?topic=operator-release-history-mq)
- [MQ Licensing Reference](https://www.ibm.com/docs/en/ibm-mq/9.4?topic=mqibmcomv1beta1-licensing-reference)
- [Connecting to MQ in OpenShift](https://community.ibm.com/community/user/integration/blogs/callum-jackson1/2021/02/15/connecting-to-a-queue-manager-running-in-openshift)
- [CP4I MQ Samples](https://github.com/ibm-messaging/cp4i-mq-samples)
- [MQ Container MFT](https://github.com/ibm-messaging/mq-container-mft)