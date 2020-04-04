require "securerandom"
require "shellwords"

namespace :jwt do
  namespace :secret do
    desc "Rotates the jwt.secret, both in the DB and in postgrest.conf"
    task :rotate do
      new_secret = SecureRandom.alphanumeric(48)

      cmd = [ "bin/dbconsole", "-c", "ALTER DATABASE scoutges_development SET \"jwt.secret\" TO '#{new_secret}'" ]
      sh cmd.shelljoin

      conf = File.read("postgrest.conf").split("\n")
      new_conf = conf.map do |line|
        next line unless line["jwt-secret"]
        "jwt-secret = \"#{new_secret}\""
      end

      File.write("postgrest.conf", new_conf.join("\n") + "\n")

      sh "killall postgrest"
    end
  end
end
