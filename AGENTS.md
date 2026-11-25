# KRT-run – `infra` repo (Bicep + provision/destroy pipelines)

Stack: Bicep, Azure DevOps YAML. Application code lives in the separate `app` repo (it has the `app-deploy` pipeline).
Resources: VNet, App Service Plan + Web App (Node 22), Function App (shares the web B1 plan), Storage account only (the app creates its Blob container `proofs`, Queue and Tables at startup), APIM Consumption with a global CORS policy for the frontend origin, Static Web Apps Free for the React frontend (region `eastasia`; SWA has no australiaeast). No Application Insights (cost).

## Layout
- `bicep/stacks/<nn>-<stack>/main.bicep`: one stack = one subscription-scope deployment = one pipeline; the number is the deploy order (`00` is reserved for a future secrets stack). Order: `10-network` (`provision-network.yml`: creates `rg-<prefix>-<env>`, VNet, subnets, Private DNS zones) -> `30-app` (`provision.yml`: same RG, `app.bicep`; builds the network ids with `appNetworkIds()` from `bicep/modules/naming.bicep`, no lookup) -> `40-apim` (`provision-apim.yml`: `rg-<prefix>-<env>-apim`). Every module, including `modules/compute/apim.bicep`, lives in `bicep/modules/`. There are no `.bicepparam` files.
- `pipelines/provision-network.yml`, `provision.yml` (app), `provision-apim.yml`, `destroy.yml` (manual only) + `templates/` + `variables/<env>.yml`. Each provision pipeline triggers on its own stack folder, `bicep/modules/**`, `pipelines/templates/**` and `pipelines/variables/**`; no exclude lists. A new stack gets its own folder and pipeline, existing pipelines stay untouched.
- `docs/SETUP_vi.md` – provisioning, cost and cleanup guide (Vietnamese)

## Rules
- NEVER run `az deployment`, `az login`, `terraform apply` or deploy without Kai's explicit OK. Only validate: `az bicep lint` / `az bicep build`.
- No hardcoded secrets; never output secrets from Bicep. App secrets (SESSION_SECRET, ADMIN_CODE, API_KEY) are business config: the app repo's pipeline sets them as app settings, so infra Bicep and pipelines never take them.
- Cheapest SKUs by default (budget < 200k VND/month): APIM Consumption. `dev` uses App Service plan **B1** (~0.019 USD/h) so VNet integration really works; destroy it after use via the destroy pipeline. The function shares the web plan, both route all traffic through the VNet and storage is private-only (public access disabled; private endpoints for blob/queue/table in `snet-pe` + `privatelink.*` Private DNS zones linked to the VNet).
- Only `dev` is active. Bicep parameters come from `pipelines/variables/common.yml` and `<env>.yml`: the pipelines pass them inline (`parameters` of the step template). Parameters without an environment-specific value (SKU, address ranges) keep their defaults in the stack `main.bicep`. The APIM secret `GATEWAY_SECRET` is passed as `$(GATEWAY_SECRET)` from the variable group (masked in logs).
- If you rename a resource here, update `pipelines/variables/<env>.yml` in the `app` repo too.
- `destroy.yml` is manual only and loads `variables/dev.yml`; its safety is the approval gate of the environment `<projectName>-<environment>` (`krtrun-dev`).
- Small, incremental changes. Everything in the system is English (comments, descriptions, displayNames). Only `docs/SETUP_vi.md` is Vietnamese.

## Environments & Git flow
Only `dev` is active for now (ADO Environment `krtrun-dev`, with approval). The stacks still allow the environment names `sit`, `uat`, `preprod`, and `prod` so a later environment can be added without changing the parameter contract.

| Branch | `provision` pipeline runs |
|---|---|
| `develop` | DEV (approval, then lint → what-if → deploy) |

One stage, one deployment job on the ADO Environment `krtrun-dev` (approvals are configured in the UI). Stages and jobs are declared in provision-network.yml / provision.yml / provision-apim.yml; the reusable work is one step template, pipelines/templates/steps/bicep-deployment.yml (lint, what-if, deploy at subscription scope; `templateFile` plus an inline `parameters` object), so other repos call a single template inside their own job. The service connection is set per environment in variables/<env>.yml and passed as `${{ variables.serviceConnection }}`, because service connections are resolved at compile time. The variable group and the ADO Environment are per environment too, named `${{ variables.projectName }}-${{ variables.environment }}` (never hardcode `krtrun-dev`). In the provision pipelines only shared variables (and `templateFile`) are global; variables/<env>.yml and the group are declared on the stage, where these compile-time expressions still resolve.
- Feature branches start from `develop` (`feature/<name>`) and merge back through a PR.
- To add an environment later: add `pipelines/variables/<env>.yml`, a stage per provision pipeline, plus an Azure DevOps Environment and variable group.
