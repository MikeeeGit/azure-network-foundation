# Publishing and dual hosting

GitHub is the canonical public collaboration host. Each repository also has a private Azure Repos counterpart for Azure Pipelines demonstrations.

The public repositories use a fresh Git history with Apache-2.0 licensing. Legacy histories, private configuration and internal documentation are not mirrored.

For the maintainer's working clones, origin points to GitHub and azure points to Azure Repos. Synchronization is explicit:

```sh
git push origin main
git push azure main
git push origin v0.1.0
git push azure v0.1.0
```

Use reviewed PRs and the configured validation policies for future changes. Do not use force pushes or mirror old repository history. A release should identify matching commits on both hosts, pass their credential-free CI, and state real-cloud qualification separately.

GitHub Actions consumers pin both the reusable workflow and its script checkout to the same commit. Azure Pipelines consumers pin their repository resource to that commit and authorize only their own pipeline to read the template repository. Terraform modules also pin child modules by commit SHA.

The Azure repositories are private; public consumers should use the GitHub URLs. There is no automatic cross-host synchronization service and no deployed cloud environment in this public baseline.
