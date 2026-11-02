# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.ShowLayoutTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  alias AshAdmin.Test.{ShowArticle, ShowAuthor, ShowBook}

  setup do
    author =
      Ash.create!(ShowAuthor, %{
        first_name: "Ada",
        last_name: "Lovelace",
        email: "ada@example.com",
        nicknames: ["Countess", "Enchantress"]
      })

    Ash.create!(ShowBook, %{title: "Notes", author_id: author.id})
    Ash.create!(ShowArticle, %{headline: "Analytical engine", author_id: author.id})

    {:ok, view, _html} = live(build_conn(), show_path(author))

    %{author: author, view: view}
  end

  defp show_path(author) do
    AshAdmin.Helpers.admin_path("/api/admin",
      domain: AshAdmin.Domain.name(AshAdmin.Test.ShowDomain),
      resource: "ShowAuthor",
      primary_key: author.id,
      action_type: "read"
    )
  end

  describe "attributes" do
    test "every scalar attribute renders in an input-styled box", %{view: view, author: author} do
      for field <- [:id, :first_name, :last_name, :email, :nicknames] do
        assert has_element?(view, ~s|div[data-field="#{field}"]|), "#{field} is not boxed"
      end

      assert has_element?(view, ~s|div[data-field="email"]|, "ada@example.com")
      assert has_element?(view, ~s|div[data-field="id"]|, author.id)
      assert has_element?(view, ~s|div[data-field="nicknames"]|, "Countess, Enchantress")
      refute has_element?(view, "textarea[disabled]")
    end
  end

  describe "calculations" do
    test "render in the main panel with a calculate button and no value", %{view: view} do
      assert has_element?(view, "#calculation-full_name button[type=submit]", "Calculate")
      refute has_element?(view, ~s|#calculation-full_name div[data-field="full_name"]|)
    end

    test "clicking calculate shows the value in a box", %{view: view} do
      view
      |> form("#calculation-full_name form")
      |> render_submit()

      assert has_element?(view, ~s|div[data-field="full_name"]|, "Ada Lovelace")
      refute has_element?(view, "#calculation-full_name button[type=submit]")
    end

    test "a calculation with arguments keeps its form to recalculate", %{view: view} do
      view
      |> form("#calculation-greeting form", %{"greeting" => %{"salutation" => "Ada"}})
      |> render_submit()

      assert has_element?(view, ~s|div[data-field="greeting"]|, "Hello Ada")
      assert has_element?(view, "#calculation-greeting button[type=submit]", "Recalculate")
    end
  end

  describe "relationships" do
    test "render as tabs with only the first panel shown", %{view: view} do
      assert has_element?(view, "#relationship-tab-books[aria-selected=true]")
      assert has_element?(view, "#relationship-tab-articles[aria-selected=false]")
      assert has_element?(view, "#relationship-panel-books")
      refute has_element?(view, "#relationship-panel-articles")
      assert has_element?(view, "#relationship-panel-books button[phx-click=load]")
    end

    test "selecting a tab shows its panel", %{view: view} do
      view |> element("#relationship-tab-articles") |> render_click()

      assert has_element?(view, "#relationship-tab-articles[aria-selected=true]")
      assert has_element?(view, "#relationship-panel-articles")
      refute has_element?(view, "#relationship-panel-books")
    end

    test "load and unload work inside a tab", %{view: view} do
      view |> element("#relationship-tab-articles") |> render_click()
      view |> element("#relationship-panel-articles button[phx-click=load]") |> render_click()

      assert render(view) =~ "Analytical engine"

      view |> element("#relationship-panel-articles button[phx-click=unload]") |> render_click()

      refute render(view) =~ "Analytical engine"
      assert has_element?(view, "#relationship-panel-articles button[phx-click=load]")
    end
  end
end
