# AKS routes through the shared firewall

This standalone Terraform root connects the four dedicated AKS subnets to an **already deployed** VNet Azure Firewall. The separate [azure-firewall](https://github.com/MikeeeGit/azure-firewall) repository owns the firewall, public IPs, inherited policies and rule collections. This root owns only the four route tables and their optional AKS subnet associations.

Supply the applied firewall resource ID. The hub provider reads the actual firewall from Azure and routes use its returned private IP, so a copied example address cannot silently become the next hop. A virtual-hub firewall is not supported by this VNet example.

## Inputs and ownership

Copy terraform.tfvars.example to ignored terraform.tfvars and replace every synthetic ID with applied outputs.

| Input | Applied source |
|---|---|
| firewall_id | azure-firewall firewall_id output |
| pprd/prd.subscription_id | Corresponding workload subscription |
| pprd/prd.resource_group_name | Network vnet-rg output |
| pprd/prd.vnet_id | Network vnet_id output |
| pprd/prd.address_space | Network vnet.address_space output |
| pprd/prd.aks_subnets.aks01/aks02.id | Network subnet_ids entry |
| pprd/prd.aks_subnets.aks01/aks02.address_prefix | Network subnet_address_prefixes entry |

The network pack retains VNet, subnet, NSG, peering and DNS ownership. Keep its AKS route CSVs header-only: only this state may associate these route tables. Application Gateway, firewall, private-endpoint and service subnets receive no route association here.

The three provider aliases use the same authenticated principal with explicit subscription targets. That principal needs Reader on the selected hub firewall, network write access in both spoke scopes and separate backend blob access. Required providers must already be registered. Use a separate state key and Azure AD backend authentication; never share state with networks, firewall or clusters.

## Use the shared delivery pipelines

Copy this entire directory into a separate private consumer root, retaining delivery.azure.json and config/. The hub target is uks/hub; its backend key has an explicit aks-egress component so it cannot collide with the network state. Configure actual tenant/subscription/backend values in delivery.azure.json and config/global.tfvars, then replace config/uks/hub/hub.tfvars with applied network/firewall outputs. Do not also keep terraform.tfvars with conflicting values.

Use the framework's [component caller examples](https://github.com/MikeeeGit/terraform-delivery-templates/tree/v0.3.0/examples/azure/component), selecting hub/uks. The same guarded saved-plan pipeline handles prepare and attach as separate reviewed configuration commits. Its plan/apply identities need the explicit hub/pprd/prd permissions described above. The Terraform delivery contract rejects tenant, region or subscription drift.

## Deployment sequence

1. Apply hub and both spoke networks with peering disabled, then enable and verify all four peering directions. Forwarded traffic must be allowed. The example uses hub 10.80/16, pprd 10.81/16 and prd 10.82/16.
2. Apply azure-firewall after the hub subnet exists. Its full example enables DNS proxy and AKS platform egress for the four AKS subnet ranges. Review actual application/registry/authentication/CDN dependencies and add explicit policy rules there. Policy and diagnostic settings remain in the firewall state.
3. Set both spoke VNet DNS server lists to the firewall_private_ip output and apply the network states. Every private zone needed through that DNS proxy must link to the hub, including the AKS private API zone and separately owned application alias zone.
4. Supply firewall_id here. Leave enable_aks_routes=false, initialize a dedicated backend, review a saved plan, and create the route tables without attaching them:

   ~~~sh
   cp backend.hcl.example backend.local.hcl
   # Replace backend and terraform.tfvars synthetic values before authenticating/planning.
   terraform init -backend-config=backend.local.hcl
   terraform plan -out=egress.tfplan
   terraform apply egress.tfplan
   ~~~

5. Check peering, DNS, NSGs and the applied firewall policy, then explicitly set enable_aks_routes=true. Review and apply a new saved plan. Verify effective routes, DNS and the required outbound destinations from temporary private test NICs in the AKS subnets. A successful apply is not a connectivity test.
6. Pass route_table_ids.pprd or .prd to the corresponding AKS slots. Set userDefinedRouting and the AKS UDR-ready acknowledgement only after the actual path is verified. Remove temporary probes before cluster creation; then verify real node bootstrap, registry pulls and workload egress.

The default and opposite-spoke prefixes use the firewall. Inter-environment traffic remains denied unless the firewall owner explicitly permits it. Reciprocal routes avoid an asymmetric inspected path. More-specific same-VNet and hub/spoke system routes are not automatically forced through this default route. Application Gateway retains its separately supported routing.

## Remove deliberately

Remove applications and AKS clusters before their routes or DNS paths. Disable/remove route associations and this state before deleting the firewall. Remove peering while the network states still exist, then remove the networks. Do not delete state to force ordering.

The former unpublished all-in-one egress example was split into firewall and route ownership before release. If you independently applied that local draft, review state/resource moves or recreate a disposable sandbox before switching to this layout. Do not create a second firewall in an occupied AzureFirewallSubnet.

## Verification and limits

    terraform init -backend=false -lockfile=readonly
    terraform fmt -check -recursive
    terraform validate
    terraform test

Eight provider-mocked tests verify staged attachment, default/peer routes, a changed firewall address, rejection of virtual-hub/wrong resource types and exclusion of Application Gateway subnets. No cloud credentials or live apply are part of CI.

Azure Firewall is a paid prerequisite. It needs workload-specific capacity, monitoring and policy review. See [AKS required outbound traffic](https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress) and [hub/spoke routing](https://learn.microsoft.com/en-us/azure/firewall/firewall-multi-hub-spoke). This example does not claim general Internet access before the firewall and routes are operational.
