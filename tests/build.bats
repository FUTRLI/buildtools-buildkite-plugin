#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/aws'
load '../lib/docker'
load '../lib/shared'

#export BUILDKITE_PLUGIN_BUILDTOOLS_VERBOSE=on

@test "Build image using build args" {
    export BUILDKITE_JOB_ID=1
    export BUILDKITE_PIPELINE_SLUG="branch"
    export BUILDKITE_BUILD_NUMBER=1
    export BUILDKITE_PLUGIN_BUILDTOOLS_AWS_ACCOUNT_ID="123456"
    export BUILDKITE_PLUGIN_BUILDTOOLS_BUILD_ARGS_0="key=1"
    export BUILDKITE_PLUGIN_BUILDTOOLS_BUILD_ARGS_1="commit=abc"
    export BUILDKITE_PLUGIN_BUILDTOOLS_CONTEXT_PATH="./path/to/build/"
    export BUILDKITE_PLUGIN_BUILDTOOLS_IMAGE_NAME="myrepo/image"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TAG="1.2.2"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TASK="build"

    stub aws \
        "ecr describe-images --region eu-west-1 --repository-name myrepo/image --registry-id 123456 --output text \
            --query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' : echo ok"
    stub grep "-c 1.2.2 : echo 0"
    stub docker \
        "build ./path/to/build/ --tag 123456.dkr.ecr.eu-west-1.amazonaws.com/myrepo/image:1.2.2 \
            --build-arg key=1 --build-arg commit=abc : echo docker build ok" \
        "push 123456.dkr.ecr.eu-west-1.amazonaws.com/myrepo/image:1.2.2 : echo docker push ok"

    run "$PWD/hooks/command"

    assert_success
    assert_output --partial "docker build ok"

    unstub aws
    unstub grep
    unstub docker
}

@test "Missing task field should raise" {
    export BUILDKITE_JOB_ID=1
    export BUILDKITE_PIPELINE_SLUG="branch"
    export BUILDKITE_BUILD_NUMBER=1

    run "$PWD/hooks/command"

    assert_failure
    assert_output --partial "Missing task"
}

@test "Build image without build args" {
    export BUILDKITE_JOB_ID=1
    export BUILDKITE_PIPELINE_SLUG="branch"
    export BUILDKITE_BUILD_NUMBER=1
    export BUILDKITE_PLUGIN_BUILDTOOLS_AWS_ACCOUNT_ID="123456"
    export BUILDKITE_PLUGIN_BUILDTOOLS_CONTEXT_PATH="./path/to/build/"
    export BUILDKITE_PLUGIN_BUILDTOOLS_IMAGE_NAME="myrepo/image"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TAG="1.2.2"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TASK="build"

    stub aws \
        "ecr describe-images --region eu-west-1 --repository-name myrepo/image --registry-id 123456 --output text \
            --query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' : echo ok"
    stub grep "-c 1.2.2 : echo 0"
    stub docker \
        "build ./path/to/build/ \
            --tag 123456.dkr.ecr.eu-west-1.amazonaws.com/myrepo/image:1.2.2 : echo docker build ok" \
        "push 123456.dkr.ecr.eu-west-1.amazonaws.com/myrepo/image:1.2.2 : echo docker push ok"

    run "$PWD/hooks/command"

    assert_success
    assert_output --partial "docker build ok"
    unstub aws
    unstub grep
    unstub docker
}

@test "Build image without tag raises error" {
    export BUILDKITE_JOB_ID=1
    export BUILDKITE_PIPELINE_SLUG="branch"
    export BUILDKITE_BUILD_NUMBER=1
    export BUILDKITE_PLUGIN_BUILDTOOLS_AWS_ACCOUNT_ID="123456"
    export BUILDKITE_PLUGIN_BUILDTOOLS_CONTEXT_PATH="./path/to/build/"
    export BUILDKITE_PLUGIN_BUILDTOOLS_IMAGE_NAME="myrepo/image"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TASK="build"
    export BUILDKITE_PLUGIN_BUILDTOOLS_VERBOSE=on

    run "$PWD/hooks/command"

    assert_failure 1
    assert_output --partial "Missing required attributes: tag"
}

@test "Build image without required attributes raises error" {
    export BUILDKITE_JOB_ID=1
    export BUILDKITE_PIPELINE_SLUG="branch"
    export BUILDKITE_BUILD_NUMBER=1
    export BUILDKITE_PLUGIN_BUILDTOOLS_TASK="build"

    run "$PWD/hooks/command"

    assert_failure 1
    assert_output --partial "Missing required attributes: aws-account-id, context-path, image-name, tag"
}


@test "Test bad command raises" {
    export BUILDKITE_JOB_ID=1
    export BUILDKITE_PIPELINE_SLUG="branch"
    export BUILDKITE_BUILD_NUMBER=1
    export BUILDKITE_COMMAND="ls -l"
    export BUILDKITE_PLUGIN_BUILDTOOLS_AWS_ACCOUNT_ID="123456"
    export BUILDKITE_PLUGIN_BUILDTOOLS_BUILD_ARGS_0="key=1"
    export BUILDKITE_PLUGIN_BUILDTOOLS_BUILD_ARGS_1="commit=abc"
    export BUILDKITE_PLUGIN_BUILDTOOLS_CONTEXT_PATH="./path/to/build/"
    export BUILDKITE_PLUGIN_BUILDTOOLS_IMAGE_NAME="myrepo/image"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TAG="1.2.2"
    export BUILDKITE_PLUGIN_BUILDTOOLS_TASK="build"

    stub ls "-l : exit 1"

    run "$PWD/hooks/command"

    assert_failure
    assert_output --partial "Command failed"

    unstub ls
}
