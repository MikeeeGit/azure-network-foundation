# Configuration

The deployment identity is **repository + environment + region**. Shared helpers load `config/global.tfvars` first, then `config/<region>/<environment>/<environment>.tfvars`. Later values override earlier values.

## Delivery settings and Terraform settings

`delivery.azure.json` configures helpers/CI: tenant, subscription aliases, environment-to-backend mapping, storage coordinates and the state-key template. It does not create resources. Terraform receives workload settings from the tfvars files.

The root validates that subscription UUIDs in `subscription_id_map` match delivery.azure.json. Update both together; a mismatch stops planning rather than silently overriding the helper-selected target. The selected `subscription` must exist, and `hub` is required for the aliased central-DNS provider. Use a new backend for this new stack.

Backend aliases remain useful: dev can share pprd's backend, shr can share hub's, and bcdr can share prd's. The state key still separates workloads: `azure-network-foundation-<environment>-<region>.tfstate`.

The included IDs end in 001–004 and are synthetic. Example storage names must be replaced with available globally unique names. No real tenant or cloud access is provided.

## Names and ownership

The stack uses `<region>-<environment>` as its label:

- Network resource group: `<label>-netw-rg-01`.
- VNet resource group: `<label>-vnet-rg-01`.
- VNet: `<label>-vnet-01`.
- Regular subnet: `<label>-<logical-name>`.
- Reserved subnet names such as `GatewaySubnet` and `AzureFirewallSubnet` remain exact.

The `company_abbreviation`, `environment_number`, `azvdc_network`, `backend_container_suffix` and `remote_state_container_suffix_map` inputs remain compatibility metadata where retained. Resource names keep their original fixed 01 suffix. Backend naming is controlled by delivery configuration; remote peer backends are explicit. Changing these metadata values alone does not rename resources or reconfigure peer-state access.

## Subnets and CSVs

Each subnet retains the original object shape:

```hcl
subnets = [{
  name           = "web"
  address_prefix = "10.61.1.0/24"
  security_group = "nsg"
  endpoints      = []
}]
```

`security_group` is an enable flag expressed as a string: any nonempty value enables the conventionally named NSG; an empty string disables it. The literal string `"false"` is nonempty and therefore enables an NSG. Use an empty string for GatewaySubnet and Azure firewall reserved subnets.

The module loads:

```text
config/<region>/<environment>/<environment>_<logical-name>_nsg.csv
config/<region>/<environment>/<environment>_<logical-name>_route_table.csv
```

NSG columns:

```csv
name,priority,direction,access,protocol,source_port_range,destination_port_range,source_address_prefix,destination_address_prefix
Allow-HTTPS-From-VNet,100,Inbound,Allow,Tcp,*,443,VirtualNetwork,VirtualNetwork
```

Route columns:

```csv
name,address_prefix,next_hop_type,next_hop_in_ip_address
Discard-Unused-Example-Range,10.255.0.0/16,None,
```

The synthetic example permits HTTPS from the virtual network and discards an unused example range. It is a demonstration of the policy interface. Design rules for your actual workload. Reserved-subnet CSVs are header-only.

Optional per-subnet settings include default_outbound_access_enabled, private_endpoint_network_policies, private_link_service_network_policies_enabled, service_endpoint_policy_ids, bgp_route_propagation_enabled and delegation. They are forwarded to the subnet module.

A route to Internet does not provide outbound address translation. This edition preserves the original optional subnet outbound setting rather than silently enabling or disabling it; configure an explicit supported egress design for workloads that need internet access.

## DNS, diagnostics and optional services

`dns` and `private_dns` retain the original zone-with-records object interface. `private_dns_zones` can add empty private zones without repeating the record fields. Duplicate zone names are avoided when combining these inputs.

Set `diag_log_workspace` to a Log Analytics resource ID to enable VNet diagnostics. Null disables diagnostics. The stack does not create or guess a workspace. `ddos_plan_id` attaches an existing plan when provided.

Private endpoints use logical subnet keys and look up external zones in the hub subscription. A zone created by this same hub stack is consumed directly from the VNet module, so a new zone and endpoint can be planned together. By default the DNS resource group is `<region>-hub-vnet-rg-01`; `hub_dns_resource_group_name` overrides it. Set `link_endpoint_dns_zones=true` only when this spoke should own the central-zone links. Otherwise configure existing links or resolver forwarding. Avoid two Terraform states managing the same link.

ACR is disabled by default. Georeplication is implemented when `acr_config.sku="Premium"`; non-Premium replication is rejected. Admin credentials are disabled in the example. Registry names must be globally unique.

See [deployment](deployment.md) for topology ownership and first-run ordering.
