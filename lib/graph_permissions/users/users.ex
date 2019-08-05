defmodule GraphPermissions.Users do
  alias GraphPermissions.Users.User
  alias GraphPermissions.Permissions
  alias GraphPermissions.Permissions.Permission
  alias GraphPermissions.Roles
  alias GraphPermissions.Roles.Role
  alias Bolt.Sips.Response

  def add_user(params) do
    user = User.new(params)

    cypher = """
    create (n:Person {id: '#{user.id}', first_name: '#{user.first_name}', last_name: '#{
      user.last_name
    }'})
    """

    Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    {:ok, user}
  end

  def get_by(params) do
    binding = "p"

    cypher = """
    match (#{binding}:Person {#{params_to_string(params)}}) return #{binding}
    """

    response = Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    case Response.first(response) do
      nil ->
        {:ok, nil}

      result ->
        user =
          result[binding].properties
          |> Enum.reduce(%{}, fn {key, value}, user ->
            Map.put(user, String.to_atom(key), value)
          end)
          |> User.new()

        {:ok, user}
    end
  end

  def give_role(user_id, role_id) do
    with {:ok, %User{}} <- get_by(%{id: user_id}),
         {:ok, %Role{}} <- Roles.get_by(%{id: role_id}) do
      cypher = """
      match (u:Person {id: '#{user_id}'}), (r:Role {id: '#{role_id}'})
        with u, r
        create (u)-[:HAS_ROLE]->(r)
      """

      Bolt.Sips.query(Bolt.Sips.conn(), cypher)
    else
      result ->
        {:error, result}
    end
  end

  def permissions_for(user_id) do
    with {:ok, %User{}} <- get_by(%{id: user_id}) do
      cypher = """
      match (u:Person {id: '#{user_id}'})
        with u
        optional match (u)-[]->(:Department)-[]->(dp:Permission)
        optional match (u)-[]->(:Team)-[]->(tp:Permission)
        optional match (u)-[]->(:Role)-[]->(rp:Permission)
        optional match (u)-[]->(pp:Permission)
        RETURN Distinct dp, tp, rp, pp
      """

      {:ok, %{results: results}} = Bolt.Sips.query(Bolt.Sips.conn(), cypher)

      results
      |> Enum.flat_map(fn map ->
        Enum.reduce(map, [], &reduce_permissions/2)
      end)
      |> Enum.uniq_by(fn item -> item.name end)
    end
  end

  def give_permission(user_id, permission_id) do
    with {:ok, %User{}} <- get_by(%{id: user_id}),
         {:ok, %Permission{}} <- Permissions.get_by(%{id: permission_id}) do
      cypher = """
      match (u:Person {id: '#{user_id}'}), (p:Permission {id: '#{permission_id}'})
        with u, p
        create (u)-[:CAN_DO]->(p)
      """

      Bolt.Sips.query(Bolt.Sips.conn(), cypher)
    else
      result ->
        {:error, result}
    end
  end

  defp reduce_permissions({_permission_key, nil}, flat_permissions), do: flat_permissions

  defp reduce_permissions(
         {"dp", %Bolt.Sips.Types.Node{properties: %{"name" => name}}},
         flat_permissions
       ) do
    [%{name: name, from: "Department"} | flat_permissions]
  end

  defp reduce_permissions(
         {"tp", %Bolt.Sips.Types.Node{properties: %{"name" => name}}},
         flat_permissions
       ) do
    [%{name: name, from: "Team"} | flat_permissions]
  end

  defp reduce_permissions(
         {"rp", %Bolt.Sips.Types.Node{properties: %{"name" => name}}},
         flat_permissions
       ) do
    [%{name: name, from: "Role"} | flat_permissions]
  end

  defp reduce_permissions(
         {"pp", %Bolt.Sips.Types.Node{properties: %{"name" => name}}},
         flat_permissions
       ) do
    [%{name: name, from: "Personal"} | flat_permissions]
  end

  defp params_to_string(params) do
    params
    |> Enum.map(fn {param, value} -> "#{param}: '#{value}'" end)
    |> Enum.join(", ")
  end
end
