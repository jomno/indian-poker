require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAi
  def calculate(info)

    return []

    #Codes END
  end

  def get_name
    "MY AI!!!"
  end
end

s.add_handler("indian", MyAi.new)
s.serve
