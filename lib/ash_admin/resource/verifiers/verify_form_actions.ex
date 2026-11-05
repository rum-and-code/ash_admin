# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Verifiers.VerifyFormActions do
  @moduledoc """
  Ensures that each `action` block in the form section names an action of the
  resource, and that each of its fields is an argument or an accepted
  attribute of that action.
  """

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> AshAdmin.Resource.form_actions()
    |> Enum.reduce_while(:ok, fn form_action, :ok ->
      case verify_form_action(dsl_state, form_action) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp verify_form_action(dsl_state, form_action) do
    case Ash.Resource.Info.action(dsl_state, form_action.name) do
      nil ->
        {:error,
         error(
           dsl_state,
           [:admin, :form, :action, form_action.name],
           "The form has an `action :#{form_action.name}` block but `#{module_name(dsl_state)}` has no action named `#{form_action.name}`."
         )}

      action ->
        inputs = inputs(action)

        case Enum.find(form_action.fields, &(&1.name not in inputs)) do
          nil ->
            :ok

          field ->
            {:error,
             error(
               dsl_state,
               [:admin, :form, :action, form_action.name, :field, field.name],
               "`#{field.name}` is in the `action :#{form_action.name}` block but is not an argument or an accepted attribute of that action."
             )}
        end
    end
  end

  defp inputs(action) do
    Enum.map(action.arguments, & &1.name) ++ List.wrap(Map.get(action, :accept))
  end

  defp error(dsl_state, path, message) do
    Spark.Error.DslError.exception(
      message: message,
      path: path,
      module: Verifier.get_persisted(dsl_state, :module)
    )
  end

  defp module_name(dsl_state) do
    String.trim_leading(to_string(Verifier.get_persisted(dsl_state, :module)), "Elixir.")
  end
end
