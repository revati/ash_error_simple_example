defmodule Helpdesk.Support.AncestorsRelationship do
  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship
  import Ecto.Query
  alias Helpdesk.Support.Ticket

  @doc false
  @impl true
  @spec load([Ticket.t()], keyword, map) ::
          {:ok, %{Ash.UUID.t() => [Ticket.t()]}} | {:error, any}
  def load(tickets, opts, context) do
    parent_ids = Enum.map(tickets, & &1.parent_id)

    ancestors =
    Ticket
      |> where([ticket], ticket.id in ^parent_ids)
      |> recursive_cte_query("ticket_tree", Ticket)
      |> Repo.all()

    tickets
    |> with_ancestors(ancestors)
    |> Map.new(&{&1.id, &1.ancestors})
    |> then(&{:ok, &1})
  end

  defp with_ancestors(tickets, ancestors) do
    Enum.map(tickets, fn ticket ->
      %{ticket | ancestors: get_ancestors(ticket, ancestors)}
    end)
  end

  defp get_ancestors(ticket, ancestors) do
    case Enum.find(ancestors, & &1.id === ticket.parent_id) do
      nil -> []
      found -> [found | get_ancestors(found, ancestors)]
    end
  end

  @doc false
  @impl true
  @spec ash_postgres_join(
          Ecto.Query.t(),
          opts :: keyword,
          current_binding :: any,
          as_binding :: any,
          :inner | :left,
          Ecto.Query.t()
        ) ::
          {:ok, Ecto.Query.t()} | {:error, any}
  # Add a join from some binding in the query, producing *as_binding*.
  def ash_postgres_join(query, _opts, current_binding, as_binding, join_type, destination_query) do
    immediate_parents =
      from(destination in destination_query,
        where: parent_as(^current_binding).id == destination.parent_id
      )

    cte_name = "tickets_#{as_binding}"

    descendant_query =
      recursive_cte_query_for_join(
        immediate_parents,
        cte_name,
        destination_query
      )

    case join_type do
      :inner ->
        {:ok,
         from(row in query,
           inner_lateral_join: descendant in subquery(descendant_query),
           on: true,
           as: ^as_binding
         )}

      :left ->
        {:ok,
         from(row in query,
           left_lateral_join: descendant in subquery(descendant_query),
           on: true,
           as: ^as_binding
         )}
    end
  end

  @impl true
  @spec ash_postgres_subquery(keyword, any, any, Ecto.Query.t()) ::
          {:ok, Ecto.Query.t()} | {:error, any}
  # Produce a subquery using which will use the given binding and will be
  def ash_postgres_subquery(_opts, current_binding, as_binding, destination_query) do
    immediate_ancestors =
      from(destination in Ticket,
        where: parent_as(^current_binding).parent_id == destination.id
      )

    cte_name = "tickets_#{as_binding}"

    recursive_cte_query =
      recursive_cte_query_for_join(
        immediate_ancestors,
        cte_name,
        Ticket
      )

    other_query =
      from(row in subquery(recursive_cte_query),
        where:
          row.id in subquery(
            from(row in Ecto.Query.exclude(destination_query, :select), select: row.id)
          )
      )

    {:ok, other_query}
  end

  defp recursive_cte_query(immediate_parents, cte_name, query) do
    recursion_query =
      query
      |> join(:inner, [parent], child in ^cte_name, on: parent.id == child.parent_id)

    ancestors_query =
      immediate_parents
      |> union(^recursion_query)

    {cte_name, Ticket}
    |> recursive_ctes(true)
    |> with_cte(^cte_name, as: ^ancestors_query)
  end

  defp recursive_cte_query_for_join(immediate_parents, cte_name, query) do
    # This is due to limitations in ecto's recursive CTE implementation
    # For more, see here:
    # https://elixirforum.com/t/ecto-cte-queries-without-a-prefix/33148/2
    # https://stackoverflow.com/questions/39458572/ecto-declare-schema-for-a-query
    ticket_keys = Ticket.__schema__(:fields)

    cte_name =
      from(cte in fragment("?", literal(^cte_name)), select: map(cte, ^ticket_keys))

    recursion_query =
      query
      |> join(:inner, [parent], child in ^cte_name, on: parent.id == child.parent_id)

    ancestors_query =
      immediate_parents
      |> union(^recursion_query)

    cte_name
    |> recursive_ctes(true)
    |> with_cte(^cte_name, as: ^ancestors_query)
  end
end
