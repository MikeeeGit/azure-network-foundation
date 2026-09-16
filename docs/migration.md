# From the existing AZ-TF repositories

These are fresh public repositories with new Git histories and explicit APIs. Existing source repositories and live state are not changed.

| Previous concern | New design |
| --- | --- |
| AZDO-specific naming | terraform-delivery-templates with separate CI adapters |
| AZ-TF-azvdc deployment | azure-network-foundation |
| AZ-TF-MOD-azvdc wrapper | terraform-azurerm-network-foundation |
| Branch-based child module references | Immutable Git revisions |
| Implicit CSV paths and region/environment name logic | Typed maps and exact resource names |
| Hardcoded Log Analytics workspace | Optional supplied workspace ID |
| Reading other environments' complete Terraform state | Explicit network IDs and caller-owned peering |
| Mixed network, DNS records and ACR management | Focused network foundation; other concerns stay separate |

Do not reuse the original backend and run apply. New resource addresses and names can produce replacements. Migrate only after a resource-by-resource state inventory, imports or reviewed moved blocks, a saved plan with no unexpected replacements, and a rollback/recovery plan. No automatic state migration script is supplied.

The public baseline intentionally omits private configuration, original history, employer/client documentation, tenant identifiers and destructive convenience scripts. Synthetic examples do not reproduce a real estate.
