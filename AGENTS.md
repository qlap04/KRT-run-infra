# KRT-run – `infra` repo (Bicep + provision/destroy pipelines)

Stack: Bicep, Azure DevOps YAML. Application code lives in the separate `app` repo (it has the `app-deploy` pipeline).
Resources: VNet, App Service Plan + Web App (Node 22), Function App (shares the web plan on B1; Consumption Y1 on F1), Storage (Blob/Queue/Table), APIM Consumption, App Insights (optional).

## Layout
- `bicep/main.bicep` + `bicep/modules/` + `bicep/env/<env>.bicepparam`
- `pipelines/provision.yml`, `pipelines/destroy.yml` (manual only) + `templates/` + `variables/<env>.yml`
- `docs/SETUP_vi.md` – provisioning, cost and cleanup guide (Vietnamese)

## Rules
- NEVER run `az deployment`, `az login`, `terraform apply` or deploy without Kai's explicit OK. Only validate: `az bicep build` / `build-params`.
- No hardcoded secrets; never output secrets from Bicep. Read them with `readEnvironmentVariable()`; the values live in the Azure DevOps variable group `krtrun-<env>`.
- Cheapest SKUs by default (budget < 200k VND/month): APIM Consumption, Y1 when on F1. `dev` now uses App Service plan **B1** (~0.019 USD/h) so VNet integration really works; destroy it after use via the destroy pipeline. On B1+ the function shares the web plan, both route all traffic through the VNet and the storage firewall is Deny (subnet only); on F1 all of that switches off.
- Only `dev` is active. Each environment has its own files `bicep/env/<env>.bicepparam` and `pipelines/variables/<env>.yml`; they must stay in sync.
- If you rename a resource here, update `pipelines/variables/<env>.yml` in the `app` repo too.
- `destroy.yml` is manual only and hardcoded to `dev`; its safety is the approval gate of environment `krtrun-dev`.
- Small, incremental changes. Everything in the system is English (comments, descriptions, displayNames). Only `docs/SETUP_vi.md` is Vietnamese.

## Environments & Git flow
Only `dev` is active for now (ADO Environment `krtrun-dev`, with approval). `main.bicep` still allows the environment names `sit`, `uat`, `preprod`, and `prod` so a later environment can be added without changing the parameter contract.

| Branch | `provision` pipeline runs |
|---|---|
| `develop` | Validate → DEV |

Each deploy stage is a what-if followed by a Deploy through the ADO Environment `krtrun-dev` (approvals are configured in the UI).
- Feature branches start from `develop` (`feature/<name>`) and merge back through a PR.
- To add an environment later: add `pipelines/variables/<env>.yml`, `bicep/env/<env>.bicepparam`, a stage, plus an Azure DevOps Environment and variable group.
