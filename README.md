# KRT-run – infra

Azure infrastructure for KRT-run with Bicep, plus the provisioning and destroy pipelines (Azure DevOps).

```
bicep/       main.bicep, modules/, env/<env>.bicepparam (dev, sit, uat, preprod, prod)
pipelines/   provision.yml, destroy.yml, templates/, variables/<env>.yml
docs/        SETUP_vi.md (Vietnamese setup guide)
```

Validate (no deployment): `az bicep build --file bicep/main.bicep --stdout > /dev/null`
Guide, costs, cleanup: [docs/SETUP_vi.md](docs/SETUP_vi.md). Application code lives in the separate `app` repo.
