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


  @logger = Logger.new 'mailbag.log'
  @config = YAML.load_file('config/mailbag.yml')


  Signal.trap('INT')  { cleanup }
  Signal.trap('TERM') { EM.stop }


  #
  # Listen for messages.  The block will be invoked when a message arrives
  # for any of the configured mailbag.
  #
  # This is a blocking method.
  #
  def self.run(&block)
    EM.run do
      @clients = @config['mailbags'].map { |name, settings| prepare(settings, &block) }
      @logger.debug 'the swamp lies dormant'
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
    @logger.debug "preparing #{config.inspect}"

    #          ...oh look, it's...
    # ~'~`*-~'~-~ THE ~='"~ RUG ~'~-``~=-~-'
    #     ...under which I sweep this...
    #                  -'O.o'-

    client = EM::IMAP.new config['host'], config['port'], true

    client.connect.bind! do
      client.login config['username'], config['password']
    end.bind! do
      client.examine config['folder']
    end.bind! do
      client.wait_for_new_emails do |response|
        client.fetch(response.data, 'RFC822').callback do |messages|
          @logger.info('fetching messages while waiting')
          messages.each do |message|
            yield message.attr['RFC822']
          end
        end
      end
    end.errback do |error|
      @logger.error(error)
    end

    client
  end

  def self.logger
    @logger
  end

  def self.cleanup
    @logger.info "disconnecting clients"
    @clients.map do |client|
      client.disconnect
    end
    EM.stop
  end

end