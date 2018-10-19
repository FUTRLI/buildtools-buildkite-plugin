### Buildkite Buildtools Plugin

A plugin for running common commands across Buildkite pipelines.

Heavily integrated with AWS. Use in tandem with the Buildkite ECR plugin.


**Build example**

```yaml
plugins:
  ecr#v1.1.4:
    login: true
    account_ids: 111111111111
  futrli/buildkite-buildtools#v0.0.1:
    task: build
    aws-account-id: 111111111111
    context-path: "./src/to/context"
    ecr-repository: "myrepo"
    image-name: "image"
    tag: "latest"
    build-args:
      - foo=bar
```

## Configuration

### `task`


Choose from the following supported tasks:

- `build`

### `aws-account-id` (used by build)

AWS account id to use. Will check ECR repositories under this account.

### `image-repository` (used by build)

The address of the image repository to use when building an image.

### `build-args` (used by build)

Array of arguments passed into the docker build.

