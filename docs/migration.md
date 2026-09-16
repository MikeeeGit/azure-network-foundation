# Provenance and compatibility

This repository derives from AZ-TF-azvdc at `ed61a1b8fe53c37bc24446f23adfca36203440f7`. GitHub's `3b7be3becf906abfe5cff9167c814e0d36ba5f5a` has the same Terraform/callers plus runner documentation/configuration. The original repositories and their state remain independent.

## v0.2.0 compared with the provisional v0.1.0

The provisional release modeled one network through a different composition. v0.2.0 restores the original operational design:

- Direct VNet/subnet modules, two resource groups and convention-derived names.
- Layered configuration, five synthetic targets and first-class CSV policy files.
- Complete VNet/subnet outputs, DNS records, central hub DNS and optional ACR.
- Bash/PowerShell and both CI platforms through shared delivery templates.

These are breaking interface/state changes from provisional v0.1.0. Start with new state. Do not point this root at an existing deployment and apply without an individually reviewed migration.

## Deliberate changes from the original

- Estate values, backend names and source references become public examples or inputs.
- Module references use the v0.2.0 release rather than a moving develop branch.
- The caller-supplied region code is honored, enabling additional regions.
- Diagnostics workspace and optional single-zone selector are forwarded correctly.
- Empty private DNS zones can be supplied through the formerly unused list.
- Explicit peer topology replaces hardcoded backend naming and one-spoke selection.
- Peerings are initially disabled so networks can be created before their states are read.
- Optional spoke DNS links make central private endpoint resolution ownership explicit.
- ACR georeplication is implemented and validated.
- Shared delivery adds locking, saved plans, target checks and explicit local confirmation.

Original remote-state/peering resource addresses therefore differ. Even where resource names match, no automatic state migration is claimed. Legacy diagnostic outputs remain for compatibility; state and plan files stay private.

## Original features outside this stack

The reusable wrapper still exists separately. It is not silently inserted between this root and its leaves. Optional Ansible/application deployment helpers belong to separate workflows. This repository does not provision a complete Azure landing zone, management groups, Azure Firewall, VPN gateways, NAT gateways or workloads.
