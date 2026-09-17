# Changelog

## 0.3.0

- Add a complete hub and two-spoke configuration pack with dual-AKS, gateway and private-endpoint subnets.
- Add shared-pipeline delivery configuration and target binding for the route-only state.
- Enable a shared example ACR with admin access disabled and expose its login server.
- Add staged AKS route attachment that reads actual next hops from the separately owned Azure Firewall stack.
- Allow spokes to link hub private DNS zones without creating private endpoints.
- Expose zone-name keyed DNS outputs while preserving existing endpoint-keyed outputs.
- Allow an explicit CSV configuration root and reject environment/subscription alias drift.
- Test the published configurations, DNS behavior and egress topology with mocked providers.

Existing inputs keep their defaults. The expanded pack uses new address spaces; use new state or a reviewed migration when adopting it for an existing deployment. These tests do not establish live Azure connectivity.

## 0.2.0

Rebuild the public stack from the reviewed AZ-TF-azvdc architecture.

- Restore direct leaf-module calls, two resource groups, original naming and full resource outputs.
- Restore multi-environment/region tfvars and CSV network policies with synthetic examples.
- Preserve DNS records, DDoS settings, diagnostics, central private endpoints and optional ACR.
- Add explicit topology and a bootstrap phase, optional central DNS spoke links and ACR georeplication.
- Preserve logical subnet keys when resolving private endpoints.
- Reject subscription-map drift between Terraform and shared delivery configuration.
- Forward diagnostics/DNS inputs and validate subscription, CIDR, endpoint and registry settings.
- Add integrated provider-mocked regression tests and first-deployment/operating documentation.
- Consume the matching shared delivery and leaf-module release.

Breaking changes from provisional 0.1.0: restored interfaces and resource addresses require new state or a separately reviewed migration. The original private repositories were not changed. Validation does not represent a live Azure deployment.

## 0.1.0

Initial provisional public baseline, superseded by the faithful reconstruction in 0.2.0.
