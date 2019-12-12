defmodule Proj4.TwitterEngine do
  @moduledoc """

  We have the following tables for our application
  userDetails - user_id (key), username, subscribers | list of subscribers, following | list of users followed by this user, status | Online or Disconnected, hashtagsFollwed |list of hashtags followed by this user

  reTweets - tweet_id (key), user_id , tweetText | contains tweet data , retweet_counter | number of times this tweet has been retweeted
  userTweets - user_id (key), [[tweet_id,tweet_text]]
  mentionedUsers - user_id(key), [[tweet_id, tweetText]] | List of tweets where this user was mentioned

  hashtags - hashtag(key), [[tweet_id, tweetText]] | List of tweets where this hashtag was used

  userTweetQueue - user_id (key), Tweets | list of tweets waiting to be seen by the user

  usernameTouserId  -username (key), user_id | mapping of process ID to username

  Types -
  user_id: pid
  username: String.t
  followers: pid | a list of user_id's followers
  listOfPeopleIFollow: list of pid's
  tweet_id: number | a sequence number, used in place of a timestamp
  hashtag: String.t
  """

  use GenServer

  def start_link(args) do
    IO.puts("Engine Started")
    GenServer.start_link(__MODULE__, 0, name: {:global, :server})
    # IO.inspect(tables)
  end

  def createTables do
    :ets.new(:userDetails, [:set, :public, :named_table])

    :ets.new(:allTweets, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:mentionedUsers, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:hashtags, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:userTweetQueue, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:usernameTouserId, [:set, :public, :named_table])
  end

  def registerUser(userid, username) do
    # IO.inspect("insert_user_details")
    reply = ""

    case :ets.match(:userDetails, {:_, username, :_, :_, :_, :_}) do
      [] ->
        # IO.inspect("insert_user_details")
        # IO.inspect(username)
        :ets.insert_new(:userDetails, {userid, username, [], [], 1, []})
        # IO.inspect(:ets.lookup(:userDetails, userid))
        :ets.insert_new(:userTweetQueue, {userid, [[]]})
        # IO.inspect(:ets.lookup(:userTweetQueue, userid))
        :ets.insert_new(:allTweets, {userid, [[]]})
        :ets.insert_new(:usernameTouserId, {username, userid})
        :ets.insert_new(:mentionedUsers, {username, [[]]})

      # IO.inspect("End - insert_user_details")

      _ ->
        reply = "username is in use"
    end

    reply
  end

  def subscribeToUsers(userid, users) do
    # IO.puts("herasfe")
    # IO.puts("subscribe")
    # IO.inspect(userid)
    # IO.inspect(users)
    # IO.inspect(:ets.lookup(:userDetails, users.first()))
    Enum.each(users, fn user ->
      [
        {following_user_id, following_username, following_user_subscribers,
         following_user_following, following_user_status, following_user_hashtags}
      ] = :ets.lookup(:userDetails, user)

      following_user_subscribers = Enum.concat(following_user_subscribers, [userid])

      :ets.insert(
        :userDetails,
        {following_user_id, following_username, following_user_subscribers,
         following_user_following, following_user_status, following_user_hashtags}
      )

      [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
        :ets.lookup(:userDetails, userid)

      user_following = Enum.concat(user_following, [user])
      # IO.inspect(user_following)
      :ets.insert(
        :userDetails,
        {user_id, username, user_subscribers, user_following, user_status, user_hashtags}
      )
    end)

    # IO.inspect(:ets.lookup(:userDetails, userid))
  end

  def handle_info({:isUserOnline, client_id}, state) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id)

    reply =
      case user_status do
        1 -> true
        0 -> false
      end

    {:reply, {:userStatus, reply}}
  end

  def tweet(tweet_id, message, userid) do
    text = message
    [{user, currentTweets}] = :ets.lookup(:allTweets, userid)

    [{_, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, userid)

    currentTweets = Enum.concat(currentTweets, [[tweet_id, text]])

    :ets.insert(:allTweets, {user, currentTweets})
    # IO.inspect(:ets.lookup(:allTweets, user))

    Enum.each(user_subscribers, fn subscriber ->
      # IO.inspect(:ets.lookup(:userDetails, userid))
      [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
        :ets.lookup(:userDetails, subscriber)

      reply =
        case user_status do
          1 -> true
          0 -> false
        end

      # reply = send(self(), {:isUserOnline, subscriber}) |> elem(0)
      # IO.inspect(reply)
      case reply do
        true ->
          GenServer.cast(subscriber, {:recieveTweets, {tweet_id, text, username}})

        false ->
          [{_, pending_tweets}] = :ets.lookup(:userTweetQueue, subscriber)
          pending_tweets = pending_tweets ++ [[tweet_id, message]]
          :ets.insert(:userTweetQueue, {userid, pending_tweets})

        _ ->
          nil
      end
    end)

    [mentions, hashtags] = extractMentionsAndHashtags(text)

    case mentions do
      [] ->
        IO.puts("No mentions")

      _ ->
        Enum.each(mentions, fn mentionedUser ->
          IO.puts("Mentioned user-")
          # IO.inspect(String.slice(Enum.at(mentionedUser,0),1..-1))
          mentionUsername = String.slice(Enum.at(mentionedUser, 0), 1..-1)
          [{_, user_id}] = :ets.lookup(:usernameTouserId, mentionUsername)
          [{username, current_tweets}] = :ets.lookup(:mentionedUsers, mentionUsername)
          current_tweets = current_tweets ++ [[tweet_id, message]]
          :ets.insert(:mentionedUsers, {mentionUsername, current_tweets})
          # IO.inspect(:ets.lookup(:mentionedUsers, mentionUsername))
          reply = GenServer.cast(user_id, {:recieveTweets, {tweet_id, text, username}})
          # IO.inspect(reply)
        end)
    end

    case hashtags do
      [] ->
        nil

      _ ->
        Enum.each(hashtags, fn hashtag ->
          IO.puts("here is the error")
          IO.inspect(:ets.lookup(:hashtags, hashtag))

          case :ets.lookup(:hashtags, hashtag) do
            [] ->
              :ets.insert(:hashtags, {hashtag, [[tweet_id, message]]})

            # IO.inspect(:ets.lookup(:hashtags, hashtag))
            _ ->
              [{_, current_tweets}] = :ets.lookup(:hashtags, hashtag)
              current_tweets = current_tweets ++ [[tweet_id, message]]
              :ets.insert(:hashtags, {hashtag, current_tweets})
              # IO.inspect(:ets.lookup(:hashtags, hashtag))
          end
        end)
    end
  end

  def findUserFollowers(client_id) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id)

    subscriber_names =
      Enum.map(user_subscribers, fn client ->
        [{_, name, _, _, _, _}] = :ets.lookup(:userDetails, client)
        name
      end)

    subscriber_names
  end

  def findUserFollowing(client_id) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id)

    following_names =
      Enum.map(user_following, fn client ->
        [{_, name, _, _, _, _}] = :ets.lookup(:userDetails, client)
        name
      end)

    following_names
  end

  def deleteAccount(client_id) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id)

    :ets.delete(:userDetails, client_id)
    :ets.lookup(:userDetails, client_id)
    :ets.delete(:usernameTouserId, username)
    :ets.lookup(:usernameTouserId, client_id)
  end

  def extractMentionsAndHashtags(tweet_text) do
    mentions_list = Regex.scan(~r/\B@[a-zA-Z0-9]+/, tweet_text)
    hashtag_list = Regex.scan(~r/\B#[a-zA-Z0-9]+/, tweet_text)
    [mentions_list, hashtag_list]
  end

  def findUserMentions(client_id) do
    tweets = :ets.lookup(:mentionedUsers, client_id)
  end

  def findMyTweets(client_id) do
    tweets = :ets.lookup(:allTweets, client_id)
  end

  def searchHashtag(hashtag) do
    tweets = :ets.lookup(:hashtags, hashtag)
  end

  def handle_call({:retweet, tweet_id, tweet_text}, client_id, state) do

    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id |> elem(0))
    Proj4Web.TwitterChannel.broadcast_retweets(%{retweet: tweet_text})
    IO.puts("Retweeting " <> tweet_text)

    Enum.each(user_subscribers, fn subscriber ->
      GenServer.cast(subscriber, {:recieveTweets, {tweet_id, tweet_text, username}})
    end)

    {:reply, :retweeted, state}
  end

  def handle_call({:register, username}, client_id, state) do
    IO.inspect("handle register user")
    IO.inspect(username)
    Proj4.TwitterEngine.registerUser(client_id |> elem(0), username)
    {:reply, {client_id, :registeredSuccesfully}, state}
  end

  def handle_call({:subscribe, followingUsers}, client_id, state) do
    Proj4.TwitterEngine.subscribeToUsers(client_id |> elem(0), followingUsers)
    {:reply, :subscribedSuccesfully, state}
  end

  def handle_call(:login, client_id, state) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id |> elem(0))

    :ets.insert(
      :userDetails,
      {user_id, username, user_subscribers, user_following, 1, user_hashtags}
    )

    [{user_id, tweets}] = :ets.lookup(:userTweetQueue, user_id)

    {:reply, {:pendingTweets, tweets}, state}
  end

  def handle_call(:logout, client_id, state) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id |> elem(0))

    :ets.insert(
      :userDetails,
      {user_id, username, user_subscribers, user_following, 0, user_hashtags}
    )

    {:reply, :loggedOut, state}
  end

  def handle_call({:searchMentions}, client_id, state) do
    userMentions = Proj4.TwitterEngine.findUserMentions(client_id |> elem(0))
    {:reply, {:foundMentions, userMentions}, state}
  end

  def handle_call({:findMyTweets}, client_id, state) do
    userTweets = Proj4.TwitterEngine.findMyTweets(client_id |> elem(0))
    {:reply, {:foundTweets, userTweets}, state}
  end

  def handle_call({:findUserFollowers}, client_id, state) do
    followers = Proj4.TwitterEngine.findUserFollowers(client_id |> elem(0))
    {:reply, {:foundFollowers, followers}, state}
  end

  def handle_call({:findUserFollowing}, client_id, state) do
    followers = Proj4.TwitterEngine.findUserFollowing(client_id |> elem(0))
    {:reply, {:foundFollowing, followers}, state}
  end

  def handle_call({:tweet, tweet_text}, client_id, state) do
    tweet_id = Enum.random(1..999_999)
    Proj4Web.TwitterChannel.broadcast_tweets(%{tweet: tweet_text})
    Proj4.TwitterEngine.tweet(tweet_id, tweet_text, client_id |> elem(0))
    {:reply, :tweeted, state}
  end

  def handle_call({:searchHashtag, hashtag}, client_id, state) do
    tweets = Proj4.TwitterEngine.searchHashtag(hashtag)
    {:reply, {:foundHashtags, tweets}, state}
  end

  def handle_call({:deleteAccount}, client_id, state) do
    [{user_id, username, user_subscribers, user_following, user_status, user_hashtags}] =
      :ets.lookup(:userDetails, client_id)

    :ets.delete(:userDetails, client_id |> elem(0))
    :ets.delete(:usernameTouserId, username)
    {:reply, {:deleted, :ets.lookup(:userDetails, client_id |> elem(0))}, state}
  end

  def init(state) do
    IO.puts("Init")
    Proj4.TwitterEngine.createTables()
    {:ok, state}
  end
end
