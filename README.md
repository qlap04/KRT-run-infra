# KRT-run – infra

Azure infrastructure for KRT-run with Bicep, plus the provisioning and destroy pipelines (Azure DevOps).

```
bicep/       stacks/{00-secret,10-network,20-data,30-app,40-apim}/main.bicep (one stack = one subscription-scope deployment), modules/ (shared)
pipelines/   provision.yml (secret, network, data, app), provision-apim.yml, destroy.yml, templates/, variables/<env>.yml
docs/        SETUP_vi.md (Vietnamese setup guide)
```

Deploy order: 00-secret -> 10-network -> 20-data -> 30-app -> 40-apim.
Validate (no deployment): `az bicep build --file bicep/stacks/30-app/main.bicep --stdout > /dev/null` (same for `00-secret`, `10-network`, `20-data`, `40-apim`)
Guide, costs, cleanup: [docs/SETUP_vi.md](docs/SETUP_vi.md). Application code lives in the separate `app` repo.
