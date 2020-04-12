require "securerandom"
require "shellwords"
require "uri"

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
    reset_env(:development)

    sh "sqitch deploy --target development"
    Rake::Task["jwt:secret:rotate"].invoke
    # jwt:secret:rotate will restart postgrest, no need to do it ourselves
    sh [ "bin/dbconsole", "--command", "SELECT api.register('francois@teksol.info', 'monkeymonkey', '10ème Est-Calade', 'Francois', '888-555-1212')" ].shelljoin
  end
end

namespace :spec do
  desc "Runs the PostgreSQL tests"
  task :db do
    if ENV.fetch("QUICK", "false") != "true"
      reset_env(:test)
      sh [ "sqitch", "deploy", "--target", "test" ].shelljoin
    end

    sh [ "psql", "--no-psqlrc", "--quiet", "--dbname", dburi(:test), "--file", "spec/db/init.sql" ].shelljoin

    Dir["spec/db/**/*_spec.sql"].each do |filename|
      sh [ "psql", "--no-psqlrc", "--quiet", "--dbname", dburi(:test), "--file", filename ].shelljoin
    end
  end
end

task :spec => "spec:db"
task :default => "spec"

def dburl(env)
  `sqitch target show #{env} | grep URI | cut -d : -f 3-`.strip.sub(/^pg:/, "postgres:")
end

def dburi(env)
  URI.parse(dburl(env))
end

ENVS_TO_SHORT = {
  "development" => :dev,
  :development  => :dev,
  "test"        => :test,
  :test         => :test,
}.freeze

def reset_env(env)
  shortenv = ENVS_TO_SHORT.fetch(env)

  devuri = dburi(env)
  pguri  = devuri.dup
  pguri.user = ENV.fetch("USER")
  pguri.path = "/postgres"

  sh "overmind stop pg#{shortenv}"
  sleep 1
  rm_rf "db/cluster-#{shortenv}"
  sleep 1
  sh "initdb --data-checksums --no-sync --pgdata db/cluster-#{shortenv}"
  sh "echo \"log_statement = 'all'\" >> db/cluster-#{shortenv}/postgresql.conf"
  sh "overmind restart pg#{shortenv}"
  sleep 1

  read      = [ "cat", "db/bootstrap.sql" ].shelljoin
  transform = [ "sed", "s/ENV/#{env}/g" ].shelljoin
  apply     = [ "bin/dbconsole", "--dbname", pguri, "--no-psqlrc", "--quiet", "--file", "-" ].shelljoin
  sh "#{read} | #{transform} | #{apply}"
end
