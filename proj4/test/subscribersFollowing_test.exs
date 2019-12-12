defmodule SubscribersFollowingTest do
  use ExUnit.Case

  '''
  Test to check subscriber list of a particular user
  2 -> 1
  3 -> 1
  Subscriber list of 1 -> [2,3]
  '''

  test "test to subscribe users" do
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
    TwitterEngine.subscribeToUsers(clientid2, [clientid1])
    TwitterEngine.subscribeToUsers(clientid3, [clientid1])
    assert TwitterEngine.findUserFollowers(clientid1) == [user2, user3]
  end

  '''
  Test to check the list of users that a particular user is following
  1 -> 2
  1 -> 3
  following list of 1 -> [2,3]
  '''

  test "test to following users" do
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
    TwitterEngine.subscribeToUsers(clientid1, [clientid2])
    TwitterEngine.subscribeToUsers(clientid1, [clientid3])
    assert TwitterEngine.findUserFollowing(clientid1) == [user2, user3]
  end

  test "test for tweet" do
    TwitterEngine.start()
    user1 = "testuser1"
    user2 = "testuser2"
    user3 = "testuser3"
    message = "This is a tweet with @testuser2 #gators #science"
    tweetid = 102_034
    {:ok, clientid1} = GenServer.start(TwitterClient, name: user1)
    {:ok, clientid2} = GenServer.start(TwitterClient, name: user2)
    {:ok, clientid3} = GenServer.start(TwitterClient, name: user3)
    TwitterEngine.registerUser(clientid1, "testuser1")
    TwitterEngine.registerUser(clientid2, "testuser2")
    TwitterEngine.registerUser(clientid3, "testuser3")
    TwitterEngine.subscribeToUsers(clientid2, [clientid1])
    TwitterEngine.subscribeToUsers(clientid3, [clientid1])
    TwitterEngine.tweet(tweetid, message, clientid1)
    assert :ets.lookup(:allTweets, clientid1) == [{clientid1, [[], [tweetid, message]]}]
    clientName = "testuser2"
    assert :ets.lookup(:mentionedUsers, clientName) == [{clientName, [[], [tweetid, message]]}]

    # assert :ets.lookup(:hashtags,) == ["#gators", "#science"]
  end
end
