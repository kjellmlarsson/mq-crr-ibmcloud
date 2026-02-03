# Instana Agent Configuration

## Field Management

- **Secrets (agent.key, downloadKey)**: Managed via GitOps using the `instana-agent-keys` secret
- **configuration_yaml**: Managed via GitOps from this repository

## Secret Reference

The InstanaAgent CR references the `instana-agent-keys` secret which contains:
- `key`: Instana agent key
- `downloadKey`: Instana download key

The secret is deployed to the `openshift-operators` namespace where the Instana operator runs.
