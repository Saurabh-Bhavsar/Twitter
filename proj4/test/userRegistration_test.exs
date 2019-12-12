defmodule UserRegistrationTest do
  use ExUnit.Case

  # Test for validating user registrations
  test "test to check whether user is registered" do
    TwitterEngine.start()
    num_messages = 10
    user1 = "testuser1"
    {:ok, clientid1} = GenServer.start(TwitterClient, {num_messages, user1})
    TwitterEngine.registerUser(clientid1, "testuser1")

    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) ==
             {clientid1, "testuser1", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == {"testuser1", clientid1}
  end

  # Test for registering the same user again
  test "test to check whether an old username is used" do
    TwitterEngine.start()
    num_messages = 10
    user1 = "testuser1"
    user2 = "testuser1"
    {:ok, clientid1} = GenServer.start(TwitterClient, {num_messages, user1})
    {:ok, clientid2} = GenServer.start(TwitterClient, {num_messages, user2})
    TwitterEngine.registerUser(clientid1, "testuser1")

    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) ==
             {clientid1, "testuser1", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == {"testuser1", clientid1}
    TwitterEngine.registerUser(clientid2, "testuser1")
    assert :ets.lookup(:userDetails, clientid2) |> Enum.at(0) == nil
  end

  # Test for deleting a user account
  test "test to delete a registered user" do
    TwitterEngine.start()
    num_messages = 10
    user1 = "testuser1"
    {:ok, clientid1} = GenServer.start(TwitterClient, {num_messages, user1})
    TwitterEngine.registerUser(clientid1, "testuser1")

    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) ==
             {clientid1, "testuser1", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == {"testuser1", clientid1}
    TwitterEngine.deleteAccount(clientid1)
    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) == nil
    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == nil
  end

  # Test for checking whether a user is allowed a username that was deleted
  test "test to check whether a user is allowed a username that was deleted" do
    TwitterEngine.start()
    num_messages = 10
    user1 = "testuser1"
    {:ok, clientid1} = GenServer.start(TwitterClient, {num_messages, user1})
    TwitterEngine.registerUser(clientid1, "testuser1")

    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) ==
             {clientid1, "testuser1", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == {"testuser1", clientid1}
    TwitterEngine.deleteAccount(clientid1)
    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) == nil
    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == nil
    TwitterEngine.registerUser(clientid1, "testuser1")

    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) ==
             {clientid1, "testuser1", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == {"testuser1", clientid1}
  end

  '''
  Test for registering multiple users
  '''

  test "test to register multiple users" do
    TwitterEngine.start()
    num_messages = 10
    user1 = "testuser1"
    user2 = "testuser2"
    user3 = "testuser3"
    {:ok, clientid1} = GenServer.start(TwitterClient, {num_messages, user1})
    {:ok, clientid2} = GenServer.start(TwitterClient, {num_messages, user2})
    {:ok, clientid3} = GenServer.start(TwitterClient, {num_messages, user3})
    TwitterEngine.registerUser(clientid1, "testuser1")
    TwitterEngine.registerUser(clientid2, "testuser2")
    TwitterEngine.registerUser(clientid3, "testuser3")

    assert :ets.lookup(:userDetails, clientid1) |> Enum.at(0) ==
             {clientid1, "testuser1", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser1") |> Enum.at(0) == {"testuser1", clientid1}

    assert :ets.lookup(:userDetails, clientid2) |> Enum.at(0) ==
             {clientid2, "testuser2", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser2") |> Enum.at(0) == {"testuser2", clientid2}

    assert :ets.lookup(:userDetails, clientid3) |> Enum.at(0) ==
             {clientid3, "testuser3", [], [], 1, []}

    assert :ets.lookup(:usernameTouserId, "testuser3") |> Enum.at(0) == {"testuser3", clientid3}
  end
end
