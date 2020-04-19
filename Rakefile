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
      rotate_secret(:development)
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

    sh "sqitch --quiet deploy --target development"
    Rake::Task["jwt:secret:rotate"].invoke
    # jwt:secret:rotate will restart postgrest, no need to do it ourselves
    sh [ "bin/dbconsole", "--no-psqlrc", "--quiet", "--command", "SELECT api.register('francois@teksol.info', 'monkeymonkey', '10ème Est-Calade', 'Francois', '888-555-1212')" ].shelljoin
  end

  namespace :test do
    desc "Destroys and creates a fresh new version of the test database"
    task :prepare => "spec/tmp/deploy.txt"
  end
end

directory "spec/tmp"
file "spec/tmp/deploy.txt" => [ "Rakefile", "db/sqitch.plan", *Dir["db/deploy/**/*.sql"], "spec/postgrest.conf", "spec/tmp", "db/bootstrap.sql", "spec/db/init.sql" ] do
  sh "overmind stop postgresttest"
  reset_env(:test)
  rotate_secret(:test)
  sh [ "sqitch", "--quiet", "deploy", "--target", "test" ].shelljoin
  sh "touch spec/tmp/deploy.txt"
  sh "overmind restart postgresttest"
end

file "spec/postgrest.conf" => %w( Rakefile postgrest.conf ) do
  sh "overmind stop postgresttest" rescue nil
  sh "sed 's!:3002/scoutges_development!:4002/scoutges_test! ; s/3003/4003/' < postgrest.conf > spec/postgrest.conf"
  sleep 1
  sh "overmind restart postgresttest" rescue nil
end

namespace :spec do
  desc "Removes all generated *.t files"
  task :clean do
    rm_f FileList["spec/revert_deploy_spec.t"] + FileList["spec/**/*_spec.js"].ext("t") + FileList["spec/**/*_spec.sql"].ext("t")
    rm_rf %w(spec/screenshots spec/videos)
  end

  desc "Generates *.t to enable prove to run over them"
  task :prepare => %w( spec:clean spec/revert_deploy_spec.t ) + FileList["spec/**/*_spec.js"].ext(".t") + FileList["spec/**/*_spec.sql"].ext(".t")

  base_spec_deps = %w(
    Rakefile
    spec/postgrest.conf
    db:test:prepare
    deps:js
    spec:prepare
    .proverc
  )
  integration_spec_deps = FileList["spec/**/*_spec.js"].ext(".t") + %w(spec/screenshots spec/videos)
  db_spec_deps          = FileList["spec/**/*_spec.sql"].ext(".t")
  ruby_spec_deps        = FileList["spec/**/*_spec.rb"].ext(".t")

  desc "Runs all spec suites"
  task :all => base_spec_deps + integration_spec_deps + db_spec_deps + ["spec/revert_deploy_spec.t"] + ruby_spec_deps do
    sh "prove --recurse --shuffle --jobs 9 --failures spec"
  end

  desc "Runs the database specs"
  task :db => base_spec_deps + db_spec_deps + ["spec/revert_deploy_spec.t"] do |t|
    sh [ "prove", "--shuffle", "--jobs", "9", "--failures", *t.prerequisite_tasks.map(&:name).grep(/[.]t$/) ].shelljoin
  end

  desc "Runs the integration specs"
  task :integration => base_spec_deps + integration_spec_deps do |t|
    sh [ "prove", "--shuffle", "--jobs", "1", "--failures", *t.prerequisite_tasks.map(&:name).grep(/[.]t$/) ].shelljoin
  end

  desc "Runs the Ruby specs"
  task :ruby => base_spec_deps + ruby_spec_deps do |t|
    sh [ "prove", "--shuffle", "--jobs", "9", "--failures", *t.prerequisite_tasks.map(&:name).grep(/[.]t$/) ].shelljoin
  end
end

directory "spec/screenshots"
directory "spec/videos"

file "spec/revert_deploy_spec.t" do |t|
  File.write(t.name, "w") do |io|
    io.puts "#/bin/bash"
    io.puts "set -eu"
    io.puts "echo '1..1'"
    io.puts "sqitch --quiet rebase --verify --target test"
    io.puts "echo 'ok 1 Revert to root and deploy everything'"
    io.puts "exit 0"
  end
end

file ".proverc" => "Rakefile" do |t|
  File.open(t.name, "w") do |io|
    io.puts "--rules 'seq=spec/integration/**/*.t'"
    io.puts "--rules 'par=**'"
  end
end

rule ".t" => ".js" do |t|
  File.open(t.name, "w") do |io|
    io.puts "#!/bin/sh"
    io.puts "set -eu"
    io.puts "exec yarn run cypress run --reporter mocha-tap-reporter --spec #{t.source}"
  end
end

rule ".t" => ".sql" do |t|
  File.open(t.name, "w") do |io|
    io.puts "#!/bin/sh"
    io.puts "set -eu"
    io.puts "exec bin/dbconsole test --no-psqlrc --quiet --file #{t.source}"
  end
end

namespace :deps do
  desc "Installs any missing dependencies"
  task :js => %w( package.json yarn.lock ) do
    sh "yarn install"
  end
end

task :default => "spec:all"

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

ENVS_TO_BF_STRENGTH = {
  "development" => 14,
  :development  => 14,
  "test"        => 4,
  :test         => 4,
}.freeze

ENVS_TO_CONF_PATH = {
  "development" => "postgrest.conf",
  :development  => "postgrest.conf",
  "test"        => "spec/postgrest.conf",
  :test         => "spec/postgrest.conf",
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
  sh "initdb > /dev/null --data-checksums --no-sync --pgdata db/cluster-#{shortenv}"
  sh "echo \"log_statement = 'all'\" >> db/cluster-#{shortenv}/postgresql.conf"
  sh "overmind restart pg#{shortenv}"
  sleep 1

  read      = [ "cat", "db/bootstrap.sql" ].shelljoin
  transform = [ "sed", "s/%ENV%/#{env}/g" ].shelljoin
  apply     = [ "bin/dbconsole", "--dbname", pguri, "--no-psqlrc", "--quiet", "--file", "-" ].shelljoin
  sh "#{read} | #{transform} | #{apply}"
end

def rotate_secret(env)
  shortenv   = ENVS_TO_SHORT.fetch(env)
  new_secret = SecureRandom.alphanumeric(48)

  sh [ "bin/dbconsole", env.to_s, "--no-psqlrc", "--quiet", "--command", "ALTER DATABASE scoutges_#{env} SET \"jwt.secret\" TO '#{new_secret}'" ].shelljoin
  sh [ "bin/dbconsole", env.to_s, "--no-psqlrc", "--quiet", "--command", "ALTER DATABASE scoutges_#{env} SET \"security.bf_strength\" TO '#{ENVS_TO_BF_STRENGTH.fetch(env)}'" ].shelljoin

  conf = File.read(ENVS_TO_CONF_PATH.fetch(env)).split("\n")
  new_conf = conf.map do |line|
    next line unless line["jwt-secret"]
    "jwt-secret = \"#{new_secret}\""
  end

  File.write(ENVS_TO_CONF_PATH.fetch(env), new_conf.join("\n") + "\n")

  sh "overmind restart postgrest#{shortenv} worker#{shortenv}"
end
