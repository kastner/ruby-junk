require 'syslog'
 
def log(message)
  # $0 is the current script name
  Syslog.open("bob", Syslog::LOG_PID | Syslog::LOG_CONS, facility = Syslog::LOG_LOCAL0) { |s| s.notice message }
end

log "HI!!!"