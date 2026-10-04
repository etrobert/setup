---
name: taskgraph
description:
  Pick up and work on tasks assigned to Claude in a TaskGraph organization, and
  update their status as you go. Use whenever Étienne asks you to work on, take,
  or check TaskGraph tasks, or gives a graph.etiennerobert.com link.
---

# TaskGraph

TaskGraph (`etrobert/taskgraph`) runs on tower at
`https://graph.etiennerobert.com`. An organization's link,
`https://graph.etiennerobert.com/?org=<id>`, is its only access key: get it from
Étienne's message, ask for it if missing, and never write it into a repository.

## API

Plain JSON over tRPC at `https://graph.etiennerobert.com/trpc`. Queries are GET
with the input URL-encoded in `?input=`; mutations are POST with a JSON body and
need `content-type: application/json`, even with no input. Responses are
`{"result":{"data":…}}`, failures `{"error":…}`.

```sh
api=https://graph.etiennerobert.com/trpc
curl --silent --get --data-urlencode 'input={"organizationId":"<id>"}' "$api/graph"
curl --silent --request POST --header 'content-type: application/json' \
  --data '{"nodeId":"<task id>","updates":{"status":"in progress"}}' \
  "$api/updateTaskDetails"
```

`graph` returns `tasks` (with `status`, `description`, `url` and `assignee`),
`projects` and `dependencies`. A dependency `{source, target}` means `source`
must be completed before `target`. Statuses are `pending`, `in progress`,
`in review` and `completed`.

## Working on tasks

1. Read the graph. Your tasks are those whose `assignee.isAi` is true.
2. A task is ready when it is `pending` and every dependency targeting it has a
   `completed` source. Work on ready tasks only; list the blocked ones and what
   blocks them.
3. If a task's name and description don't say what done looks like, ask before
   starting.
4. Set it to `in progress`, do the work, then set it to `completed`, or to
   `in review` when a person has to approve the result (an open pull request).
   Set the result's link (http or https only), such as the pull request, as the
   task's `url` in the same `updateTaskDetails` call.
