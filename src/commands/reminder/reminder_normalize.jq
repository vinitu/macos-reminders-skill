# Maps remindctl JSON to AGENTS.md reminder shape. Priority: 0/1/5/9 -> "none"/"low"/"medium"/"high".
[.[] | {
  id,
  name: .title,
  list: .listName,
  body: (if .notes == "" or .notes == null then null else .notes end),
  completed: .isCompleted,
  priority: (if .priority == null then "none" elif .priority == 0 then "none" elif .priority == 1 then "low" elif .priority == 5 then "medium" elif .priority == 9 then "high" else "none" end),
  due_date: .dueDate
}]
