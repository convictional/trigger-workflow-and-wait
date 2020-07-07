# Trigger Workflow and Wait

Github Action for trigger a workflow from another workflow. The action then waits for a response.

**When would you use it?**

When deploying an app you may need to deploy additional services, this Github Action helps with that.


## Arguments

| Argument Name   | Required   | Default     | Description           |
| --------------- | ---------- | ----------- | --------------------- |
| `owner`         | True       | N/A         | The owner of the repository where the workflow is contained. |
| `repo`          | True       | N/A         | The repository where the workflow is contained. |
| `github_token`  | True       | N/A         | The Github access token with access to the repository. Its recommended you put it under secrets. |
| `wait_interval` | False      | 10          | The number of seconds delay between checking for result of run. |
| `event_type`    | False      | `ping`      | The event type that is trigger your workflow on the secondary repository. |
| `ref`         | False      | `master`    | The reference point. This is either a commit or branch. |


## Example

```
- uses: convictional/trigger-workflow-and-wait
  with:"
    owner: keithconvictional
    repo: myrepo
    github_token: ${{ secrets.GITHUB_PERSONAL_ACCESS_TOKEN }}
```
