defmodule GraphPermissions.Teams do
  alias GraphPermissions.Teams.Team
  alias GraphPermissions.Users.User
  alias GraphPermissions.Permissions
  alias GraphPermissions.Permissions.Permission
  alias GraphPermissions.Users
  alias Bolt.Sips.Response

  def add_team(params) do
    team = Team.new(params)

    cypher = """
    create (n:Team {id: '#{team.id}', name: '#{team.name}'})
    """

    Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    {:ok, team}
  end

  def get_by(params) do
    binding = "d"

    cypher = """
    match (#{binding}:Team {#{params_to_string(params)}}) return #{binding}
    """

    response = Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    case Response.first(response) do
      nil ->
        {:ok, nil}

      result ->
        team =
          result[binding].properties
          |> Enum.reduce(%{}, fn {key, value}, user ->
            Map.put(user, String.to_atom(key), value)
          end)
          |> Team.new()

        {:ok, team}
    end
  end

  def add_user(team_id, user_id) do
    with {:ok, %Team{}} <- get_by(%{id: team_id}),
         {:ok, %User{}} <- Users.get_by(%{id: user_id}) do
      cypher = """
      match (t:Team {id: '#{team_id}'}), (u:Person {id: '#{user_id}'})
        with t, u
        create (u)-[:BELONGS_TO]->(t)
      """

      Bolt.Sips.query(Bolt.Sips.conn(), cypher)
    else
      result ->
        {:error, result}
    end
  end

  def give_permission(team_id, permission_id) do
    with {:ok, %Team{}} <- get_by(%{id: team_id}),
         {:ok, %Permission{}} <- Permissions.get_by(%{id: permission_id}) do
      cypher = """
      match (t:Team {id: '#{team_id}'}), (p:Permission {id: '#{permission_id}'})
        with t, p
        create (t)-[:CAN_DO]->(p)
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
