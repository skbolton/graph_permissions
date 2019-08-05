defmodule GraphPermissions.Departments do
  alias Bolt.Sips.Response
  alias GraphPermissions.Departments.Department
  alias GraphPermissions.Permissions
  alias GraphPermissions.Permissions.Permission
  alias GraphPermissions.Users
  alias GraphPermissions.Users.User

  def add_department(params) do
    department = Department.new(params)

    cypher = """
    create (n:Department {id: '#{department.id}', name: '#{department.name}'})
    """

    Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    {:ok, department}
  end

  def get_by(params) do
    binding = "d"

    cypher = """
    match (#{binding}:Department {#{params_to_string(params)}}) return #{binding}
    """

    IO.inspect(cypher)

    response = Bolt.Sips.query!(Bolt.Sips.conn(), cypher)

    case Response.first(response) do
      nil ->
        {:ok, nil}

      result ->
        department =
          result[binding].properties
          |> Enum.reduce(%{}, fn {key, value}, user ->
            Map.put(user, String.to_atom(key), value)
          end)
          |> Department.new()

        {:ok, department}
    end
  end

  def give_permission(department_id, permission_id) do
    with {:ok, %Department{}} <- get_by(%{id: department_id}),
         {:ok, %Permission{}} <- Permissions.get_by(%{id: permission_id}) do
      cypher = """
      match (d:Department {id: '#{department_id}'}), (p:Permission {id: '#{permission_id}'})
        with d, p
        create (d)-[:CAN_DO]->(p)
      """

      Bolt.Sips.query(Bolt.Sips.conn(), cypher)
    else
      result ->
        {:error, result}
    end
  end

  def add_user(department_id, user_id) do
    with {:ok, %Department{}} <- get_by(%{id: department_id}),
         {:ok, %User{}} <- Users.get_by(%{id: user_id}) do
      cypher = """
      match (d:Department {id: '#{department_id}'}), (u:Person {id: '#{user_id}'})
        with d, u
        create (u)-[:WORKS_IN]->(d)
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
