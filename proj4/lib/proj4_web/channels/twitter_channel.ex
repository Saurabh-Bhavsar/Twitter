defmodule Proj4Web.TwitterChannel do
  use Phoenix.Channel

  def join("twitter_update:*", _message, socket) do
    {:ok, socket}
  end

  def broadcast_num_users(n) do
    Proj4Web.Endpoint.broadcast("twitter_update:*", "num_users", n)
  end

  def broadcast_tweets(%{tweet: tweet_text}) do
    Proj4Web.Endpoint.broadcast("twitter_update:*", "tweet", %{tweet: tweet_text})
  end

  def broadcast_retweets(%{retweet: tweet_text}) do
    Proj4Web.Endpoint.broadcast("twitter_update:*", "retweet", %{retweet: tweet_text})
  end

  def broadcast_subscribers(%{subscriber: value}) do
    Proj4Web.Endpoint.broadcast("twitter_update:*", "subscribers", %{subscriber: value})
  end
end
