require 'mailbag'

# To send all output to the terminal when
# launched using foreman (as intended).
$stdout.sync = true
$stderr.sync = true

config = {  'host'     =>  ENV['MAILBAG_HOST'],
            'port'     =>  ENV['MAILBAG_PORT'],
            'username' =>  ENV['MAILBAG_USER'],
            'password' =>  ENV['MAILBAG_PASS'],
            'folder'   =>  ENV['MAILBAG_FOLD'] }

$stderr.puts "an example error"

Mailbag.run(config) do |message|
  puts message
end
