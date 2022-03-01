#!/bin/bash
refactor-tf() {
  echo "Changing $1 to $2"
  while IFS= read -r line
  do
    sed -i '' -e "s/$1/$2/g" "$line"
    echo "Updating $line"
  done < <(grep -d skip "$1" ./* | awk '{print $1}' | cut -d":" -f1 | uniq)
}
# Example rewrite: this will replace _all_ entries of this value inside the current directory only.
# refactor-tf "data.terraform_remote_state.vpc.outputs.aws_vpc_ps_main_id" "local.runlevels.vpc_id"

# Additionally, you may now have some ternaries that are the same setting for both true and false
# You will need to manually review and improve this."