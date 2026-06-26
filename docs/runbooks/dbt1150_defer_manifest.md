# dbt1150 defer manifest issue

## Symptom

dbt Fusion or the VS Code dbt extension fails with:

```text
[ManifestLoadFailed (dbt1150)]: Failed to load manifest.json from state path ... because config.grants is null, expected map.
```

or:

```text
[ManifestLoadFailed (dbt1150)]: Failed to load manifest.json from state path ... config.grants: invalid type: unit value, expected a map
```

Common affected paths:

- `target/dbt_cloud_defer/manifest.json`
- `target/.lsp/dbt_cloud_defer/manifest.json`

`target/dbt_cloud_defer` affects `dbtf build`. `target/.lsp/dbt_cloud_defer` affects the VS Code dbt extension/LSP.

## Common causes

There are two separate issues that can produce similar symptoms:

1. The downloaded defer manifest contains explicit `config.grants: null` values. Fusion expects `config.grants` to be a map, so normalize null grants to `{}`.
2. The downloaded defer manifest is stale or from the wrong dbt Cloud environment. This can happen after project renames or Cloud config changes if Fusion guesses the wrong defer artifact. Pin the intended production environment with `dbt-cloud.defer-env-id`.

## Quick check

Run this from the project root to check whether the defer manifest belongs to the current project:

```shell
jq '.metadata | {project_name, dbt_version, adapter_type, generated_at}' target/dbt_cloud_defer/manifest.json
```

For this project, the expected `project_name` is `ksalomon_sandbox`. If the manifest shows an old project name such as `kyle_sa_hybrid`, move the stale defer directory out of the way and re-download from the pinned Cloud environment.

Run this from the project root for each manifest path to check for null grants:

```shell
jq '[.. | objects | select(has("config") and (.config|type=="object") and (.config|has("grants")) and (.config.grants == null))] | length' target/dbt_cloud_defer/manifest.json
jq '[.. | objects | select(has("config") and (.config|type=="object") and (.config|has("grants")) and (.config.grants == null))] | length' target/.lsp/dbt_cloud_defer/manifest.json
```

If either returns a number greater than `0`, normalize that manifest.

## Fix null grants

Back up the manifest first:

```shell
cp target/dbt_cloud_defer/manifest.json target/dbt_cloud_defer/manifest.json.bak-$(date +%Y%m%d%H%M%S)
cp target/.lsp/dbt_cloud_defer/manifest.json target/.lsp/dbt_cloud_defer/manifest.json.bak-$(date +%Y%m%d%H%M%S)
```

Normalize explicit null grants to empty maps:

```shell
perl -0pi -e 's/"grants"\s*:\s*null/"grants": {}/g' target/dbt_cloud_defer/manifest.json
perl -0pi -e 's/"grants"\s*:\s*null/"grants": {}/g' target/.lsp/dbt_cloud_defer/manifest.json
```

Validate state loading:

```shell
dbt ls --select state:modified --state target/dbt_cloud_defer
```

## Fix wrong or stale Cloud defer manifest

If `target/dbt_cloud_defer/manifest.json` belongs to the wrong project, first confirm the correct dbt Cloud production environment id. For this project:

- dbt Cloud project id: `469416`
- Production environment id: `404851`

Keep deferral deterministic by pinning the production environment in `dbt_project.yml`:

```yaml
dbt-cloud:
  project-id: 469416
  defer-env-id: 404851
```

Then move the stale artifact out of the way and let Fusion download a fresh one:

```shell
mv target/dbt_cloud_defer target/dbt_cloud_defer.stale-$(date +%Y%m%d%H%M%S)
dbt compile --skip-semantic-manifest-validation
```

Confirm the fresh download used the pinned environment:

```text
INFO Using defer_env_id '404851' for manifest download
```

Then re-run the quick checks above. The fresh manifest should report `project_name: ksalomon_sandbox` and `0` null grants.

## VS Code settings

Confirm these user settings if VS Code Problems are noisy:

```json
{
  "dbt.flag.defer": false,
  "dbt.linter.enable": false,
  "dbt.maxErrorReportingLsp": 0
}
```

Reload VS Code with `Developer: Reload Window` after changing settings.

## Chat prompt

Paste this into Wizard if the issue comes back:

```text
Use docs/runbooks/dbt1150_defer_manifest.md to troubleshoot the dbt1150 defer manifest issue. Check target/dbt_cloud_defer metadata, confirm the manifest project_name is ksalomon_sandbox, confirm dbt_project.yml pins dbt-cloud.defer-env-id to 404851, check both target/dbt_cloud_defer and target/.lsp/dbt_cloud_defer for null config.grants values, normalize null grants to {}, and keep the repo clean.
```

## Notes

- Keep repo changes clean; the fix should only touch generated `target/` artifacts and local VS Code user settings.
- A fresh Cloud defer download can recreate the bad manifest if the wrong Cloud environment is used.
- Pinning `dbt-cloud.defer-env-id` is the durable fix for wrong or stale Cloud artifact downloads.
- Normalizing `config.grants: null` to `{}` is a local repair for manifests created by older dbt versions or stale Cloud artifacts.
