# Trusted deployment caller examples

These files are templates for a **private deployment copy** of azure-network-foundation. They are not active workflows in this public repository.

## GitHub

Copy github/tf-validate.yml and github/tf-apply.yml to .github/workflows in the private consumer. Both are manual workflows. Configure the selected environment/region, plan/apply client IDs and TERRAFORM_DELIVERY_SHA, following the shared first-time guide. Configure the named plan/apply environments and their approvals before enabling apply.

The reusable workflow checks repository privacy, manual dispatch and the allowed branch before selecting deployment runners. Never add authenticated PR triggers or run untrusted code on a persistent self-hosted runner.

## Azure DevOps

Copy azure-devops/plan.yml and apply.yml to the private consumer root and create separate pipeline definitions for them. CI/PR triggers are disabled. The repository resource assumes terraform-delivery-templates is mirrored in the same Azure project; qualify its name with the project if needed and authorize repository access.

Configure plan/apply/backend workload-identity service connections with explicit pipeline authorization, install the Microsoft Terraform extension and set deployment-environment approvals. The example service-connection names are placeholders. Review the hosted/self-hosted pool and backend firewall strategy.

## Shared contract

Both platforms read delivery.azure.json and layer config/global.tfvars with config/<region>/<environment>/<environment>.tfvars. Start with peerings disabled, then enable them after the referenced network states exist.

Use the [shared getting-started guide](https://github.com/MikeeeGit/terraform-delivery-templates/blob/v0.2.0/docs/getting-started.md) and [root deployment order](../../docs/deployment.md). Public CI proves syntax and mocked behavior; running these callers against your own configured Azure environment is a separate validation step.
