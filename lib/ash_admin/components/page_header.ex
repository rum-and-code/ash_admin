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
  Page header shown above the content: breadcrumb and title on the left, the
  buttons for the current page on the right.

  - list: read action switcher, generic actions, create
  - show: update
  - update: show, destroy
  - destroy: show
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
          class="md:hidden -ml-1.5 rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-700 dark:text-slate-400 dark:hover:bg-white/5 dark:hover:text-slate-200"
          aria-label="Open navigation"
        >
          <AshAdmin.CoreComponents.icon name="hero-bars-3" class="h-5 w-5" />
        </button>
        <h1 class="text-2xl md:text-3xl font-bold tracking-tight text-slate-950 dark:text-white truncate">
          {@title}
        </h1>
        <div class="flex-1" />
        <div :if={@page in [:list, :generic]} class="flex items-center gap-2">
          {read_action_switcher(assigns)}
          {generic_actions_dropdown(assigns)}
          <.action_button
            id="create-actions-dropdown"
            actions={actions(@resource, :create)}
            label="New"
            icon="hero-plus-mini"
            variant={:primary}
            path={&action_path(assigns, &1)}
          />
        </div>
        <div :if={@page == :show} class="flex items-center gap-2">
          <.action_button
            id="update-actions-dropdown"
            actions={actions(@resource, :update)}
            label="Update"
            variant={:primary}
            path={&action_path(assigns, &1, @loaded_record)}
          />
        </div>
        <div :if={@page in [:update, :destroy]} class="flex items-center gap-2">
          <.link
            :if={AshAdmin.Resource.show_action(@resource)}
            navigate={show_path(assigns, @loaded_record)}
            class={button_class(:secondary)}
          >
            Show
          </.link>
          <.action_button
            :if={@page == :update}
            id="destroy-actions-dropdown"
            actions={actions(@resource, :destroy)}
            label="Destroy"
            variant={:danger}
            path={&action_path(assigns, &1, @loaded_record)}
          />
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
      <ol class="flex flex-wrap items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400">
        <li :for={{{label, path}, index} <- Enum.with_index(@items)} class="flex items-center gap-1.5">
          <AshAdmin.CoreComponents.icon
            :if={index > 0}
            name="hero-chevron-right-mini"
            class="h-4 w-4 text-slate-400 dark:text-slate-500"
          />
          <.link
            :if={path}
            navigate={path}
            class="hover:text-slate-900 dark:hover:text-slate-100 transition-colors"
          >
            {label}
          </.link>
          <span :if={!path}>{label}</span>
        </li>
      </ol>
    </nav>
    """
  end

  attr :id, :string, required: true
  attr :actions, :list, required: true
  attr :label, :string, required: true
  attr :icon, :string, default: nil
  attr :variant, :atom, required: true
  attr :path, :any, required: true, doc: "A function from an action to its path."

  # A link for a single action, a dropdown for several, nothing for none.
  defp action_button(%{actions: []} = assigns), do: ~H""

  defp action_button(%{actions: [action]} = assigns) do
    assigns = assign(assigns, :action, action)

    ~H"""
    <.link navigate={@path.(@action)} class={button_class(@variant)}>
      <AshAdmin.CoreComponents.icon :if={@icon} name={@icon} class="h-4 w-4" />
      {@label}
    </.link>
    """
  end

  defp action_button(assigns) do
    ~H"""
    <div class="relative">
      <button type="button" phx-click={JS.toggle(to: "##{@id}")} class={button_class(@variant)}>
        <AshAdmin.CoreComponents.icon :if={@icon} name={@icon} class="h-4 w-4" />
        {@label}
        <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
      </button>
      <div
        id={@id}
        class={"hidden absolute right-0 top-full mt-1 w-48 #{menu_class()}"}
        phx-click-away={JS.hide(to: "##{@id}")}
      >
        <.link :for={action <- @actions} navigate={@path.(action)} class={menu_item_class(false)}>
          {action_label(action)}
        </.link>
      </div>
    </div>
    """
  end

  defp button_class(:primary), do: "aa-btn-primary"

  defp button_class(:secondary), do: "aa-btn-secondary"

  defp button_class(:danger), do: "aa-btn-danger"

  defp menu_class, do: "aa-menu"

  defp menu_item_class(true), do: "aa-menu-item-active"
  defp menu_item_class(false), do: "aa-menu-item"

  # Small header toggles for the read action and the generic actions.
  defp toggle_class(active?) do
    [
      "aa-btn-ghost",
      active? && "bg-slate-100 text-slate-900 dark:bg-white/5 dark:text-slate-100"
    ]
  end

  defp read_action_switcher(assigns) do
    # With a single read action, the breadcrumb already links to the list.
    case actions(assigns.resource, :read) do
      read_actions when length(read_actions) < 2 ->
        ~H""

      read_actions ->
        assigns = assign(assigns, :read_actions, read_actions)

        ~H"""
        <div class="relative">
          <button
            type="button"
            phx-click={JS.toggle(to: "#read-actions-dropdown")}
            class={toggle_class(@page == :list)}
          >
            {if @page == :list, do: action_label(@action), else: "Read"}
            <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
          </button>
          <div
            id="read-actions-dropdown"
            class={"hidden absolute right-0 top-full mt-1 w-48 #{menu_class()}"}
            phx-click-away={JS.hide(to: "#read-actions-dropdown")}
          >
            <.link
              :for={action <- @read_actions}
              navigate={action_path(assigns, action)}
              class={menu_item_class(@page == :list && @action.name == action.name)}
            >
              {action_label(action)}
            </.link>
          </div>
        </div>
        """
    end
  end

  defp generic_actions_dropdown(assigns) do
    assigns = assign(assigns, :generic_actions, actions(assigns.resource, :action))

    ~H"""
    <div :if={@generic_actions != []} class="relative">
      <button
        type="button"
        phx-click={JS.toggle(to: "#generic-actions-dropdown")}
        class={toggle_class(@page == :generic)}
      >
        {if @page == :generic, do: action_label(@action), else: "Actions"}
        <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
      </button>
      <div
        id="generic-actions-dropdown"
        class={"hidden absolute right-0 top-full mt-1 w-48 #{menu_class()}"}
        phx-click-away={JS.hide(to: "#generic-actions-dropdown")}
      >
        <.link
          :for={action <- @generic_actions}
          navigate={action_path(assigns, action)}
          class={menu_item_class(@page == :generic && @action.name == action.name)}
        >
          {action_label(action)}
        </.link>
      </div>
    </div>
    """
  end

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
