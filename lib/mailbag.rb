require 'em-imap'
require 'logger'
require 'yaml'

#
# Watch IMAP mailboxes for messages and react however you like.
#
# Usage Example:
#
#   Mailbag.run do |message|
#     puts message.from
#   end
#
module Mailbag


  Signal.trap('INT')  { cleanup; stop }
  Signal.trap('TERM') { stop }


  #
  # Listen for messages.  The block will be invoked when a message arrives
  # for any of the configured mailbag.
  #
  # This is a blocking method.
  #
  def self.run(config, &block)
    EM.run do
      prepare(config, &block)
      puts 'starting Event Machine'
    end
  end


  #
  # Build an EM::IMAP.  Block is passed through by .run though it
  # is possible to invoke .prepare on your own with a configuration
  # and block.
  #
  # Configuration expects a host, port, username, password, and folder.
  # If you don't provide these, you will not be warned.
  #
  # @private
  #
  def self.prepare config, &block
    puts "connecting to #{config['host']} for #{config['username']}"

    #          ...oh look, it's...
    # ~'~`*-~'~-~ THE ~='"~ RUG ~'~-``~=-~-'
    #     ...under which I sweep this...
    #                  -'O.o'-

    client = EM::IMAP.new config['host'], config['port'].to_i, true

    client.connect.bind! do
      puts "logging in"
      client.login config['username'], config['password']
    end.bind! do
      puts "changing folder"
      client.examine 'INBOX'
    end.bind! do
      puts "waiting for new email"
      client.wait_for_new_emails do |response|
        puts "handling a response: #{response.inspect}"
        begin
          # em-imap triggers new email when a message is
          # removed from mailbox.  if you fetch the 0th
          # message, then things stop working.
          if response.data > 0
            client.fetch(response.data, 'RFC822').callback do |messages|
              puts('fetching messages while waiting')
              messages.each do |message|
                yield message.attr['RFC822']
              end
            end
          end
        rescue => e
          warn e.backtrace
        end
      end
    end.errback do |error|
      warn error.backtrace
    end

    @client = client
  end

  def self.cleanup
    puts "disconnecting client"
    @client.disconnect
  end

  def self.stop
    puts "stopping Event Machine"
    EM.stop
  end

end