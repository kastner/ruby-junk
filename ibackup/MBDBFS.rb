class MBDBFS < RackDAV::Resource
  include WEBrick::HTTPUtils

  def exist?
    entry
  end

  def collection?
    entry.children
  end

  def etag
    entry.hash
  end

  def entry
    tree[path]
  end

  def file_path
    # puts "path: #{path}, t: #{entry.inspect}"
    File.join(@options[:backup_path], entry.hash)
  end

  def content_length
    entry.file_size
  end

  def last_modified
    entry.mtime
  end

  def get(request, response)
    files = entry.children.map do |child|
      path = child.full_path
      basename = File.basename(path)

      if child.directory?
        # puts "DIRECTORY HERE #{child}"
        type = "directory"
        basename << "/"
        size = "-"
      else
        # puts "IN HERE #{child}"
        file = File.join(@options[:backup_path], child.hash)
        # puts "file: #{file}"
        type = mime_type(basename, DefaultMimeTypes)
        
        # hack
        # type = `file --mime-type -b "#{file}"`.chomp
        size = child.file_size
      end

      Rack::Directory::DIR_FILE % [child.full_path, basename, size, type, child.mtime]
    end

    content = Rack::Directory::DIR_PAGE % [path, path, files.join("\n")]
    response.body = [content]
    response['Content-Length'] = content.size.to_s

    # if entry.children
    #   content = ""
    #   Rack::Directory.new(root).call(request.env)[2].each { |line| content << line }
    #   response.body = [content]
    #   response['Content-Length'] = content.size.to_s
    # else
    #   file = Rack::File.new(nil)
    #   file.path = file_path
    #   response.body = file
    # end
  end

  def content_type
    puts "#{entry}"
    if entry.children
      "text/html"
    else
      mime_type(file_path, DefaultMimeTypes)
    end
  end

  def tree
    @options[:tree]
  end
end
