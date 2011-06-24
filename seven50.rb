require 'rubygems'
require 'net/imap'
require 'highline/import'
require 'time'

tag = "750"

user = ask("Your IMAP name: ")
password = ask("Your password (will not echo): ") {|f| f.echo = false }

imap = Net::IMAP.new('imap.gmail.com', 993, true)
imap.login(user, password)
imap.select(tag)
imap.uid_search(["BODY", "One Month Challenge update!"]).each do |uid|
  data = imap.fetch(uid, ["RFC822", "RFC822.HEADER"]).first
  body = data.attr["RFC822"]
  date = data.attr["RFC822.HEADER"].split("\r\n").grep(/^Date/).first
  if (ppl = body.match(/Out of the original (\d+) people who signed up for the challenge this month, there are currently (\d+)/))
    puts Time.parse(date).strftime("%Y-%m-%d") + "\t" + ppl[1] + "\t" + ppl[2]
  end
end

