class MBDBFS < RackDAV::Resource
  include WEBrick::HTTPUtils

  def exist?
    entry
  end

  def collection?
    entry.directory?
  end

  # If this is a collection, return the child resources.
  def children
    (entry.children || []).map do |ch|
      self.class.new(ch.full_path, options)
    end
  end

  def etag
    entry.hash
  end

  def entry
    tree[path]
  end

  def file_path
    # puts "path is #{path}"
    File.join(@options[:backup_path], entry.hash)
  end

  def content_length
    entry.file_size
  end

  def last_modified
    entry.mtime
  end
  
  def creation_date
    entry.ctime
  end

  def get(request, response)
    if entry.directory?
      files = entry.children.map do |child|
        path = child.full_path
        basename = File.basename(path)

        if child.directory?
          type = "directory"
          basename << "/"
          size = "-"
        else
          file = File.join(@options[:backup_path], child.hash)
          type = mime_type(basename, DefaultMimeTypes)        
          size = child.file_size
        end

        Rack::Directory::DIR_FILE % [child.full_path, basename, size, type, child.mtime.httpdate]
      end
      
      files.unshift(Rack::Directory::DIR_FILE % ['../', 'Parent Directory', '', '', ''])

      content = Rack::Directory::DIR_PAGE % [path, path, files.join("\n")]
      response.body = [content]
      response['Content-Length'] = content.size.to_s
    else
      file = Rack::File.new(nil)
      file.path = file_path
      response.body = file
    end
  end

  def content_type
    if entry.directory?
      "text/html"
    else
      mime_type(File.basename(entry.path), DefaultMimeTypes)
    end
  end

  def resource_type
    if collection?
      Nokogiri::XML::fragment('<D:collection xmlns:D="DAV:"/>').children.first
    end
  end

  def post(request, response)
    raise HTTPStatus::Forbidden
  end

  def tree
    @options[:tree]
  end
  
  def to_s
    # "RESOURCE: #{entry}"
    "RESOURCE: #{path}"
  end
end
