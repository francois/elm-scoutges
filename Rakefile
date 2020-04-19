require "securerandom"
require "shellwords"
require "uri"

begin
  require "byebug"
rescue LoadError => _
  # NOP
end

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
    sh "overmind stop postgrestdev worker"
    reset_env(:development)

    sh "sqitch deploy --target development"
    Rake::Task["jwt:secret:rotate"].invoke
    # jwt:secret:rotate will restart postgrest, no need to do it ourselves
    sh [ "bin/dbconsole", "--command", "SELECT api.register('francois@teksol.info', 'monkeymonkey', '10ème Est-Calade', 'Francois', '888-555-1212')" ].shelljoin
  end

  namespace :test do
    desc "Destroys and creates a fresh new version of the test database"
    task :prepare => "spec/tmp/deploy.txt"
  end
end

directory "spec/tmp"
file "spec/tmp/deploy.txt" => [ "Rakefile", "db/sqitch.plan", *Dir["db/deploy/**/*.sql"], "spec/tmp", "spec/bootstrap.sql", "spec/db/init.sql" ] do
  sh "overmind stop postgresttest"
  reset_env(:test)
  sh [ "sqitch", "--quiet", "deploy", "--target", "test" ].shelljoin
  sh "touch spec/tmp/deploy.txt"
  sh "overmind restart postgresttest"
end

file "spec/tmp/integration-specs-list.txt" => [ "Rakefile", "spec/tmp", *Dir["spec/integration/**/*_spec.js"] ] do |t|
  File.open("spec/tmp/integration-specs-list.txt", "w") do |io|
    io.puts(t.all_prerequisite_tasks.map(&:name))
  end
end

file "spec/tmp/db-specs-list.txt" => [ "Rakefile", "spec/tmp", *Dir["spec/db/**/*_spec.sql"] ] do |t|
  File.open("spec/tmp/db-specs-list.txt", "w") do |io|
    io.puts(t.all_prerequisite_tasks.map(&:name))
  end
end

file "spec/postgrest.conf" => %w( Rakefile postgrest.conf ) do
  sh "overmind stop postgresttest"
  sh "sed 's!/scoutges_development!:5433/scoutges_test! ; s/3001/5002/' < postgrest.conf > spec/postgrest.conf"
  sleep 1
  sh "overmind restart postgresttest"
end

namespace :spec do
  desc "Runs the PostgreSQL tests"
  task :db => %w( Rakefile db:test:prepare spec/tmp/db-specs-list.txt ) do
    sh [ "psql", "--no-psqlrc", "--quiet", "--dbname", dburi(:test), "--file", "spec/db/init.sql" ].shelljoin
    prove = [
      "prove",
      # "--timer",
      # "--verbose",
      "--shuffle",
      "--ext", "sql",
      "--jobs", "9",
      "--exec", "psql --no-psqlrc --quiet --dbname #{dburi(:test)} --file ",
      "-"
    ].shelljoin
    sh "#{prove} < spec/tmp/db-specs-list.txt"
  end

  desc "Runs the integration test suite"
  task :integration => %w( Rakefile db:test:prepare spec/postgrest.conf spec/tmp/integration-specs-list.txt ) do
    prove = [
      "prove",
      # "--timer",
      # "--verbose",
      "--shuffle",
      "--ext", "sql",
      "--jobs", "1",
      "--exec", "yarn run cypress run --reporter mocha-tap-reporter --spec ",
      *Dir["spec/integration/**/*_spec.js"]
    ].shelljoin
    sh prove
  end
end

task :spec => "spec:db"
task :spec => "spec:integration"
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

  read      = [ "cat", "spec/bootstrap.sql" ].shelljoin
  transform = [ "sed", "s/%ENV%/#{env}/g" ].shelljoin
  apply     = [ "bin/dbconsole", "--dbname", pguri, "--no-psqlrc", "--quiet", "--file", "-" ].shelljoin
  sh "#{read} | #{transform} | #{apply}"
end
