# KRT-run – `infra` repo (Bicep + provision/destroy pipelines)

Stack: Bicep, Azure DevOps YAML. Application code lives in the separate `app` repo (it has the `app-deploy` pipeline).
Resources: VNet, App Service Plan + Web App (Node 22), Function App (Consumption), Storage (Blob/Queue/Table), APIM Consumption, App Insights (optional).

## Layout
- `bicep/main.bicep` + `bicep/modules/` + `bicep/env/<env>.bicepparam`
- `pipelines/provision.yml`, `pipelines/destroy.yml` (manual only) + `templates/` + `variables/<env>.yml`
- `docs/SETUP_vi.md` – provisioning, cost and cleanup guide (Vietnamese)

## Rules
- NEVER run `az deployment`, `az login`, `terraform apply` or deploy without Kai's explicit OK. Only validate: `az bicep build` / `build-params`.
- No hardcoded secrets; never output secrets from Bicep. Read them with `readEnvironmentVariable()`; the values live in the Azure DevOps variable group `krtrun-<env>`.
- Cheapest SKUs by default (budget < 200k VND/month): F1, Y1, APIM Consumption.
- `sit`/`uat`/`preprod` SHARE the `dev` resources (`resourceEnv=dev`) and differ only in `APP_ENV`; only `prod` has its own resources.
- Each environment has its own files `bicep/env/<env>.bicepparam` and `pipelines/variables/<env>.yml`; they must stay in sync.
- If you rename a resource here, update `pipelines/variables/<env>.yml` in the `app` repo too.
- `destroy.yml` is manual only; its safety is the approval gate of environment `krtrun-<env>`.
- Small, incremental changes. Everything in the system is English (comments, descriptions, displayNames). Only `docs/SETUP_vi.md` is Vietnamese.

## Environments & Git flow
| Branch | `provision` pipeline runs |
|---|---|
| `develop` | Validate → DEV |
| `release/*` | Validate → SIT → UAT |
| `main` | Validate → PREPROD → PROD |
| `hotfix/*` | Validate → `targetEnvironment` (chosen manually) → PROD |

Each deploy stage is a what-if followed by a Deploy through the ADO Environment `krtrun-<env>` (approvals are configured in the UI).
- Feature branches start from `develop`; release branches are cut from `develop`; hotfix branches from `main`; when done merge into `main` and `develop`.
- Never push directly to `main` or `develop`.
