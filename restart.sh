#!/bin/bash
echo 'bringing down the server'
kill -9 `cat tmp/pids/server.pid`

echo 'Updating the source code..'
git pull --rebase

echo 'precompiling assets..'
rake assets:precompile

echo 'Indexing the db'
rake ts:index

rails s -d
echo 'Started hackweek server'
