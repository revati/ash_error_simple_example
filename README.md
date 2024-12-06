`Helpdesk.Support.Ticket` has 2 update actions both extracted from discussions in discord.

```elixir
update :recalculate_relationships do
  change atomic_update(:ancestor_ids, {:atomic, expr(expensive_ancestors.id)})
end

update :recalculate_relationships_alt do
  change atomic_update(:ancestor_ids, {:atomic, expr(list(expensive_ancestors, field: :id))})
end
```

Both those actions are based on `expensive_ancestors` relationship which does recursive postgres query.

There are 2 test cases in `test/ancestors_error_test.exs` trigering both of them and getting different errors.
