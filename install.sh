#!/bin/sh

sudo cp ci_watch.rb /opt/ci_watch.rb
sudo chmod 755 /opt/ci_watch.rb
sudo mv ci-watch.service /etc/systemd/system/ci-watch.service

