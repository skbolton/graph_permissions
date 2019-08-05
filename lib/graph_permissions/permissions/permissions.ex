defmodule GraphPermissions.Permissions do
  alias GraphPermissions.Permissions.Permission
  alias Bolt.Sips.Response

  def add_permission(params) do
    permission = Permission.new(params)

    cypher = """
    create (n:Permission {id: '#{permission.id}', name: '#{permission.name}'})
    """

    Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    {:ok, permission}
  end

  def get_by(params) do
    binding = "d"

    cypher = """
    match (#{binding}:Permission {#{params_to_string(params)}}) return #{binding}
    """

    response = Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    case Response.first(response) do
      nil ->
        {:ok, nil}

      result ->
        permission =
          result[binding].properties
          |> Enum.reduce(%{}, fn {key, value}, user ->
            Map.put(user, String.to_atom(key), value)
          end)
          |> Permission.new()

        {:ok, permission}
    end
  end

  defp params_to_string(params) do
    params
    |> Enum.map(fn {param, value} -> "#{param}: '#{value}'" end)
    |> Enum.join(", ")
  end
end
