# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.PageHeader do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :resource, :any, default: nil
  attr :domain, :any, default: nil
  attr :action, :any, default: nil
  attr :action_type, :atom, default: nil
  attr :record, :any, default: nil
  attr :table, :any, default: nil
  attr :prefix, :any, required: true

  @doc """
  Page header shown above the content: breadcrumb and title on the left, a
  single "Actions" dropdown on the right, split into sections: create, read,
  update, destroy and generic actions. The update and destroy sections need a
  record, so they only show on the show, update and destroy pages. The action
  in use is highlighted.

  The show page also has "Set as actor", the update and destroy pages "Show".
  """
  def page_header(assigns) do
    record =
      case assigns.record do
        {:ok, %_{} = record} -> record
        _ -> nil
      end

    assigns =
      assigns
      |> assign(:loaded_record, record)
      |> assign(:page, page(assigns.resource, assigns.action, record))

    assigns =
      assigns
      |> assign(:breadcrumb, breadcrumb_items(assigns))
      |> assign(:title, title(assigns))

    ~H"""
    <div class="mx-4 md:mx-8 pt-6 md:pt-8">
      <.breadcrumb :if={@breadcrumb != []} items={@breadcrumb} />
      <div class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-2">
        <button
          type="button"
          phx-click="toggle_sidebar"
          class="md:hidden -ml-1.5 rounded-lg p-1.5 text-neutral-500 hover:bg-neutral-100 hover:text-neutral-700 dark:text-neutral-400 dark:hover:bg-white/5 dark:hover:text-neutral-200"
          aria-label="Open navigation"
        >
          <AshAdmin.CoreComponents.icon name="hero-bars-3" class="h-5 w-5" />
        </button>
        <h1 class="text-2xl md:text-3xl font-bold tracking-tight text-neutral-950 dark:text-white truncate">
          {@title}
        </h1>
        <div class="flex-1" />
        <div class="flex items-center gap-2">
          <button
            :if={@page == :show && @loaded_record && AshAdmin.Resource.actor?(@resource)}
            type="button"
            class={button_class(:secondary)}
            phx-click="set_actor"
            phx-value-resource={AshAdmin.Resource.name(@resource)}
            phx-value-domain={AshAdmin.Domain.name(@domain)}
            phx-value-pkey={AshAdmin.Helpers.encode_primary_key(@loaded_record)}
          >
            Set as actor
          </button>
          <.link
            :if={@page in [:update, :destroy] && AshAdmin.Resource.show_action(@resource)}
            navigate={show_path(assigns, @loaded_record)}
            class={button_class(:secondary)}
          >
            Show
          </.link>
          {actions_dropdown(assigns)}
        </div>
      </div>
    </div>
    """
  end

  # Which page is shown: the list and the show page are both read actions,
  # the show page has a record.
  defp page(nil, _action, _record), do: :none
  defp page(_resource, nil, _record), do: :none
  defp page(_resource, %{type: :read}, nil), do: :list
  defp page(_resource, %{type: :read}, _record), do: :show
  defp page(_resource, %{type: :create}, _record), do: :create
  defp page(_resource, %{type: :action}, _record), do: :generic
  defp page(_resource, %{type: type}, record) when not is_nil(record), do: type
  defp page(_resource, _action, _record), do: :none

  # Plural resource > current page. The resource links to its list.
  defp breadcrumb_items(%{resource: nil}), do: []

  defp breadcrumb_items(assigns) do
    list_action =
      if assigns.page == :list do
        assigns.action
      else
        assigns.resource |> actions(:read) |> List.first()
      end

    resource_item = {
      AshAdmin.Resource.plural_name(assigns.resource),
      list_action && action_path(assigns, list_action)
    }

    case page_label(assigns) do
      nil -> [resource_item]
      label -> [resource_item, {label, nil}]
    end
  end

  defp page_label(%{page: :none}), do: nil
  defp page_label(%{page: :show}), do: "Show"

  defp page_label(%{page: :list} = assigns) do
    # With several read actions, name the one in use.
    if length(actions(assigns.resource, :read)) > 1 do
      action_label(assigns.action)
    else
      "List"
    end
  end

  defp page_label(assigns), do: action_label(assigns.action)

  defp title(%{resource: nil}), do: AshAdmin.title()

  defp title(%{page: page, resource: resource}) when page in [:list, :none],
    do: AshAdmin.Resource.plural_name(resource)

  defp title(%{page: :show, resource: resource}), do: "Show #{AshAdmin.Resource.name(resource)}"
  defp title(%{page: :generic, action: action}), do: action_label(action)

  # "Update User" for the default action, "Change Password" for a named one.
  defp title(%{action: action, resource: resource}) do
    if action.name == action.type do
      "#{action_label(action)} #{AshAdmin.Resource.name(resource)}"
    else
      action_label(action)
    end
  end

  attr :items, :list,
    required: true,
    doc: "A list of `{label, path}`. A `nil` path renders plain text."

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb">
      <ol class="flex flex-wrap items-center gap-1.5 text-sm text-neutral-500 dark:text-neutral-400">
        <li :for={{{label, path}, index} <- Enum.with_index(@items)} class="flex items-center gap-1.5">
          <AshAdmin.CoreComponents.icon
            :if={index > 0}
            name="hero-chevron-right-mini"
            class="h-4 w-4 text-neutral-400 dark:text-neutral-500"
          />
          <.link
            :if={path}
            navigate={path}
            class="hover:text-neutral-900 dark:hover:text-neutral-100 transition-colors"
          >
            {label}
          </.link>
          <span :if={!path}>{label}</span>
        </li>
      </ol>
    </nav>
    """
  end

  @sections [
    create: "Create",
    read: "Read",
    update: "Update",
    destroy: "Destroy",
    action: "Generic"
  ]

  # One icon per action type, so a section reads at a glance.
  defp type_icon(:create), do: "hero-plus-mini"
  defp type_icon(:read), do: "hero-list-bullet-mini"
  defp type_icon(:update), do: "hero-pencil-square-mini"
  defp type_icon(:destroy), do: "hero-trash-mini"
  defp type_icon(:action), do: "hero-bolt-mini"

  defp actions_dropdown(assigns) do
    sections =
      for {type, label} <- @sections,
          type not in [:update, :destroy] or assigns.loaded_record,
          actions = actions(assigns.resource, type),
          actions != [],
          do: {type, label, actions}

    assigns = assign(assigns, :sections, sections)

    ~H"""
    <div :if={@sections != []} class="relative">
      <button
        type="button"
        phx-click={JS.toggle(to: "#actions-dropdown")}
        class={button_class(:secondary)}
      >
        Actions <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
      </button>
      <div
        id="actions-dropdown"
        class={"hidden absolute right-0 top-full mt-1.5 w-60 max-h-[70vh] overflow-y-auto #{menu_class()}"}
        phx-click-away={JS.hide(to: "#actions-dropdown")}
      >
        <div :for={{{type, label, actions}, index} <- Enum.with_index(@sections)}>
          <div :if={index > 0} class="aa-menu-separator" />
          <div class="aa-menu-label">{label}</div>
          <.link
            :for={action <- actions}
            navigate={
              !same_form?(assigns, type) &&
                action_path(assigns, action, record_for(type, @loaded_record))
            }
            patch={same_form?(assigns, type) && action_path(assigns, action, @loaded_record)}
            aria-current={current?(assigns, action) && "page"}
            class={["aa-menu-item", type == :destroy && "aa-menu-item-danger"]}
          >
            <AshAdmin.CoreComponents.icon name={type_icon(type)} class="aa-menu-icon" />
            <span class="flex-1 truncate">{action_label(action)}</span>
            <AshAdmin.CoreComponents.icon
              :if={current?(assigns, action)}
              name="hero-check-mini"
              class="h-4 w-4 shrink-0"
            />
          </.link>
        </div>
      </div>
    </div>
    """
  end

  # Switching between actions of the current form's type patches the form in
  # place, like the old form action switcher.
  defp same_form?(%{page: page, action: %{type: type}}, type)
       when page in [:create, :update, :destroy],
       do: true

  defp same_form?(_assigns, _type), do: false

  defp record_for(type, record) when type in [:update, :destroy], do: record
  defp record_for(_type, _record), do: nil

  # The show page is a read action with a record, it is not the list.
  defp current?(%{page: :show}, _action), do: false
  defp current?(%{action: nil}, _action), do: false

  defp current?(%{action: current}, action),
    do: current.type == action.type && current.name == action.name

  defp button_class(:secondary), do: "aa-btn-secondary"

  defp menu_class, do: "aa-menu"

  defp action_path(assigns, action, record \\ nil) do
    params =
      [
        domain: AshAdmin.Domain.name(assigns.domain),
        resource: AshAdmin.Resource.name(assigns.resource),
        action_type: action.type,
        action: action.name,
        table: assigns.table
      ] ++
        if(record, do: [primary_key: AshAdmin.Helpers.encode_primary_key(record)], else: [])

    AshAdmin.Helpers.admin_path(assigns.prefix, params)
  end

  defp show_path(assigns, record) do
    AshAdmin.Helpers.admin_path(assigns.prefix,
      domain: AshAdmin.Domain.name(assigns.domain),
      resource: AshAdmin.Resource.name(assigns.resource),
      table: assigns.table,
      primary_key: AshAdmin.Helpers.encode_primary_key(record),
      action_type: :read
    )
  end

  # The actions of a type that the admin config allows, primary first.
  defp actions(resource, type) do
    action_names =
      case type do
        :read -> AshAdmin.Resource.read_actions(resource)
        :action -> AshAdmin.Resource.generic_actions(resource)
        :create -> AshAdmin.Resource.create_actions(resource)
        :update -> AshAdmin.Resource.update_actions(resource)
        :destroy -> AshAdmin.Resource.destroy_actions(resource)
      end

    action_names
    |> Enum.map(&Ash.Resource.Info.action(resource, &1))
    |> Enum.filter(&(&1 && &1.type == type))
  end

  defp action_label(action) do
    action.name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
