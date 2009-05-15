def run_osa(script)
  result = ""
  IO.popen "osascript", "r+" do |io|
    io.write script
    io.close_write
    result = io.read.chomp
  end
  return result
end

def run_osa_itunes(script)
  run_osa <<-OSA
    tell application "iTunes"
      #{script}
    end tell
  OSA
end

def run_osa_current(script)
  run_osa_itunes <<-OSA
    tell current playlist
      #{script}
    end tell
  OSA
end

def current_tracks
  tracks = run_osa_current("tracks")
  tracks.split(",").collect {|t| t.gsub(/^.*\s(\d+)$/, '\1') }
end

def current_track_id
  run_osa_itunes "get id of current track"
end

def track_name_in_current(track_id)
  run_osa_current "get name of track id #{track_id}"
end

track = current_track_id
tracks = current_tracks

if tracks.include?(track)
  tracks[tracks.index(track),10].each do |track_id|
    puts track_name_in_current(track_id)
  end
end