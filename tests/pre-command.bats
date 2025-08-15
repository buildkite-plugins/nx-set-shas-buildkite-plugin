#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

bats_require_minimum_version 1.5.0

export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

DEFAULT_BRANCH="main"

setup() {
  export BUILDKITE_ORGANIZATION_SLUG="buildkite"
  export BUILDKITE_PIPELINE_SLUG="test-pipeline"
}

# Note: This snippet was copied from an issuein jasonkarns/bats-mock but Buildkite maintains its own fork.
# https://github.com/jasonkarns/bats-mock/issues/3#issuecomment-406301922
# https://github.com/buildkite-plugins/bats-mock?tab=readme-ov-file#credits
cleanup_stubs() {
  if stat ${BATS_TMPDIR}/*-stub-plan >/dev/null 2>&1; then
    for file in ${BATS_TMPDIR}/*-stub-plan; do
      program=$(basename $(echo "$file" | rev | cut -c 11- | rev))
      # Note: This will not error if unstubbing a command fails.
      unstub $program || true
    done
  fi
}

teardown() {
  cleanup_stubs
}

get_successful_base_commit_response() {
  local expected_nx_base=$1

  response=$(cat <<EOF
{
  "data": {
    "pipeline": {
      "builds": {
        "edges": [
          {
            "node": {
              "commit": "$expected_nx_base",
              "branch": "main",
              "state": "PASSED"
            }
          }
        ]
      }
    }
  }
}
EOF
)
  # minified_response=$(jq -n --arg r "$response" '$r')
  echo $response
}

get_no_successful_base_commit_response() {
  response=$(cat <<EOF
{
  "data": {
    "pipeline": {
      "builds": {
        "edges": []
      }
    }
  }
}
EOF
)

  echo $response
}

@test "Fails when API token is not detected" {
  run "$PWD/hooks/pre-command"

  assert_failure
  assert_output "GraphQL API token is required."
}

@test "Default branch build" {
  export GRAPHQL_API_TOKEN="fake-token"
  export BUILDKITE_PULL_REQUEST=false
  export BUILDKITE_BRANCH="$DEFAULT_BRANCH"

  expected_nx_base="ead215f889b0aa1aeb985373f5b512af7015445f"
  expected_nx_head="234kj5f889b0aa1aeb985373f5b512af70152345"

  stub curl "echo '$(get_successful_base_commit_response $expected_nx_base)'"
  stub git "rev-parse HEAD : echo $expected_nx_head"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "NX_BASE: $expected_nx_base"
  assert_output --partial "NX_HEAD: $expected_nx_head"
}

@test "PR branch build" {
  export GRAPHQL_API_TOKEN="fake-token"
  export BUILDKITE_PULL_REQUEST=2342
  export BUILDKITE_BRANCH="pr-branch"
  export BUILDKITE_PULL_REQUEST_BASE_BRANCH="$DEFAULT_BRANCH"

  expected_nx_base="ead215f889b0aa1aeb985373f5b512af7015445f"
  expected_nx_head="234kj5f889b0aa1aeb985373f5b512af70152345"

  stub curl "echo '$(get_successful_base_commit_response $expected_nx_base)'"
  stub git "rev-parse HEAD : echo $expected_nx_head"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "Current build is a PR build"
  assert_output --partial "NX_BASE: $expected_nx_base"
  assert_output --partial "NX_HEAD: $expected_nx_head"
}

@test "PR branch build without any successful base commit" {
  export GRAPHQL_API_TOKEN="fake-token"
  export BUILDKITE_PULL_REQUEST=2342
  export BUILDKITE_BRANCH="pr-branch"
  export BUILDKITE_PULL_REQUEST_BASE_BRANCH="$DEFAULT_BRANCH"

  expected_nx_base="ead215f889b0aa1aeb985373f5b512af7015445f"
  expected_nx_head="234kj5f889b0aa1aeb985373f5b512af70152345"

  stub curl "echo '$(get_no_successful_base_commit_response)'"

  # Stubs MUST be in the order they will be executed
  # by the program under test or they won't be matched properly.
  stub git \
    "merge-base ${BUILDKITE_PULL_REQUEST_BASE_BRANCH} HEAD : echo $expected_nx_base" \
    "rev-parse HEAD : echo $expected_nx_head"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "Current build is a PR build"
  assert_output --partial "NX_BASE: $expected_nx_base"
  assert_output --partial "NX_HEAD: $expected_nx_head"
}
