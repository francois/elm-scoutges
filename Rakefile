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
    sh [ "bin/dbconsole", "--command", "INSERT INTO groups(name, pgrole) VALUES ('10eme', 'authenticated'); INSERT INTO users(email, password, name, phone, group_name) VALUES ('francois@teksol.info', 'monkeymonkey', 'Francois', '888-555-1212', '10eme')" ].shelljoin
    Rake::Task["jwt:secret:rotate"].invoke

    # jwt:secret:rotate will restart postgrest, no need to do it ourselves
  end
end

namespace :spec do
  desc "Runs the PostgreSQL tests"
  task :db do
    dev_status = Kernel.open("|sqitch status --target development").read.split("\n")
    dev_change = dev_status.grep(/Change:/)

    test_status = Kernel.open("|sqitch status --target test").read.split("\n")
    test_change = test_status.grep(/Change:/)

    if dev_change != test_change
      sh "dropdb scoutges_test || exit 0"
      sh "createdb scoutges_test"
      sh "sqitch deploy --quiet --target test"
    end

    sh ["psql", "--no-psqlrc", "--quiet", "--dbname", "postgresql://localhost/scoutges_test", "--file", "spec/db/_setup.sql"].shelljoin

    Dir["spec/db/**/*_spec.sql"].each do |filename|
      sh ["psql", "--no-psqlrc", "--quiet", "--dbname", "postgresql://localhost/scoutges_test", "--file", filename].shelljoin
    end
  end
end

task :spec => "spec:db"
task :default => "spec"
