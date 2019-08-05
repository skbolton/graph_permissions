defmodule GraphPermissions.Users.User do
  @enforce_keys [:id, :first_name, :last_name]
  defstruct [:id, :first_name, :last_name]

  def new(params) do
    %__MODULE__{
      id: params[:id] || UUID.uuid4(),
      first_name: params[:first_name],
      last_name: params[:last_name]
    }
  end
end
