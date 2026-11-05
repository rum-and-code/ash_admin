# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Verifiers.VerifyFieldResources do
  @moduledoc """
  Ensures that a field with the `resource` option references an action
  argument of the resource (or of its action, for a field in an `action`
  block), points to an Ash resource with a `label_field`, and does not also
  set a text `type`.
  """

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  def verify(dsl_state) do
    form_level =
      dsl_state
      |> AshAdmin.Resource.fields()
      |> Enum.map(&{&1, nil})

    action_level =
      dsl_state
      |> AshAdmin.Resource.form_actions()
      |> Enum.flat_map(fn form_action ->
        Enum.map(form_action.fields, &{&1, form_action.name})
      end)

    (form_level ++ action_level)
    |> Enum.reject(fn {field, _action} -> is_nil(field.resource) end)
    |> Enum.reduce_while(:ok, fn {field, action}, :ok ->
      case verify_field(dsl_state, field, action) do
        :ok -> {:cont, :ok}
        {:error, message} -> {:halt, {:error, error(dsl_state, field, action, message)}}
      end
    end)
  end

  defp verify_field(dsl_state, field, action) do
    cond do
      not argument_exists?(dsl_state, field.name, action) ->
        {:error, missing_argument_message(dsl_state, field, action)}

      field.type not in [nil, :default] ->
        {:error,
         "`#{field.name}` sets both `resource` and `type: #{inspect(field.type)}`. A field with `resource` renders as a relationship field, so remove `type`."}

      not Ash.Resource.Info.resource?(field.resource) ->
        {:error,
         "`#{field.name}` has `resource: #{inspect(field.resource)}`, but `#{inspect(field.resource)}` is not an Ash resource."}

      is_nil(AshAdmin.Resource.label_field(field.resource)) ->
        {:error,
         "`#{field.name}` has `resource: #{inspect(field.resource)}`, but `#{inspect(field.resource)}` has no `label_field` in its `admin` section."}

      true ->
        :ok
    end
  end

  defp missing_argument_message(dsl_state, field, nil) do
    "`#{field.name}` has `resource` set but `#{module_name(dsl_state)}` has no action with an argument named `#{field.name}`."
  end

  defp missing_argument_message(dsl_state, field, action) do
    "`#{field.name}` has `resource` set but the `#{action}` action of `#{module_name(dsl_state)}` has no argument named `#{field.name}`."
  end

  defp error(dsl_state, field, action, message) do
    path =
      if action,
        do: [:admin, :form, :action, action, :field, field.name],
        else: [:admin, :form, :field, field.name]

    Spark.Error.DslError.exception(
      message: message,
      path: path,
      module: Verifier.get_persisted(dsl_state, :module)
    )
  end

  defp module_name(dsl_state) do
    String.trim_leading(to_string(Verifier.get_persisted(dsl_state, :module)), "Elixir.")
  end

  defp argument_exists?(dsl_state, name, nil) do
    dsl_state
    |> Ash.Resource.Info.actions()
    |> Enum.flat_map(fn action -> action.arguments end)
    |> Enum.any?(&(&1.name == name))
  end

  defp argument_exists?(dsl_state, name, action_name) do
    case Ash.Resource.Info.action(dsl_state, action_name) do
      nil -> true
      action -> Enum.any?(action.arguments, &(&1.name == name))
    end
  end
end
