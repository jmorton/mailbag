$:.push('./lib')

require 'minitest/autorun'
require 'debugger'

class MailbagTest < Minitest::Test

  require 'mailbag'
  require 'mail'

  def mail
    Mail.read_from_string(open('./test/mail.txt').read)
  end

  def test_text_to_mail
    puts mail.from
    assert mail.from, 'jon.morton@gmail.com'
  end

end