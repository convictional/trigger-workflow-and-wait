function usage_docs {
  echo ""
  echo "You can use this Github Action with:"
  echo "- uses: convictional/trigger-workflow-and-wait"
  echo "  with:"
  echo "    owner: keithconvictional"
  echo "    repo: myrepo"
  echo "    github_token: \${{ secrets.GITHUB_PERSONAL_ACCESS_TOKEN }}"
  echo "    workflow_file_name: main.yaml"
}

function validate_args {
  wait_interval=10 # Waits for 10 seconds
  if [ "$INPUT_WAITING_INTERVAL" ]
  then
    wait_interval=$INPUT_WAITING_INTERVAL
  fi

  propagate_failure=true
  if [ -n "$INPUT_PROPAGATE_FAILURE" ]
  then
    propagate_failure=$INPUT_PROPAGATE_FAILURE
  fi

  trigger_workflow=true
  if [ -n "$INPUT_TRIGGER_WORKFLOW" ]
  then
    trigger_workflow=$INPUT_TRIGGER_WORKFLOW
  fi

  wait_workflow=true
  if [ -n "$INPUT_WAIT_WORKFLOW" ]
  then
    wait_workflow=$INPUT_WAIT_WORKFLOW
  fi

  if [ -z "$INPUT_OWNER" ]
  then
    echo "Error: Owner is a required argument."
    usage_docs
    exit 1
  fi

  if [ -z "$INPUT_REPO" ]
  then
    echo "Error: Repo is a required argument."
    usage_docs
    exit 1
  fi

  if [ -z "$INPUT_GITHUB_TOKEN" ]
  then
    echo "Error: Github token is required. You can head over settings and"
    echo "under developer, you can create a personal access tokens. The"
    echo "token requires repo access."
    usage_docs
    exit 1
  fi

  if [ -z $INPUT_WORKFLOW_FILE_NAME ]
  then
    echo "Error: Workflow File Name is required"
    usage_docs
    exit 1
  fi

  inputs=$(echo '{}' | jq)
  if [ "$INPUT_INPUTS" ]
  then
    inputs=$(echo $INPUT_INPUTS | jq)
  fi

  ref="main"
  if [ "$INPUT_REF" ]
  then
    ref=$INPUT_REF
  fi
}

function trigger_workflow {
  echo "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/$INPUT_WORKFLOW_FILE_NAME/dispatches"

  curl -X POST "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/$INPUT_WORKFLOW_FILE_NAME/dispatches" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    --data "{\"ref\":\"${ref}\",\"inputs\":${inputs}}"
  echo "Sleeping for $wait_interval seconds"
  sleep $wait_interval
}

function wait_for_workflow_to_finish {
  # Find the id of the last build
  last_workflow=$(curl -X GET "https://api.github.com/repos/$INPUT_OWNER/$INPUT_REPO/actions/workflows/$INPUT_WORKFLOW_FILE_NAME/runs" \
    -H 'Accept: application/vnd.github.antiope-preview+json' \
    -H "Authorization: Bearer $INPUT_GITHUB_TOKEN" | jq '[.workflow_runs[]] | first')
  last_workflow_id=$(echo $last_workflow | jq '.id')
  echo "The workflow id is [$last_workflow_id]."
  echo ""
  conclusion=$(echo $last_workflow | jq '.conclusion')
  status=$(echo $last_workflow | jq '.status')

  while [[ $conclusion == "null" && $status != "\"completed\"" ]]
  do
    echo "Sleeping for $wait_interval seconds"
    sleep $wait_interval
    workflow=$(curl -X GET "https://api.github.com/repos/$INPUT_OWNER/$INPUT_REPO/actions/workflows/$INPUT_WORKFLOW_FILE_NAME/runs" \
      -H 'Accept: application/vnd.github.antiope-preview+json' \
      -H "Authorization: Bearer $INPUT_GITHUB_TOKEN" | jq '.workflow_runs[] | select(.id == '$last_workflow_id')')
    conclusion=$(echo $workflow | jq '.conclusion')
    status=$(echo $workflow | jq '.status')
    echo "Checking conclusion [$conclusion]"
    echo "Checking status [$status]"
  done

  if [[ $conclusion == "\"success\"" && $status == "\"completed\"" ]]
  then
    echo "Yes, success"
  else
    # Alternative "failure"
    echo "Conclusion is not success, its [$conclusion]."
    if [ "$propagate_failure" = true ]
    then
      echo "Propagating failure to upstream job"
      exit 1
    fi
  fi
}

function main {
  validate_args

  if [ "$trigger_workflow" = true ]
  then
    trigger_workflow
  else
    echo "Skipping triggering the workflow."
  fi

  if [ "$wait_workflow" = true ]
  then
    wait_for_workflow_to_finish
  else
    echo "Skipping waiting for workflow."
  fi
}

main
