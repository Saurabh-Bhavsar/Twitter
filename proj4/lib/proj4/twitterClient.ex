defmodule Proj4.TwitterClient do
  use GenServer
  @time 10000
  def init(state) do
    IO.inspect(state)
    Process.send_after(self(), :register, 0)
    {:ok, state}
  end

  '''
  def start_link(args) do
    GenServer.start_link(__MODULE__,args)
  end
  '''

  def validateTweet(tweet) do
    cond do
      emptyTweet(tweet) == true -> "Tweet cannot be empty"
      doesTweetContainAnyIncompHashtag(tweet) == false -> "Tweet contains incomplete hashtag"
      doesTweetContainAnyIncompMention(tweet) == false -> "Tweet contains incomplete mention"
      true -> true
    end
  end

  def emptyTweet(tweet) do
    String.trim(tweet) == ""
  end

  def doesTweetContainAnyIncompMention(mention) do
    at_count = mention |> String.graphemes() |> Enum.count(&(&1 == "@"))
    list = Regex.scan(~r/\B@[a-zA-Z0-9]+/, mention)
    list_length = length(list)
    at_count == list_length
  end

  def doesTweetContainAnyIncompHashtag(hashtag) do
    pound_count = hashtag |> String.graphemes() |> Enum.count(&(&1 == "#"))
    list = Regex.scan(~r/\B#[a-zA-Z0-9]+/, hashtag)
    list_length = length(list)
    pound_count == list_length
  end

  def handle_info({:startActivity, num_activities, num_messages}, state) do
    cond do
      num_messages > 0 ->
        IO.puts("Number of Messages left to send ")
        IO.inspect(num_messages)

        activity =
          Enum.random([
            "searchMyMention",
            "logout",
            "findMyTweets",
            "followHashtag",
            "searchHashtag",
            "tweet",
            "tweet",
            "tweet",
            "tweet",
            "tweet"
          ])

        case activity do
          "tweet" ->
            IO.puts("tweeting")
            tweet_text = Proj4.TwitterClient.generateTweet(state)
            # current_state = :sys.get_state(self())

            cond do
              validateTweet(tweet_text) == true ->
                IO.inspect(GenServer.call({:global, :server}, {:tweet, tweet_text}))
                # :sys.replace_state(self(), current_state - 1)

                Process.send_after(
                  self(),
                  {:startActivity, num_activities - 1, num_messages - 1},
                  @time
                )
            end

          "searchMyMention" ->
            IO.puts("Searching my tweets where i was mentioned")
            Proj4.TwitterClient.searchMentions()

          "logout" ->
            reply = GenServer.call({:global, :server}, :logout)
            Process.send_after(self(), {:login, num_messages}, 50000)
            IO.puts("logging out")

          "findMyTweets" ->
            IO.puts("Finding My tweets")
            Proj4.TwitterClient.myTweets()

          "followHashtag" ->
            IO.puts("follow a random hashtag")
            Proj4.TwitterClient.followAHashtag()

          "searchHashtag" ->
            IO.puts("search a random hashtag")
            Proj4.TwitterClient.searchHashtag(Enum.at(Proj4.TwitterClient.pickHashtag(1), 0))

          _ ->
            IO.puts("nothing")
            nil

          # "subscribeUser" -> nil

          true ->
            {:noreply, state}
        end

        if activity != "logout" do
          IO.inspect(num_activities)
          Process.send_after(
            self(),
            {:startActivity, num_activities - 1, num_messages},
            20000
          )
        end

      num_messages == 0 ->
        IO.puts("Simulation Complete for " <> self())
    end

    {:noreply, state}
  end

  '''
  def handle_info({:startActivity, num_activities, num_messages}, state) do
    cond do
      num_messages > 0 ->
        activity =
          Enum.random([
            "searchMyMention",
            "logout",
            "findMyTweets",
            "followHashtag",
            "searchHashtag",
            "tweet",
            "tweet",
            "tweet"
          ])

        case activity do
          "tweet" ->
            IO.puts("tweeting")
            tweet_text = TwitterClient.generateTweet()
            current_state = :sys.get_state(self())

            cond do
              validateTweet(tweet_text) == true ->
                GenServer.call({:global, :server}, {:tweet, tweet_text})
                :sys.replace_state(self(), current_state - 1)

                Process.send_after(
                  self(),
                  {:startActivity, num_activities - 1, num_messages - 1},
                  @time
                )
            end

          "searchMyMention" ->
            IO.puts("Searching my tweets where i was mentioned")
            TwitterClient.searchMentions()

          "logout" ->
            reply = GenServer.call({:global, :server}, {:logout})
            Process.send_after(self(), :login, 50000)
            IO.puts("logging out")

          "findMyTweets" ->
            IO.puts("Finding My tweets")
            TwitterClient.myTweets()

          "followHashtag" ->
            IO.puts("follow a random hashtag")
            TwitterClient.followAHashtag()

          "searchHashtag" ->
            IO.puts("search a random hashtag")
            TwitterClient.searchHashtag(Enum.at(TwitterClient.pickHashtag(1), 0))

          _ ->
            IO.puts("nothing")
            nil

          # "subscribeUser" -> nil

          true ->
            {:noreply, state}
        end

        Process.send_after(
          self(),
          {:startActivity, num_activities - 1, num_messages},
          @time
        )
    end

    {:noreply, state}
  end
  '''

  def generateTweet(state) do
    tweet_text =
      Enum.random(["Tweet1", "Tweet2", "Tweet3", "Tweet4", "Tweet5", "Tweet6", "Tweet7", "Tweet8"])

    followers = GenServer.call({:global, :server}, {:findUserFollowers}) |> elem(1)
    # IO.("My followers"<> followers)
    following = GenServer.call({:global, :server}, {:findUserFollowing}) |> elem(1)
    # IO.puts("My following" <> following)
    mentionUsers = followers ++ following
    IO.inspect(mentionUsers)
    # IO.inspect(mentionUsers)
    tweet_mentions = Enum.take_random(mentionUsers, Enum.random(1..3))

    mentions_list =
      Enum.map(tweet_mentions, fn user ->
        "@" <> user
      end)

    tweet_hashtags = pickHashtag(Enum.random(1..3))

    tweet_text <> " " <> Enum.join(mentions_list, " ") <> " " <> Enum.join(tweet_hashtags, " ")
  end

  def handle_info({:login, num_messages}, state) do
    {num_activities, username} = state
    pending_tweets = GenServer.call({:global, :server}, :login) |> elem(1)
    IO.puts(username <> " Logged in. I have following pending tweets")
    IO.inspect(pending_tweets)
    Process.send_after(self(), {:startActivity, num_messages, num_messages}, 10000)
    {:noreply, {num_messages, username}}
  end

  def followAHashtag do
    hashtag = Proj4.TwitterClient.pickHashtag(1)
  end

  def searchHashtag(hashtag) do
    IO.inspect(hashtag)
    search_results = GenServer.call({:global, :server}, {:searchHashtag, hashtag}) |> elem(1)
  end

  def searchMentions do
    mentionedTweets = GenServer.call({:global, :server}, {:searchMentions}) |> elem(1)
    IO.inspect(mentionedTweets)
  end

  def myTweets do
    tweets = GenServer.call({:global, :server}, {:findMyTweets}) |> elem(1)
    IO.inspect(tweets)
  end

  def handle_info(:register, state) do
    IO.inspect("self register on init")
    {num_activities, username} = state
    reply = GenServer.call({:global, :server}, {:register, username}) |> elem(1)

    IO.inspect(send(self(), {:login, num_activities}))
    {:noreply, state}
  end

  def handle_call({:subcribe, followingUsers}, _from, state) do
    GenServer.call({:global, :server}, {:subscribe, followingUsers})
    {:reply, {:subscribedUser}, state}
  end

  def handle_info({:retweet, tweet_id, tweet_text, number}, state) do
    cond do
      rem(number, 2) == 0 -> GenServer.call({:global, :server}, {:retweet, tweet_id, tweet_text})
      true -> nil
    end

    {:noreply, state}
  end

  def handle_cast({:recieveTweets, {tweet_id, text, userid}}, state) do
    IO.puts("New Tweet recieved" <> " " <> to_string(tweet_id) <> " " <> text <> " " <> userid)
    send(self(), {:retweet, tweet_id, text, Enum.random(1..1000)})
    # {:reply, {:tweetRecieved, text}}
    {:noreply, state}
  end

  def handle_info({:startActivity, num_activities}, _from, state) do
    # IO.puts("in handle call")
    Process.send_after(self(), {:startActivity, num_activities, num_activities}, @time)
    # {:reply, :activitiesComplete, state}
    {:noreply, state}
  end

  def handle_call({:deleteAccount}, _from, state) do
    GenServer.call({:global, :server}, {:deleteAccount})
    {:reply, :deleted, state}
  end

  def pickHashtag(count) do
    hashtagList = [
      "#science",
      "#technology",
      "#politics",
      "#economics",
      "#gators",
      "#sports",
      "#cars",
      "#movies",
      "#music",
      "#dancing",
      "#comedy"
    ]

    Enum.take_random(hashtagList, count)
  end

  @doc """
    def handle_call(_msg, _from, state) do
    {:reply, :unknown_call, state}
  end
  """
end
