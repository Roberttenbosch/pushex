defmodule Pushex.GCM.Request do
  @moduledoc """
  `Pushex.GCM.Request` represents a request that will be sent to GCM.
  It contains the notification, and all the metadata that can be sent with it.

  Only the key with a value will be sent to GCM, so that the proper default
  are used.
  """

  use Vex.Struct

  defstruct [
    :app,
    :registration_ids,
    :to,
    :collapse_key,
    :priority,
    :content_available,
    :delay_while_idle,
    :time_to_live,
    :restricted_package_name,
    :data,
    :notification
  ]

  @type t :: %__MODULE__{
    app: Pushex.GCM.App.t,
    registration_ids: [String.t],
    to: String.t,
    collapse_key: String.t,
    priority: String.t,
    content_available: boolean,
    delay_while_idle: boolean,
    time_to_live: non_neg_integer,
    restricted_package_name: String.t,
    data: map,
    notification: map
  }

  validates :app,
    presence: true,
    type: [is: Pushex.GCM.App]
  validates :registration_ids,
    type: [is: [[list: :binary], :nil]],
    presence: [if: [to: nil]]
  validates :to,
    type: [is: [:binary, :nil]],
    presence: [if: [registration_ids: nil]]
  validates :collapse_key,
    type: [is: [:binary, :nil]]
  validates :priority,
    type: [is: [:string, :nil]],
    inclusion: [in: ~w(high normal), allow_nil: true]
  validates :content_available,
    type: [is: [:boolean, :nil]]
  validates :delay_while_idle,
    type: [is: [:boolean, :nil]]
  validates :time_to_live,
    type: [is: [:integer, :nil]]
  validates :restricted_package_name,
    type: [is: [:binary, :nil]]
  validates :data,
    type: [is: [:map, :nil]]
  validates :notification,
    type: [is: [:map, :nil]]


  def create(params) do
    Pushex.Util.create_struct(__MODULE__, params)
  end
  def create!(params) do
    Pushex.Util.create_struct!(__MODULE__, params)
  end

  def create!(notification, app, opts) do
    params = opts
    |> Enum.into(%{})
    |> Map.merge(create_base_request(notification))
    |> Map.put(:app, app)
    |> normalize_opts()

    Pushex.Util.create_struct!(__MODULE__, params)
  end

  defp create_base_request(notification) do
    keys = ["notification", "data", :notification, :data]
    req = Enum.reduce(keys, %{}, fn(elem, acc) -> add_field(acc, notification, elem) end)
    if Enum.empty?(req) do
      %{notification: notification}
    else
      req
    end
  end

  defp add_field(request, notification, field) do
    case Map.fetch(notification, field) do
      {:ok, value} -> Map.put(request, field, value)
      :error -> request
    end
  end

  defp normalize_opts(opts) do
    if is_list(Map.get(opts, :to)) do
      {to, opts} = Map.pop(opts, :to)
      Map.put(opts, :registration_ids, to)
    else
      opts
    end
  end
end

defimpl Poison.Encoder, for: Pushex.GCM.Request do
  def encode(request, options) do
    request
    |> Map.from_struct()
    |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
    |> Enum.into(%{})
    |> Map.delete(:app)
    |> Poison.encode!(options)
  end
end
