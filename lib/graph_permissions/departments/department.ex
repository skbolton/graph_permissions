defmodule GraphPermissions.Departments.Department do
  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  def new(params) do
    %__MODULE__{
      id: params[:id] || UUID.uuid4(),
      name: params[:name]
    }
  end
end
