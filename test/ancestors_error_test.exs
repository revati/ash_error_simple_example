defmodule HelpdeskTest do
  use ExUnit.Case
  doctest Helpdesk

  test "recalculate relationships" do
    import Ash.Query

    assert {:ok, ticket_1} = Helpdesk.Support.create_ticket(%{subject: "1"})
    assert {:ok, ticket_2} = Helpdesk.Support.create_ticket(%{subject: "1", parent_id: ticket_1.id})

    ids = [ticket_1.id, ticket_2.id]

    Helpdesk.Support.Ticket
    |> Ash.Query.filter(id in ^ids)
    |> Ash.bulk_update!(:recalculate_relationships, %{}, [return_errors?: true])
  end

  test "recalculate relationships alt" do
    import Ash.Query

    assert {:ok, ticket_1} = Helpdesk.Support.create_ticket(%{subject: "1"})
    assert {:ok, ticket_2} = Helpdesk.Support.create_ticket(%{subject: "1", parent_id: ticket_1.id})

    ids = [ticket_1.id, ticket_2.id]

    Helpdesk.Support.Ticket
    |> Ash.Query.filter(id in ^ids)
    |> Ash.bulk_update!(:recalculate_relationships_alt, %{}, [return_errors?: true])
  end
end
