# .github/workflows/ — GitHub Actions (MANAGED)

**These files are auto-synced by `thepopebot init` and `thepopebot upgrade`. Do not edit them — changes will be overwritten.**

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `run-job.yml` | `job/*` branch created | Runs the Docker agent container for a job |
| `rebuild-event-handler.yml` | Push to `main` | Rebuilds the event handler server |
| `upgrade-event-handler.yml` | Manual dispatch | Creates a PR to upgrade thepopebot |
| `auto-merge.yml` | Job PR opened | Squash-merges PRs within allowed paths |
| `notify-pr-complete.yml` | After auto-merge | Sends job completion notification |
| `notify-job-failed.yml` | `run-job.yml` fails | Sends failure notification |

## Customization

If you need custom workflows, create new `.yml` files outside this directory or in a separate workflow path. Do not modify these managed files — they will be reset on upgrade.
