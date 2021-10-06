#!/bin/bash
aws s3api put-object --bucket 3s_bucket --key path/to/terraform.tfstate --acl bucket-owner-full-control