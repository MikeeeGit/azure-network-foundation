# Publishing and two-host operation

GitHub is the public source and contribution entry point. Azure DevOps hosts matching source and pipeline definitions within AzureInfraCode; project access is required.

Use the same commits and release tags on both remotes. Review contributions on GitHub, run credential-free CI, then publish the reviewed commit to both hosts. Do not maintain independently diverging develop branches on each host.

A develop branch is available for ongoing work; main and versioned releases are the stable consumer path. Modules/templates should use explicit releases or immutable commits. Changing only a Git repository name must never be used as a shortcut to migrate Terraform state.

Release checks:

1. Format/validate the root and run provider-mocked tests.
2. Validate the synthetic target configurations and shared-helper context.
3. Check module/template references against the intended released revisions.
4. Scan tracked files for state, plans, secrets and original estate values.
5. Confirm CI on GitHub and Azure DevOps for the same commit.
6. Publish a release note that states whether a live deployment was performed.

No original Git history, original state or private tfvars are imported into this public repository. Apache-2.0 applies to the published source.
