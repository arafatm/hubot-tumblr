# Description:
#   Post stuff to tumblr
#
# Dependencies:
#   "tumblr.js": "*"
#   "util": "*"
#
# Configuration:
#   TUMBLR_CONSUMER_KEY - Sign up for OAuth on tumblr
#   TUMBLR_CONSUMER_SECRET - Sign up for OAuth on tumblr
#   TUMBLR_TOKEN - Sign up for OAuth on tumblr
#   TUMBLR_TOKEN_SECRET - Sign up for OAuth on tumblr
#   TUMBLR_BLOG - url for your blog where stuff should be posted
#
# Commands:
#   http://<url> some description - post link to tumblr with optional description
#   http://link.to.gif.or.jpg some caption - post image link to tumblr with optional caption
#   "quote something" -- source attribute to   - post quote to tumblr with source attribution
#
# Author:
#   Arafat Mohamed

tumblr = require("tumblr.js")
Util = require("util")

module.exports = (robot) ->

  # Check TUMBLR keys are available
  working = true
  unless process.env.TUMBLR_CONSUMER_KEY?
    robot.logger.warning 'TUMBLR_CONSUMER_KEY environment variable not set'
    working = false
  unless process.env.TUMBLR_CONSUMER_SECRET?
    robot.logger.warning 'TUMBLR_CONSUMER_SECRET environment variable not set'
    working = false
  unless process.env.TUMBLR_TOKEN?
    robot.logger.warning 'TUMBLR_TOKEN environment variable not set'
    working = false
  unless process.env.TUMBLR_TOKEN_SECRET?
    robot.logger.warning 'TUMBLR_TOKEN_SECRET environment variable not set'
    working = false
  unless process.env.TUMBLR_BLOG?
    robot.logger.warning 'TUMBLR_BLOG environment variable not set'
    working = false

  blog = process.env.TUMBLR_BLOG

  client = tumblr.createClient(
    consumer_key: process.env.TUMBLR_CONSUMER_KEY
    consumer_secret: process.env.TUMBLR_CONSUMER_SECRET
    token: process.env.TUMBLR_TOKEN
    token_secret: process.env.TUMBLR_TOKEN_SECRET
  )

  handleresponse = (msg, err, data, typed) ->
      if err?
        msg.reply "Error posting: Try again :(\n#{Util.inspect(err, false, 4)}"
      else
        msg.send "#{typed} http://#{blog}/post/#{data.id}"


  robot.hear /"(.*)" -- (\w.*)/i, (msg) ->
    if not working
      return

    quote = msg.match[1]
    source = msg.match[2]
    client.quote blog, quote: quote, source: source, (err, data) ->
      handleresponse(msg, err, data, "Quoted")

  robot.hear /(.* )?(.?https?:\/\/\S*)(.*)?/i, (msg) ->
    if not working
      return

    bait = msg.match[0]

    # github irc hook. ignore
    if /http:\/\/git\.io/.test(bait)
      return

    url   = msg.match[2]
    if url[0] != 'h'
      return
    desc  = msg.match[3]
    if /.*(jpg|gif|png)$/i.test(url)
      if desc?
        client.photo blog, source: url, caption: desc, (err, data) ->
          handleresponse(msg, err, data, "Imaged")
      else
        client.photo blog, source: url, (err, data) ->
          handleresponse(msg, err, data, "Imaged")
    else if desc? 
      client.link blog, url: url, description: desc, (err, data) ->
        handleresponse(msg, err, data, "Linked")
    else
      client.link blog, url: url, (err, data) ->
        handleresponse(msg, err, data, "Linked")
