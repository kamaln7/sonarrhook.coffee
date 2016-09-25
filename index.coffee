config = require './config'
http = require 'http'
mailgun = require('mailgun-js')({apiKey: config.mailgun.apikey, domain: config.mailgun.domain})
console.log {apiKey: config.mailgun.apikey, domain: config.mailgun.domain}

handleRequest = (req, res) ->
  if req.url isnt "/download?key=#{config.http.key}" or req.method isnt 'POST'
    res.writeHead(404, "Not Found")
    res.end()
    return

  body = []

  req.on 'data', (chunk) ->
    body.push chunk

  req.on 'end', ->
    download(req, res, Buffer.concat(body).toString())

download = (req, res, body) ->
  try
    event = JSON.parse body
  catch err
    switch err.name
      when 'SyntaxError'
        res.writeHead(400, "Bad Request")
        res.end()
        return
      else
        res.writeHead(500, "Internal Server Error")
        res.end()
        return

  unless event.EventType?
    res.writeHead(400, "Bad Request")
    res.end()
    return

  if event.EventType isnt 'Download'
    if event.EventType is 'Test'
      res.write('Tested')
    else
      res.writeHead(400, "Bad Request")

    res.end()
    return

  console.log "got series [#{event.Series.Id}] #{event.Series.Title}"

  unless config.series[event.Series.Id]?
    console.log "series id #{event.Series.Id} not in config"
    res.end()
    return

  recipients = config.series[event.Series.Id].map (name) ->
    if config.contacts[name]?
      return config.contacts[name]
    else
      console.log "contact #{name} not in config"
      return undefined
  .filter (x) -> x isnt undefined

  unless recipients.length
    console.log "no contacts to notify"
    return
  res.end()

  data =
    from: config.mailgun.from
    to: recipients
    subject: "New #{event.Series.Title} episodes downloaded"
    text: event.Episodes.map((ep) -> "+ S#{ep.SeasonNumber}E#{ep.EpisodeNumber} - #{ep.Title}").join "\n"

  mailgun.messages().send data, (err, body) ->
    if err
      console.log err
      res.writeHead(500, "Internal Server Error")
      res.end()
      return

    console.log "message id #{body.id}"
    res.end()

server = http.createServer handleRequest
server.listen config.http.port, config.http.server, ->
  console.log "listening on #{config.http.host}:#{config.http.port}"
