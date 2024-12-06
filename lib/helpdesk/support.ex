defmodule Helpdesk.Support do
  use Ash.Domain

  resources do
    resource Helpdesk.Support.Ticket do
      define :create_ticket, action: :create
    end
  end
end
