#!/bin/bash

function aws_check_image {
    local ecr_repository=$1
    local aws_account_id=$2
    local tag=$3
    local count
    count=$(\
        aws ecr batch-get-image \
            --region eu-west-1 \
            --repository-name="${ecr_repository}" \
            --registry-id="${aws_account_id}" \
            --image-ids imageTag="${tag}" \
        | \
        jq '.images | length' \
    )
    echo "${count}"
}

