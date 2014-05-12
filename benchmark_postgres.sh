#!/usr/bin/env sh

if ! vagrant -v | grep -qiE 'Vagrant 1.5'; then
  echo 'You must use vagrant >= 1.5.0 to run this.'
  exit 1
fi

execute_count_statement(){
  vagrant ssh -c 'time psql count_test -c "select count(*) from infringing_urls"' || \
    echo 'Could not execute count'
  sleep 1
}

execute_in_vagrant(){
  vagrant ssh -c "$*" || echo "$* failed"
}

benchmark_count(){
  vagrant up

  execute_in_vagrant 'sudo -u postgres createuser vagrant -dRS' 
  execute_in_vagrant 'psql template1 -c "create database count_test"'
  execute_in_vagrant 'psql count_test -c "create table infringing_urls(id serial primary key, url varchar(1024))"'
  execute_in_vagrant 'cat /vagrant/create_rows.psql | psql count_test'
  execute_in_vagrant 'psql count_test -c "select createRows()"'

  sleep 5

  execute_count_statement
  execute_count_statement
  execute_count_statement
  execute_count_statement
  execute_count_statement

  vagrant destroy
  sleep 60
}

ln -sf Vagrantfile.precise Vagrantfile

echo 'Benchmarking postgres 9.1 from precise'
benchmark_count

ln -sf Vagrantfile.trusty Vagrantfile

echo 'Benchmarking postgres 9.3 from trusty'
benchmark_count
