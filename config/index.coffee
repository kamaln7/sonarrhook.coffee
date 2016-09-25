config =
  http:
    host: '127.0.0.1'
    port: 8080
    key: 'ooo-secret-api-key'
  
  mailgun:
    from: 'me@domain.com'
    domain: 'domain.com'
    apikey: 'key-lalala'

  contacts:
    alex: 'alex@emails.com'
    sam: 'sam@emails.com'

  series:
    2: ['alex', 'sam']
    3: ['sam']

module.exports = config
