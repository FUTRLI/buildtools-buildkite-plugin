#!/bin/bash

set -ueo pipefail

# Build task that will build an image for the chosen repository with the chosen tag
# Run through all images in the build property, either a single item or a list

ecr_repository="$(plugin_read_list ECR_REPOSITORY)"
image_name="$(plugin_read_list IMAGE_NAME)"
tag_script="$(plugin_read_list TAG_SCRIPT)"
tag_value="$(plugin_read_list TAG_VALUE)"
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
if [[ -z "${ecr_repository}" ]] ; then 
    missing_attributes+=("ecr-repository")
    raise=1
fi
if [[ -z "${image_name}" ]] ; then 
    missing_attributes+=("image-name")
    raise=1
fi
if [[ -z "${tag_script}" ]] && [[ -z "${tag_value}" ]] ; then
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

# If we need to run a script to derive the tag then run it
[[ -n "${tag_script}" ]] && tag_value=$( eval "${tag_script}" )

full_image_tag="${ecr_repository}/${image_name}:${tag_value}"
build_params=(--tag "${full_image_tag}")
# Create --build-arg xxx command list
while read -r arg ; do
    [[ -n "${arg:-}" ]] && build_params+=("--build-arg" "${arg}")
done <<< "$(plugin_read_list BUILD_ARGS)"

image_matching_tag_count=$(aws_check_image "${ecr_repository}" "${aws_account_id}" "${tag_value}")

if [[ ${image_matching_tag_count} -gt 0 ]] ; then
    echo "+++ Tag ${tag_value} already exists on ECR. Will not continue to build."
    exit 0
fi

echo "+++ :docker: Building ${image_name}:${tag_value}"
run_docker build "${context_path}" "${build_params[@]}"

echo "+++ :docker: Pushing ${image_name}:${tag_value} to ECR"
run_docker push "${full_image_tag}"
