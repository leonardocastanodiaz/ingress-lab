# Lifecycle runbooks

Each lab must provide repeatable lifecycle operations:

- `up`: create runtime cluster and bootstrap root app
- `pause`: stop runtime processes without deleting data
- `resume`: start runtime processes and validate health
- `destroy`: remove runtime cluster
- `smoke`: run basic verification checks

Use `scripts/labctl.sh` as the command entrypoint.
