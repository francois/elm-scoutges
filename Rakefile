require "securerandom"
require "shellwords"

namespace :jwt do
  namespace :secret do
    desc "Rotates the jwt.secret, both in the DB and in postgrest.conf"
    task :rotate do
      new_secret = SecureRandom.alphanumeric(48)

      sh [ "bin/dbconsole", "--command", "ALTER DATABASE scoutges_development SET \"jwt.secret\" TO '#{new_secret}'" ].shelljoin

      conf = File.read("postgrest.conf").split("\n")
      new_conf = conf.map do |line|
        next line unless line["jwt-secret"]
        "jwt-secret = \"#{new_secret}\""
      end

      File.write("postgrest.conf", new_conf.join("\n") + "\n")

      sh "overmind restart postgrest"
    end
  end
end

namespace :db do
  desc "Destroys the local database and creates a new one"
  task :reset do
    sh "overmind stop postgrest"
    sh "dropdb scoutges_development || exit 0"
    sh "createdb scoutges_development"
    sh "sqitch deploy"
    sh [ "bin/dbconsole", "--command", "INSERT INTO users(email, password, pguser) VALUES ('francois@teksol.info', 'monkeymonkey', 'authenticated')" ].shelljoin
    Rake::Task["jwt:secret:rotate"].invoke

    # jwt:secret:rotate will restart postgrest, no need to do it ourselves
  end
end
