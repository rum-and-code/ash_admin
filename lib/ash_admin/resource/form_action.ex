# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.FormAction do
  @moduledoc """
  The field configuration of a single action in the admin form.
  """
  defstruct [:name, :__identifier__, fields: [], __spark_metadata__: nil]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "The name of the action."
    ]
  ]

  def schema, do: @schema
end
