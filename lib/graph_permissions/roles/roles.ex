defmodule GraphPermissions.Roles do
  alias GraphPermissions.Roles.Role
  alias GraphPermissions.Permissions
  alias GraphPermissions.Permissions.Permission
  alias Bolt.Sips.Response

  def add_role(params) do
    role = Role.new(params)

    cypher = """
    create (n:Role {id: '#{role.id}', name: '#{role.name}'})
    """

    Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    {:ok, role}
  end

  def get_by(params) do
    binding = "d"

    cypher = """
    match (#{binding}:Role {#{params_to_string(params)}}) return #{binding}
    """

    response = Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    case Response.first(response) do
      nil ->
        {:ok, nil}

      result ->
        role =
          result[binding].properties
          |> Enum.reduce(%{}, fn {key, value}, user ->
            Map.put(user, String.to_atom(key), value)
          end)
          |> Role.new()

        {:ok, role}
    end
  end

  def give_permission(role_id, permission_id) do
    with {:ok, %Role{}} <- get_by(%{id: role_id}),
         {:ok, %Permission{}} <- Permissions.get_by(%{id: permission_id}) do
      cypher = """
      match (r:Role {id: '#{role_id}'}), (p:Permission {id: '#{permission_id}'})
        with r, p
        create (r)-[:CAN_DO]->(p)
      """

      Bolt.Sips.query(Bolt.Sips.conn(), cypher)
    else
      result ->
        {:error, result}
    end
  end

  defp params_to_string(params) do
    params
    |> Enum.map(fn {param, value} -> "#{param}: '#{value}'" end)
    |> Enum.join(", ")
  end
end
