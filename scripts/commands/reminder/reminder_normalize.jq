# Maps remindctl JSON to AGENTS.md reminder shape. Priority may be 0/1/5/9 or none/low/medium/high.
[.[] | . as $item | {
  id,
  name: .title,
  list: .listName,
  body: (if .notes == "" or .notes == null then null else .notes end),
  completed: .isCompleted,
  priority: (
    if $item.priority == null then "none"
    elif $item.priority == 0 or $item.priority == "none" then "none"
    elif $item.priority == 1 or $item.priority == "low" then "low"
    elif $item.priority == 5 or $item.priority == "medium" then "medium"
    elif $item.priority == 9 or $item.priority == "high" then "high"
    else "none"
    end
  ),
  due_date: .dueDate
}]
