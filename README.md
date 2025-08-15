# Nx Set SHAs Buildkite Plugin [![Build status](https://badge.buildkite.com/b94916f8659ae6941a5cb34bcaff600deb9ff30e09101fcbce.svg)](https://buildkite.com/buildkite/plugins-nx-set-shas)

A [Buildkite](https://buildkite.com/) plugin that fetches and sets base and head SHAs for more efficient [Nx](https://nx.dev) monorepo builds.

This plugin queries the Buildkite API for the last successful commit on either the current branch or, for PR builds, the base branch of the repository and sets the environment variables `NX_BASE` and `NX_HEAD` accordingly.

These two variables are used by the [`nx affected` command](https://nx.dev/ci/features/affected) to allow Nx to run only the targets affected by the current (i.e., `HEAD`) commit.

## Examples

The plugin requires a [Buildkite API access token](https://buildkite.com/user/api-access-tokens) with GraphQL scope. You can set the token with the `GRAPHQL_API_TOKEN` environment variable or with the plugin's `api-token` parameter.

In this example, the token is obtained using the [Secrets plugin](https://github.com/buildkite-plugins/secrets-buildkite-plugin), which reads it from [Buildkite secrets](https://buildkite.com/docs/pipelines/security/secrets/buildkite-secrets):

```yaml
steps:
  - label: ":nx: Run the Nx build"
    command: npx nx affected -t lint build test
    plugins:
      - nx-set-shas#v0.1.0
      - secrets:
          variables:
            GRAPHQL_API_TOKEN: GRAPHQL_API_TOKEN
```

Here, the token is read from the plugin's `api-token` parameter, having been set with an environment variable — for example, using a [post-checkout lifecycle hook](https://buildkite.com/docs/agent/v3/hooks#job-lifecycle-hooks):

```yaml
steps:
  - label: ":nx: Run the Nx build"
    command: npx nx affected -t lint build test
    plugins:
      - nx-set-shas#v0.1.0:
          api-token: $MY_GRAPHQL_API_TOKEN
```

To learn more about working with secrets in Buildkite pipelines, see [Managing pipeline secrets](https://buildkite.com/docs/pipelines/security/secrets/managing).

## License

MIT (see [LICENSE](LICENSE))
