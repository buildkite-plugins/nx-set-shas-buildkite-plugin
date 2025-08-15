# Nx Set SHAs Buildkite Plugin [![Build status](https://badge.buildkite.com/b94916f8659ae6941a5cb34bcaff600deb9ff30e09101fcbce.svg)](https://buildkite.com/buildkite/plugins-nx-set-shas)

A [Buildkite](https://buildkite.com/) plugin that fetches and sets base and head SHAs for more efficient [Nx](https://nx.dev) monorepo builds.

This plugin queries Buildkite for the last successful commit in either the current branch or (for PR builds) the base branch of the repository and sets the environment variables `NX_BASE` and `NX_HEAD` accordingly.

These two variables are used by the `nx affected` command to allow Nx to run only the targets affected by the current `HEAD` commit. This is useful if your Nx monorepo contains several projects and you want to avoid running all targets for every project on every commit.

For more information, see the [`nx affected` documentation](https://nx.dev/ci/features/affected).

## Examples

**Note**: The plugin requires a [Buildkite API access token](https://buildkite.com/user/api-access-tokens) with GraphQL scope. The example assumes assume you've set this token as an environment variable named `BUILDKITE_API_TOKEN` using a [Buildkite secret](https://buildkite.com/docs/pipelines/security/secrets/buildkite-secrets), but [additional secret managers](https://buildkite.com/docs/pipelines/security/secrets/managing) are supported as well.

```yaml
steps:
  - label: ":nx: Run the Nx build"
    commands:
      - npx nx affected -t lint build test
    plugins:
      - nx-set-shas#v0.1.0

      - secrets:
          variables:
            BUILDKITE_API_TOKEN: BUILDKITE_API_TOKEN
```

## License

MIT (see [LICENSE](LICENSE))
