defmodule TwitterClientHelperTest do
  use ExUnit.Case

  # Tests for validating tweets

  test "test for empty tweet string" do
    tweet = ""
    assert TwitterClient.validateTweet(tweet) == "Tweet cannot be empty"
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[], []]
  end

  test "test for only @ in the tweet" do
    tweet = "@"
    assert TwitterClient.validateTweet(tweet) == "Tweet contains incomplete mention"
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[], []]
  end

  test "test for only # in the hashtag" do
    tweet = "#"
    assert TwitterClient.validateTweet(tweet) == "Tweet contains incomplete hashtag"
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[], []]
  end

  test "test for incomplete hashtag" do
    tweet = "this is #hashtag # @user1"
    assert TwitterClient.validateTweet(tweet) == "Tweet contains incomplete hashtag"
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[["@user1"]], [["#hashtag"]]]
  end

  test "test for incomplete mention" do
    tweet = "this is a tweet with a incomplete @ @mention and complete #hashtag"
    assert TwitterClient.validateTweet(tweet) == "Tweet contains incomplete mention"
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[["@mention"]], [["#hashtag"]]]
  end

  test "test for a valid tweet" do
    tweet = "this is a valid tweet with #hashtag and @mention"
    assert TwitterClient.validateTweet(tweet) == true
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[["@mention"]], [["#hashtag"]]]
  end

  test "test for a tweet without hashtag and mention" do
    tweet = "this is a valid tweet without mentions and hashtags"
    assert TwitterClient.validateTweet(tweet) == true
    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [[], []]
  end

  test "test for one hashtag and multiple mentions" do
    tweet = "this is a valid #tweet with multiple @mention1 @mention2 @mention3"
    assert TwitterClient.validateTweet(tweet) == true

    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [
             [["@mention1"], ["@mention2"], ["@mention3"]],
             [["#tweet"]]
           ]
  end

  test "test for one mention and multiple hashtags" do
    tweet = "this is a valid tweet with one @mention and multiple #hashtag1 #hashtag2 #hashtag3"
    assert TwitterClient.validateTweet(tweet) == true

    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [
             [["@mention"]],
             [["#hashtag1"], ["#hashtag2"], ["#hashtag3"]]
           ]
  end

  test "test for multiple mentions and hashtags" do
    tweet =
      "this is a valid tweet with multiple @mention and #hashtag #hashtag1 @mention1 @mention3 #hahstag3"

    assert TwitterClient.validateTweet(tweet) == true

    assert TwitterEngine.extractMentionsAndHashtags(tweet) == [
             [["@mention"], ["@mention1"], ["@mention3"]],
             [["#hashtag"], ["#hashtag1"], ["#hahstag3"]]
           ]
  end
end
