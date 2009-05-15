require 'progress'

t = Time.now.to_i
Progress.total = Proc.new do
  100
end

Progress.current = Proc.new do
  Time.now.to_i - t
end

while(1)
  Progress.output
  sleep(1)
end