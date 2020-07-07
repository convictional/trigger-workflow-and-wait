function usage_docs {
  echo ""
  echo "You can use this Github Action with:"
  echo "- uses: convictional/trigger-workflow-and-wait"
  echo "  with:"
  echo "    owner: keithconvictional"
  echo "    repo: myrepo"
  echo "    github_token: \${{ secrets.GITHUB_PERSONAL_ACCESS_TOKEN }}"
}

# TODO - Add client_payload

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

  ref="master"
  if [ $INPUT_REF ]
  then
    ref=$INPUT_REF
  fi 
}

function trigger_workflow {
  echo "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/dispatches"
  curl -X POST "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/dispatches" \
    -H "Accept: application/vnd.github.everest-preview+json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    --data "{\"event_type\": \"${event_type}\", \"client_payload\": {} }"
  sleep $wait_interval
}

function wait_for_workflow_to_finish {
  # Find the id of the last build
  last_run_id=$(curl -X GET "https://api.github.com/repos/$INPUT_OWNER/$INPUT_REPO/commits/$ref/check-runs" \
    -H 'Accept: application/vnd.github.antiope-preview+json' \
    -H "Authorization: Bearer $INPUT_GITHUB_TOKEN" | jq '[.check_runs[].id] | first')
  echo "The job id is [$last_run_id]."
  echo ""
  conclusion=$(curl -X GET "https://api.github.com/repos/$INPUT_OWNER/$INPUT_REPO/check-runs/$last_run_id" -H 'Accept: application/vnd.github.antiope-preview+json' -H "Authorization: Bearer $INPUT_GITHUB_TOKEN" | jq '.conclusion')

  while [[ $conclusion == "null" ]]
  do
    sleep $wait_interval
    conclusion=$(curl -X GET "https://api.github.com/repos/$INPUT_OWNER/$INPUT_REPO/check-runs/$last_run_id" -H 'Accept: application/vnd.github.antiope-preview+json' -H "Authorization: Bearer $INPUT_GITHUB_TOKEN" | jq '.conclusion')
    echo "Checking conclusion [$conclusion]"
  done

  if [[ $conclusion == "\"success\"" ]]
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
