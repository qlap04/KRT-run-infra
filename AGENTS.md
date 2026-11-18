# KRT-run – `infra` repo (Bicep + provision/destroy pipelines)

Stack: Bicep, Azure DevOps YAML. Application code lives in the separate `app` repo (it has the `app-deploy` pipeline).
Resources: VNet, App Service Plan + Web App (Node 22), Function App (shares the web B1 plan), Storage account only (the app creates its Blob container `proofs`, Queue and Tables at startup), APIM Consumption with a global CORS policy for the frontend origin, Static Web Apps Free for the React frontend (region `eastasia`; SWA has no australiaeast). No Application Insights (cost).

## Layout
- `bicep/main.bicep` (subscription scope: creates `rg-<prefix>-<env>`, then calls `network.bicep` and `app.bicep`) + `bicep/apim.bicep` (separate APIM stack in `rg-<prefix>-<env>-apim`, own pipeline `provision-apim.yml`, run after the app stack) + `bicep/modules/` + `bicep/env/<env>.bicepparam`
- `pipelines/provision.yml` (network + app), `pipelines/provision-apim.yml` (APIM), `pipelines/destroy.yml` (manual only) + `templates/` + `variables/<env>.yml`
- `docs/SETUP_vi.md` – provisioning, cost and cleanup guide (Vietnamese)

## Rules
- NEVER run `az deployment`, `az login`, `terraform apply` or deploy without Kai's explicit OK. Only validate: `az bicep build` / `build-params`.
- No hardcoded secrets; never output secrets from Bicep. App secrets (SESSION_SECRET, ADMIN_CODE, API_KEY) are business config: the app repo's pipeline sets them as app settings, so infra Bicep and pipelines never take them.
- Cheapest SKUs by default (budget < 200k VND/month): APIM Consumption. `dev` uses App Service plan **B1** (~0.019 USD/h) so VNet integration really works; destroy it after use via the destroy pipeline. The function shares the web plan, both route all traffic through the VNet and storage is private-only (public access disabled; private endpoints for blob/queue/table in `snet-pe` + `privatelink.*` Private DNS zones linked to the VNet).
- Only `dev` is active. Each environment has its own files `bicep/env/<env>.bicepparam` and `pipelines/variables/<env>.yml`; they must stay in sync.
- If you rename a resource here, update `pipelines/variables/<env>.yml` in the `app` repo too.
- `destroy.yml` is manual only and hardcoded to `dev`; its safety is the approval gate of environment `krtrun-dev`.
- Small, incremental changes. Everything in the system is English (comments, descriptions, displayNames). Only `docs/SETUP_vi.md` is Vietnamese.

## Environments & Git flow
Only `dev` is active for now (ADO Environment `krtrun-dev`, with approval). `main.bicep` still allows the environment names `sit`, `uat`, `preprod`, and `prod` so a later environment can be added without changing the parameter contract.

| Branch | `provision` pipeline runs |
|---|---|
| `develop` | DEV (approval, then lint → what-if → deploy) |

One stage, one deployment job on the ADO Environment `krtrun-dev` (approvals are configured in the UI). Stages and jobs are declared in provision.yml / provision-apim.yml; the reusable work is one step template, pipelines/templates/steps/bicep-deployment.yml (lint + build-params, what-if, deploy at subscription scope), so other repos call a single template inside their own job. The service connection is set per environment in variables/<env>.yml and passed as `${{ variables.serviceConnection }}`, because service connections are resolved at compile time.
- Feature branches start from `develop` (`feature/<name>`) and merge back through a PR.
- To add an environment later: add `pipelines/variables/<env>.yml`, `bicep/env/<env>.bicepparam`, a stage, plus an Azure DevOps Environment and variable group.
