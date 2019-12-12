defmodule Proj4.Simulator do
  @moduledoc """
  Documentation for Proj4.Simulator
  """
  use GenServer
  require Logger
  @me Simulator

  def start_link(args) do
    IO.inspect(self())
    IO.puts("Simulator started")
    GenServer.start_link(__MODULE__, args, name: @me)
  end

  def init(args) do
    # DynamicSupervisor.init(strategy: :one_for_one)
    Process.send_after(self(), :kickoff, 5000)
    {:ok, args}
  end

  def handle_info(:kickoff, args) do
    {num_users, num_messages} = args
    Proj4Web.TwitterChannel.broadcast_num_users(%{users: num_users})
    clientList = createClients(num_users, num_messages)
    makeSubscriptions(clientList)
    {:noreply, args}
  end

  # startClientActivity(clientList, num_messages)

  # Process.sleep(:infinity)
  # end

  @doc """
  Hello world.


  """

  # def run({num_users, num_messages}) do
  # Process.register(self(), :mainProcess)
  # TwitterEngine.start()
  # clientList = ClientSpawner.createClients(num_users, num_messages)
  # IO.puts(clientList)
  # ClientSpawner.makeSubscriptions(clientList)
  # end

  def createClients(num_clients, num_messages) do
    try do
      clientList = []
      IO.puts("Creating clients")

      clientList =
        Enum.map(1..num_clients, fn index ->
          client_num = index |> Integer.to_string()
          client_name = "user" |> Kernel.<>(client_num) |> String.to_atom()
          username = "name" |> Kernel.<>(client_num)
          {:ok, clientid} = GenServer.start_link(Proj4.TwitterClient, {num_messages, username})
          IO.inspect(clientid)

          # GenServer.call(clientid, {:register, {username, serverpid}}, :infinity)
          clientid
          # clientList = clientList ++ [clientid]
          # IO.inspect(clientList)
        end)

      # Enum.each(1..num_clients, fn index ->
      #   IO.inspect(index)
      #   client_num = index |> Integer.to_string()
      #   client_name = "user" |> Kernel.<>(client_num) |> String.to_atom()
      #   {:ok, clientid} = GenServer.start(TwitterClient, name: client_name)
      #   IO.inspect(clientid)

      #   clientList = clientList ++ [clientid]
      #   IO.inspect(clientList)
      #   username = "name" |> Kernel.<>(client_num)

      #   GenServer.call(clientid, {:register, {username,serverpid}})
      # end)
      IO.puts("here")
      # IO.inspect(clientList)
      clientList
    rescue
      e -> IO.puts("An error occurred: " <> e)
      _ -> IO.puts("something wrong")
    end
  end

  def startClientActivity(clientList, num_activities) do
    # IO.inspect(num_activities)

    Enum.each(clientList, fn user ->
      IO.puts("calling user")
      IO.inspect(user)
      IO.inspect(send(user, {:startActivity, num_activities, num_activities}))
    end)
  end

  def makeSubscriptions(clientList) do
    Enum.each(clientList, fn user ->
      followingUsers =
        Enum.take_random(clientList -- [user], (20 * length(clientList) / 100) |> round)

      # IO.inspect(followingUsers)
      GenServer.call(user, {:subcribe, followingUsers}, 50000)
    end)
  end

  def run(:help) do
    IO.puts("""
    usage: mix escript.build
    escript project4 <num_users> <num_messages>
    Where num_users is number of users to simulate.
    num_messages if number of tweets

    """)

    System.halt(0)
  end
end
