defmodule Helpdesk.Support.Ticket do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Support,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tickets"
    repo(Helpdesk.Repo)
  end

  actions do
    defaults [:read, create: [:subject, :parent_id]]

    update :recalculate_relationships do
      change atomic_update(:ancestor_ids, {:atomic, expr(expensive_ancestors.id)})
      # change atomic_update(:descendant_ids, {:atomic, expr(descendants.id)})
    end

    update :recalculate_relationships_alt do
      change atomic_update(:ancestor_ids, {:atomic, expr(list(expensive_ancestors, field: :id))})
    end

  end

  attributes do
    uuid_primary_key :id

    attribute :subject, :string do
      allow_nil? false
      public? true
    end

    attribute :ancestor_ids, {:array, :uuid} do
      allow_nil? false
      default []
    end

    timestamps()
  end

  relationships do
    belongs_to :parent, __MODULE__

    has_many :expensive_ancestors, __MODULE__,
      manual: Helpdesk.Support.AncestorsRelationship

    has_many :ancestors, __MODULE__ do
      no_attributes? true
      filter expr(id in parent(ancestor_ids))
    end
  end

  # changes do
  #   change after_action(fn changeset, ticket, context ->
  #     import Ash.Query

  #     # Here will be logic and all descendents and ancestors will have recalculated ancestor_ids field\
  #     ids = [ticket.id] |> IO.inspect()

  #     Helpdesk.Support.Ticket
  #     |> Ash.Query.filter(id in ^ids)
  #     |> Ash.bulk_update(:recalculate_relationships, %{}, Ash.Context.to_opts(context) ++ [return_errors?: true, strategy: [:atomic, :atomic_batches, :stream]])
  #     |> IO.inspect(label: :bulk_update)

  #     {:ok, ticket}
  #   end), where: changing(:parent_id)
  # end
end
