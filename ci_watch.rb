#!/usr/bin/env ruby

require 'syslog/logger'

def daemoned?
  ARGV.any? { |x| x == '-D' }
end

class ErrorMachine
  def initialize(interval = 180)
    @interval = interval
    @prev = []
  end

  def logger
    @logger ||= daemoned? ? Syslog::Logger.new('ci_watch') : Logger.new(STDOUT)
  end


  def fetch_error_machines
    cmd = `docker-machine ls`
    cmd.lines.map do |l|
      if l =~ /^runner/
        name, active, driver, state = l.split

        name if state == 'Error'
      end
    end.compact
  end

  def check
    now = fetch_error_machines
    logger.info "#{now.count} machines are on error state" if now.count > 0

    remains = @prev & now
    remains.each do |machine|
      logger.info "Removed: #{machine}"
      `docker-machine rm -f #{machine}`
    end

    @prev = now
  end

  def loop
    logger.info 'Start watching'
    while true do
      check
      sleep @interval
    end
  end
end

# Daemonize
if daemoned?
  Process.daemon
  open('/var/run/ci_watch.pid', 'w') { |io| io.puts(Process.pid) }
end

# Start loop
ErrorMachine.new(300).loop

