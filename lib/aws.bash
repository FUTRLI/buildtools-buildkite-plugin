#!/bin/bash

function aws_check_image {
    # Query ECR for images under $ecr_repository that have $tag and echo the count.
    local ecr_repository=$1
    local aws_account_id=$2
    local tag=$3
    local matching_images
    matching_images=$(\
        aws ecr describe-images \
            --region eu-west-1 \
            --repository-name "${ecr_repository}" \
            --registry-id "${aws_account_id}" \
            --output text --query "sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]"\
        | \
        tr '\t' '\n' | grep -c "${tag}" \
    )
    echo "${matching_images}"
}
