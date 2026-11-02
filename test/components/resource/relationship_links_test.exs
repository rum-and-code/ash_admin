# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.RelationshipLinksTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  alias AshAdmin.Components.Resource.Table
  alias AshAdmin.Helpers
  alias AshAdmin.Test.{Comment, Domain, LinkDomain, LinkedNote, Post, UnlinkedNote}

  @prefix "/api/admin"

  defp post_path(post) do
    Helpers.admin_path(@prefix,
      domain: AshAdmin.Domain.name(Domain),
      resource: "Post",
      primary_key: post.id,
      action_type: "read"
    )
  end

  defp render_table_value(domain, record, resource, field) do
    attribute = Ash.Resource.Info.attribute(resource, field)

    domain
    |> Table.render_attribute(
      record,
      attribute,
      [],
      [],
      [actor: nil, tenant: nil, authorize?: false],
      nil,
      @prefix
    )
    |> to_html()
  end

  defp to_html(value) when is_binary(value), do: value
  defp to_html(value), do: value |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  describe "relationship_path/4" do
    test "returns the show path of the related record" do
      post_id = Ash.UUID.generate()

      assert Helpers.relationship_path(@prefix, Comment, :post_id, post_id) ==
               post_path(%{id: post_id})
    end

    test "returns nil when the prefix or the value is nil" do
      assert Helpers.relationship_path(nil, Comment, :post_id, Ash.UUID.generate()) == nil
      assert Helpers.relationship_path(@prefix, Comment, :post_id, nil) == nil
    end

    test "returns nil when the attribute is not a belongs_to foreign key" do
      assert Helpers.relationship_path(@prefix, Comment, :body, "text") == nil
    end

    test "returns nil when the destination is not visible in the admin" do
      assert Helpers.relationship_path(@prefix, LinkedNote, :post_id, Ash.UUID.generate()) =~
               "resource=Post"

      assert Helpers.relationship_path(
               @prefix,
               LinkedNote,
               :hidden_target_id,
               Ash.UUID.generate()
             ) ==
               nil
    end

    test "returns nil when link_relationships? is false" do
      assert Helpers.relationship_path(@prefix, UnlinkedNote, :post_id, Ash.UUID.generate()) ==
               nil
    end
  end

  test "the show page of a comment has a button to its post" do
    post = Ash.create!(Post, %{body: "A post"})
    comment = Ash.create!(Comment, %{body: "A comment", post_id: post.id})

    path =
      Helpers.admin_path(@prefix,
        domain: AshAdmin.Domain.name(Domain),
        resource: "Comment",
        primary_key: comment.id,
        action_type: "read"
      )

    {:ok, view, _html} = live(build_conn(), path)

    assert render(view) =~ post.id
    assert has_element?(view, ~s|a[data-relationship-link][href="#{post_path(post)}"]|)
  end

  test "a table of comments links to their post" do
    post = Ash.create!(Post, %{body: "A post"})
    comment = Ash.create!(Comment, %{body: "A comment", post_id: post.id})

    html = render_table_value(Domain, comment, Comment, :post_id)

    assert html =~
             ~s|href="#{Phoenix.HTML.html_escape(post_path(post)) |> Phoenix.HTML.safe_to_string()}"|

    assert html =~ post.id
  end

  test "a hidden destination renders plain text" do
    hidden_id = Ash.UUID.generate()
    note = struct(LinkedNote, id: Ash.UUID.generate(), hidden_target_id: hidden_id)

    assert render_table_value(LinkDomain, note, LinkedNote, :hidden_target_id) == hidden_id
  end

  test "link_relationships? false renders plain text" do
    post_id = Ash.UUID.generate()
    note = struct(UnlinkedNote, id: Ash.UUID.generate(), post_id: post_id)

    assert render_table_value(LinkDomain, note, UnlinkedNote, :post_id) == post_id
  end
end
