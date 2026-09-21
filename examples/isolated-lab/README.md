# Isolated resource names for a disposable lab

Merge [isolation.tfvars.example](isolation.tfvars.example) into a new private consumer's global/target inputs before first deployment. Retain the complete hub/spoke, subscription, CSV and backend configuration. Helpers read only global/selected target tfvars; this file is not loaded automatically.

With `name_prefix = "aks-lab"`, the PPRD target creates:

| Resource | Example name |
| --- | --- |
| Network resource group | `uks-pprd-aks-lab-netw-rg-01` |
| VNet resource group | `uks-pprd-aks-lab-vnet-rg-01` |
| VNet | `uks-pprd-aks-lab-vnet-01` |
| Ordinary `aks01` subnet | `uks-pprd-aks-lab-aks01` |
| Default hub DNS group | `uks-hub-aks-lab-vnet-rg-01` |

Use the same qualifier for hub and selected spokes. An explicit `hub_dns_resource_group_name` overrides the default; use the actual owned/shared DNS group. Reserved Azure subnet names stay exact; logical keys and CSV filenames remain unchanged.

The default empty qualifier preserves existing names. Changing it on managed infrastructure can replace resources; use new state for a separate trial. `company_abbreviation` remains compatibility metadata and does not isolate names. ACR names remain explicit and globally unique. Prefixing does not provide network isolation: review CIDRs, peerings, DNS and access rules.

Use a distinct private repository/state-key namespace. Update every `remote_networks` backend and downstream component ID from actual outputs. The framework backend's separate `resource_group_name_prefix = "aks-lab"` isolates its resource groups; update `delivery.azure.json` and remote-state coordinates from those outputs. Its existing alphanumeric storage `prefix` remains independently globally unique.

See the [Azure worked example](https://github.com/MikeeeGit/terraform-delivery-templates/blob/main/docs/azure/three-tier-worked-example.md). Mock tests verify naming contracts; this input is not evidence of a deployed Azure lab.
