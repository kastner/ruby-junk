# http://code.google.com/p/iphonebackupbrowser/wiki/MbdbMbdxFormat
require 'openssl'

module SillyHasher
  extend self
  
  def hash(strings)
    OpenSSL::Digest::SHA1.hexdigest(join_strings(strings))
  end
  
  def join_strings(strings)
    strings = [strings] unless strings.respond.to?(:each)
    strings.reject {|a| a == ''}.join("-")
  end
end

class MBDBEntry
  attr_accessor :permissions, :path, :domain, :hash, :file_size
  
  def to_s
     self.instance_variables.map {|ivar| ivar.to_s + " => " + self.instance_variable_get(ivar)}.join(" ")
  end
end

class MBDBParser
  def self.parse(mbdb_path)
    p = new(mbdb_path)

    until p.ended?
      p.extract_record(&block)
    end
  end
  
  def extract_record
    entry = MBDBEntry.new
    
    entry.domain = get_string
    entry.path = get_string

    strings = []

    strings << entry.domain
    strings << entry.path
    strings << get_string # LinkTarget
    strings << get_string # DataHash
    strings << get_string # "Unknown"

    entry.permissions = get_uint16.to_s(8)

    skip(7 * 4)

    entry.file_size = get_uint64

    skip(1)

    attribs = get_uint8
    attribs.times { skip_string } if attribs

    yield(entry) if block_given?
    entry
  end

  def initialize(mbdb_path, file_class=File)
    @mbdb_file = mbdb_path
    @f = file_class.open(mbdb_path)

    # skip name / version header
    skip(6)
  end

  def ended?
    @f.eof?
  end

  def skip(bytes)
    @f.read(bytes)
  end

  def get_string
    len = get_uint16
    return "" if len == 0xFFFF
    # make a new string so it's UTF-8
    s = ""
    read(len, s).inspect
    return s
  end

  def skip_string
    len = get_uint16

    return if len == 0xFFFF
    skip(len)
  end

  def get_uint8;  get_uint(1, :C); end
  def get_uint16; get_uint(2, :S); end
  def get_uint32; get_uint(4, :L); end
  def get_uint64; get_uint(8, :Q); end

  def get_uint(bytes, packing)
    d = read(bytes)
    return d.reverse.unpack(packing.to_s)[0]
    # read(bytes).unpack("n")[0]
  end

  def read(bytes, string=nil)
    @f.read(bytes, string)
  end
end


# f = File.open("/Users/kastner/Library/Application Support/MobileSync/Backup/2da97f115b665c27d108e4086d61ce98064b2c77/Manifest.mbdb")
# 
# f.seek()

if $0 == __FILE__
  require 'test/unit'

  class FakeFile
    def self.fake_data=(fake_data)
      @@fake_data = fake_data
    end

    def self.open(path)
      new
    end
    
    def initialize
      @pointer = 0
    end

    def skip(bytes)
      @pointer += bytes
    end

    def eof?
      @pointer >= @@fake_data.length
    end

    def pos
      @pointer
    end

    def read(bytes, string = nil)
      # if (string)
      #   # DAMN COW!
      #   str = string.dup
      #   str = @@fake_data[@pointer, bytes].join
      #   string.replace str
      #   skip(bytes)
      #   return bytes
      # else
      #   ret = []
      #   bytes.times do |i|
      #     ret << (@@fake_data[@pointer] || 0)
      #     skip(1)
      #   end
      #   raise ret.inspect
      #   return ret.pack("C*")
      # end
      
      data = @@fake_data[@pointer, bytes].map {|c| c.respond_to?(:each) ? (c[0] || 0).ord : c}
      skip(bytes)

      string.replace data.map {|a| a.chr}.join if string
      data.pack("C*")
    end

    def rewind
      @pointer = 0
    end
  end

  class TestMBDBParser < Test::Unit::TestCase
    def setup
      FakeFile.fake_data = [
        'm', 'b', 'd', 'b', 5, 0,                 # header
        0, 5, 'h', 'e', 'l', 'l', 'o', 0, 1, 'u', # path and domain
        255, 255, 255, 255, 255, 255,             # skip
        0x01, 0xFD,                               # permissions (octal)
        [""] * 7 * 4,                             # skip
        [0] * 5, 1, 24, 24,                       # file size (71704)
        0, 0, 0, 0                                # attributes
      ].flatten
      
      @mbdb = MBDBParser.new("blah", FakeFile)
    end

    def test_string
      assert_equal "hello", @mbdb.get_string
    end
    
    def test_record
      record = @mbdb.extract_record
      assert_equal 71704, record.file_size
    end
  end
end