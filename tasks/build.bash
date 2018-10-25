#!/bin/bash

set -ueo pipefail

# Build task that will build an image for the chosen repository with the chosen tag
# Run through all images in the build property, either a single item or a list

image_name="$(plugin_read_list IMAGE_NAME)"
tag="$(plugin_read_list TAG)"
context_path="$(plugin_read_list CONTEXT_PATH)"
aws_account_id="$(plugin_read_list AWS_ACCOUNT_ID)"

# https://stackoverflow.com/questions/1527049/join-elements-of-an-array#17841619
function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

# FIXME: there must be a more elegant way of doing this!
raise=0
missing_attributes=()
if [[ -z "${aws_account_id}" ]] ; then 
    missing_attributes+=("aws-account-id")
    raise=1
fi
if [[ -z "${context_path}" ]] ; then 
    missing_attributes+=("context-path")
    raise=1
fi
if [[ -z "${image_name}" ]] ; then 
    missing_attributes+=("image-name")
    raise=1
fi
if [[ -z "${tag}" ]] ; then
    missing_attributes+=("tag")
    raise=1
fi
# If any of the above are missing then raise should be set and we should bail
if [[ "${raise}" -eq 1 ]] ; then
    # shellcheck disable=SC2086
    missing_attrs=$(join_by ', ' ${missing_attributes[*]})
    echo "Missing required attributes: ${missing_attrs}"
    exit 1
fi

full_image_tag="${image_name}:${tag}"
build_params=(--tag "${full_image_tag}")
# Create --build-arg xxx command list
while read -r arg ; do
    [[ -n "${arg:-}" ]] && build_params+=("--build-arg" "${arg}")
done <<< "$(plugin_read_list BUILD_ARGS)"

image_matching_tag_count=$(aws_check_image "${image_name}" "${aws_account_id}" "${tag}")

if [[ ${image_matching_tag_count} -gt 0 ]] ; then
    echo "+++ Tag ${tag} already exists on ECR. Will not continue to build."
    exit 0
fi

echo "+++ :docker: Building ${image_name}:${tag}"
run_docker build "${context_path}" "${build_params[@]}"

echo "+++ :docker: Pushing ${image_name}:${tag} to ECR"
run_docker push "${full_image_tag}"
