require 'messaging_helper'
require 'mailbag'

Mailbag.run do |message|
  begin
    MH.publish 'mailbag', { rfc822: message }, 'tbd'
  rescue RuntimeError => e
    Mailbag.logger(e)
    Mailbag.logger(message)
  end
end