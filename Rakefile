require "securerandom"
require "shellwords"

namespace :jwt do
  namespace :secret do
    desc "Rotates the jwt.secret, both in the DB and in postgrest.conf"
    task :rotate do
      new_secret = SecureRandom.alphanumeric(48)

      sh [ "bin/dbconsole", "--command", "ALTER DATABASE scoutges_development SET \"jwt.secret\" TO '#{new_secret}'" ].shelljoin
      sh [ "bin/dbconsole", "--command", "ALTER DATABASE scoutges_development SET \"security.bf_strength\" TO '14'" ].shelljoin

      conf = File.read("postgrest.conf").split("\n")
      new_conf = conf.map do |line|
        next line unless line["jwt-secret"]
        "jwt-secret = \"#{new_secret}\""
      end

      File.write("postgrest.conf", new_conf.join("\n") + "\n")

      sh "overmind restart postgrest worker"
    end
  end
end

namespace :db do
  desc "Deploys the latest changes to the development database"
  task :deploy do
    sh "overmind stop postgrest worker"
    sh "sqitch deploy"
    sh "overmind restart postgrest"
  end

  desc "Reverts and reapplies the most recent change to the development database"
  task :rebase do
    sh "overmind stop postgrest worker"
    sh ["sqitch", "rebase", "HEAD^"].shelljoin
    sh "overmind restart postgrest"
  end

  desc "Destroys the local database and creates a new one"
  task :reset do
    sh "overmind stop postgrest worker"
    sh "dropdb scoutges_development || exit 0"
    sh "createdb scoutges_development"
    sh "sqitch deploy"
    Rake::Task["jwt:secret:rotate"].invoke
    sh [ "dropuser", "--if-exists", "10ème Est-Calade"].shelljoin
    sh [ "bin/dbconsole", "--command", "SELECT api.register('francois@teksol.info', 'monkeymonkey', '10ème Est-Calade', 'Francois', '888-555-1212')" ].shelljoin

    # jwt:secret:rotate will restart postgrest, no need to do it ourselves
  end
end

namespace :spec do
  desc "Runs the PostgreSQL tests"
  task :db do
    sh "dropdb scoutges_test || exit 0"
    sh "createdb scoutges_test"
    sh "sqitch deploy --quiet --target test"

    sh ["psql", "--no-psqlrc", "--quiet", "--dbname", "postgresql://localhost/scoutges_test", "--file", "spec/db/init.sql"].shelljoin

    Dir["spec/db/**/*_spec.sql"].each do |filename|
      sh ["psql", "--no-psqlrc", "--quiet", "--dbname", "postgresql://localhost/scoutges_test", "--file", filename].shelljoin
    end
  end
end

task :spec => "spec:db"
task :default => "spec"
