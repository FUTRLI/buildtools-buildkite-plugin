### Buildkite Buildtools Plugin

A plugin for running common commands across Buildkite pipelines.

Heavily integrated with AWS. Use in tandem with the Buildkite ECR plugin.


## Example

```yml
steps:
  - command: "export VAR=123"
  - plugins:
      - futrli/buildtools#v0.2.0:
          task: build
          aws-account-id: "111111111111"
          build-args:
            - foo=bar
          context-path: "./src/to/context"
          image-name: "repo/image"
          tag: "latest"
```

If `command` is defined it will be executed before the chosen task is run.

## Configuration

### `task`

Choose from the following supported tasks:

- `build`

### `aws-account-id` (used by build)

AWS account id to use. Will check ECR repositories under this account.

### `build-args` (used by build)

Array of arguments passed into the docker build.

### `image-name` (used by build)

The short form of the repository to use for the image, for example `futrli/reports-service-api`.

### `context-path` (used by build)

The path to use as the build context when docker build is invoked.

### `tag` (used by build)

The tag that the image should use.
