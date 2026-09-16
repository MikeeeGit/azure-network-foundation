# Deployment and daily operations

## From an empty subscription

Complete the [shared bootstrap guide](https://github.com/MikeeeGit/terraform-delivery-templates/blob/v0.2.0/docs/getting-started.md) first. Backend storage and the deployment identities must exist before normal remote-state initialization.

Select a subset of the examples appropriate to your estate. For the full demonstration:

1. Keep `enable_peerings=false` in all five tfvars files. Apply uks/hub, ukw/hub, uks/pprd, uks/prd and ukw/bcdr through reviewed plans. No remote-state data sources are read in this phase.
2. Verify all referenced backend coordinates and state keys in `remote_networks`.
3. Set `enable_peerings=true` for the selected networks. Plan/apply their local peerings.
4. The uks hub owns its pprd/prd sides; each spoke owns its hub side. The ukw hub owns its bcdr side. The secondary hub also owns both inter-hub sides through its explicitly enabled reverse-hub entry.
5. Verify peering status and DNS resolution from a test workload. Mock tests cannot establish connectivity.

There is no automatic peering to an unlisted network. Every intended connection is visible in `remote_networks`. This removes the original one-spoke-per-region assumption and makes bootstrap deliberate.

## Remote-state topology

Each map entry supplies the other network's Azure backend coordinates and local peering settings. The other state must export `vnet_id` and the complete `vnet` object, as this stack does. Address-space hashes trigger peering synchronization when a remote range changes. Apply the remote network first, then plan/apply its consumers.

The remote-state data source uses Microsoft Entra blob authentication. The caller needs access to those state blobs as well as appropriate network permissions. State can contain more information than the outputs you consume, so grant access accordingly.

`create_reverse_hub_peering` is opt-in. It uses the hub provider and rejects a remote VNet outside the configured hub subscription. For other subscriptions, manage the reciprocal side from that environment's own state. Never create two owners for the same peering.

Gateway transit is exposed but does not deploy a gateway. Keep `use_remote_gateways=false` until an appropriate gateway exists and the hub side permits transit.

## Daily local flow

```bash
tf_setup azure-network-foundation pprd uks
tf_init
tf_plan
tf_apply
```

Switching selectors changes the backend/state identity. Run setup/init before planning the new target. The helpers guard against using an earlier target's saved plan. Ordinary init does not upgrade dependencies; use an explicit dependency-upgrade workflow and review the lockfile.

After a CSV edit, plan the selected environment and review rule removals as well as additions. Keep plans and state out of Git. Use ignored local overrides for private values and maintain your deployment copy privately.

The PowerShell helper commands follow the same targeting and saved-plan contract. The shared documentation explains GitHub dispatch/watch helpers and CI configuration.

## CI use

This public repository runs backend-free validation and mocked tests on pull requests and pushes. It has no Azure identity or backend access.

For a deployment repository, consume the shared Azure delivery workflow or Azure DevOps templates and configure its identities, protected environments and backend. Use the examples shipped in the shared framework for exact parameters. Configure approvals in the CI service; an environment name in YAML does not itself create an approval policy.

## Removal

Do not delete a remote state or network while other states still manage peerings to it. Plan removal of both peering sides first, then remove endpoint/zone-link dependencies and the network. Review Terraform destroy output explicitly. The framework does not run destruction from public PRs.

## Resource provider registration

Before the first deployment, an operator with registration permissions must register `Microsoft.Network` and `Microsoft.Insights` in each target subscription, and `Microsoft.ContainerRegistry` when enabling ACR. The default and hub providers use `resource_provider_registrations = "none"` so a plan identity with Reader does not need registration permissions. Register the relevant namespaces before granting the narrower CI roles.
