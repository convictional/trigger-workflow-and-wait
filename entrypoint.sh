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
  wait_interval=10
  if [ "$INPUT_WAITING_INTERVAL" ]
  then
    wait_interval=$INPUT_WAITING_INTERVAL
  fi

  if [ -z "$INPUT_OWNER" ]
  then
    echo "Error: Owner is a required arugment."
    usage_docs
    exit 1
  fi

  if [ -z "$INPUT_REPO" ]
  then
    echo "Error: Repo is a required arugment."
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

  event_type="ping"
  if [ "$INPUT_EVENT_TYPE" ]
  then
    event_type=$INPUT_EVENT_TYPE
  fi

  if [ -z $INPUT_WORKFLOW_FILE_NAME ]
  then
    echo "Error: Workflow File Name is required"
    usage_docs
    exit 1
  fi

  client_payload=$(echo '{}' | jq)
  if [ "$INPUT_CLIENT_PAYLOAD" ]
  then
    client_payload=$(echo $INPUT_CLIENT_PAYLOAD | jq)
  fi
}

function trigger_workflow {
  echo "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/dispatches"
  curl -X POST "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/dispatches" \
    -H "Accept: application/vnd.github.everest-preview+json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    --data "{\"event_type\": \"${event_type}\", \"client_payload\": $client_payload }"
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
    exit 1
  fi
}

function main {
  validate_args
  trigger_workflow
  wait_for_workflow_to_finish
}

main
