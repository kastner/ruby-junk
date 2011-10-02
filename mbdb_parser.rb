# iOS 5 MBDB Parser
# =================
#
# by Erik Kastner <kastner@gmail.com>
#
# MBDB format explanation from here: http://code.google.com/p/iphonebackupbrowser/wiki/MbdbMbdxFormat
#
# The entry / file system hash file mapping was reverse engineered.
#
#
# Usage
# -----
#
# ruby mbdb_parser.rb "<path_to_your_Manifest.mbdb_file>"
#
#
# Tests
# -----
#
# * run them: `ruby mbdb_parser.rb`

require 'openssl'

module SillyHasher
  extend self

  def hash(strings)
    OpenSSL::Digest::SHA1.hexdigest(join_strings(strings))
  end

  def join_strings(strings)
    strings = [strings] unless strings.respond_to?(:each)
    strings.reject {|a| a == ''}.join("-")
  end
end

class MBDBEntry
  attr_accessor :permissions, :path, :domain, :hash, :file_size, :children, :full_path
  attr_accessor :link_target, :atime, :mtime, :ctime, :flag, :dummy

  def initialize(dummy = false)
    @atime = @mtime = @ctime = Time.now
    @dummy = dummy
  end

  def directory?
    @file_size == 0 && (@permissions & 0o40000 > 0)
  end

  def copy(other)
    self.instance_variables.each do |ivar|
      next if ivar == :children
      self.send("#{ivar}=", other.send(ivar))
    end

    @dummy = false
  end

  def to_s
    self.instance_variables.map do |ivar| 
      value = self.instance_variable_get(ivar)
      value = "count: #{value.size}" if value.kind_of?(Array)
      "#{ivar} => #{value}"
    end.join(", ")
  end
end

class MBDBParser
  def self.parse(mbdb_path, &block)
    p = new(mbdb_path)

    until p.ended?
      p.extract_record(&block)
    end
  end

  def extract_record
    entry = MBDBEntry.new

    entry.domain = get_string
    entry.path = get_string
    entry.link_target = get_string

    skip_string # DataHash
    skip_string # "Unknown"

    entry.permissions = get_uint16

    skip(4 * 4) # skip 4, 32 bit entries

    entry.ctime = Time.at(get_uint32)
    entry.mtime = Time.at(get_uint32)
    entry.atime = Time.at(get_uint32)

    entry.file_size = get_uint64

    entry.flag = get_uint8

    if entry.directory?
      entry.full_path = File.join(File::SEPARATOR, entry.domain, entry.path, "")
    else
      entry.full_path = File.join(File::SEPARATOR, entry.domain, entry.path)
    end

    attribs = get_uint8 # attribute count
    attribs.times { skip_string; skip_string } if attribs

    entry.hash = SillyHasher.hash([entry.domain, entry.path])

    yield(entry) if block_given?
    entry
  end

  def initialize(mbdb_path, file_class=File, no_skip=false)
    @mbdb_file = mbdb_path
    @f = file_class.open(mbdb_path)

    # skip name / version header
    skip(6) unless no_skip
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


#f = File.open("/Users/kastner/Library/Application Support/MobileSync/Backup/2da97f115b665c27d108e4086d61ce98064b2c77/Manifest.mbdb")
#
#f.seek()

if $0 == __FILE__
  tree = {}
  if ARGV[0]
    # make the root entry
    tree[File::SEPARATOR] = MBDBEntry.new

    MBDBParser.parse(ARGV[0]) do |entry|
      puts "#{entry.hash} : #{entry.domain} / #{entry.path}" unless entry.directory?

      path = entry.full_path
      tree[path] ||= entry

      while path != File::SEPARATOR
        up_path = File.dirname(path)

        tree[up_path] ||= MBDBEntry.new
        tree[up_path].children ||= []
        tree[up_path].children << tree[path] unless tree[up_path].children.include?(tree[path])

        path = up_path
      end
    end

    # puts tree.inspect
    #puts "children count = " + tree["/"].children.size.inspect
  else
    require 'test/unit'

    class FakeFile
      def self.fake_from_hex(hex_array); @@fake_data = hex_array.map {|h| h.to_i(16)}; end
      def self.fake_data=(fake_data); @@fake_data = fake_data; end
      def self.open(path); new; end
      def initialize; @pointer = 0; end
      def skip(bytes); @pointer += bytes; end
      def eof?; @pointer >= @@fake_data.length; end
      def pos; @pointer; end
      def rewind; @pointer = 0; end

      def read(bytes, string = nil)
        # raise @@fake_data.inspect
        data = @@fake_data[@pointer, bytes].map {|c| c.respond_to?(:each) ? (c[0] || 0).ord : c}
        skip(bytes)

        string.replace data.map {|a| a.chr}.join if string
        data.pack("C*")
      end
    end

    class TestMBDBParser < Test::Unit::TestCase
      def setup
        FakeFile.fake_data = [
          'm', 'b', 'd', 'b', 5, 0,                 # header
          0, 5, 'h', 'e', 'l', 'l', 'o', 0, 1, 'u', # path and domain
          255, 255, 255, 255, 255, 255,             # skip
          0x01, 0xFD,                               # permissions (octal)
          [""] * 2 * 4,                             # skip
          0x00, 0x00, 0x01, 0xF5,                   # user
          0x00, 0x00, 0x01, 0xF5,                   # group
          0x4E, 0x73, 0xEB, 0xEB,                   # one of a/m/c time
          0x4E, 0x77, 0x9F, 0x21,                   # one of a/m/c time
          0x4E, 0x73, 0xEB, 0xEB,                   # one of a/m/c time
          [0] * 5, 1, 24, 24,                       # file size (71704)
          0, 0, 0, 0                                # attributes
        ].flatten

        @mbdb = MBDBParser.new("blah", FakeFile)

        mbdb2 = MBDBParser.new("blah", FakeFile)
        @record = mbdb2.extract_record
      end

      def test_string
        assert_equal "hello", @mbdb.get_string
      end

      def test_timestamp
        assert_equal Time.at(1316219883), @record.atime
      end

      def test_record
        assert_equal 71704, @record.file_size
      end
    end

    class TestParserTwo < Test::Unit::TestCase
      def test_directory
        FakeFile.fake_from_hex(%w|00 15 41 70 70 44 6F 6D 61 69 6E 2D 63 6F
          6D 2E 70 61 6E 64 6F 72 61 00 0E 4C 69 62 72 61 72 79 2F 57 65 62
          4B 69 74 FF FF FF FF FF FF 41 ED 00 00 00 00 00 00 0E 4A 00 00 01
          F5 00 00 01 F5 4C 32 15 89 4D ED A1 8D 4C 32 15 89 00 00 00 00 00
          00 00 00 00|)

        record = MBDBParser.new("blah", FakeFile, true).extract_record

        assert record.directory?
      end

      def test_file
        FakeFile.fake_from_hex(%w|00 15 41 70 70 44 6F 6D 61 69 6E 2D 63 6F
          6D 2E 70 61 6E 64 6F 72 61 00 30 4C 69 62 72 61 72 79 2F 50 72 65
          66 65 72 65 6E 63 65 73 2F 63 6F 6D 2E 61 70 70 6C 65 2E 50 65 6F
          70 6C 65 50 69 63 6B 65 72 2E 70 6C 69 73 74 00 44 2F 70 72 69 76
          61 74 65 2F 76 61 72 2F 6D 6F 62 69 6C 65 2F 4C 69 62 72 61 72 79
          2F 50 72 65 66 65 72 65 6E 63 65 73 2F 63 6F 6D 2E 61 70 70 6C 65
          2E 50 65 6F 70 6C 65 50 69 63 6B 65 72 2E 70 6C 69 73 74 FF FF FF
          FF A1 ED 00 00 00 00 00 05 00 75 00 00 01 F5 00 00 01 F5 4E 5C 3E
          88 4E 5C 3E 88 4E 5C 3E 88 00 00 00 00 00 00 00 00 00 00|)

        record = MBDBParser.new("blah", FakeFile, true).extract_record

        assert ! record.directory?
      end
    end

    class TestSillyHasher < Test::Unit::TestCase
      def test_hash
        strings = %w|AppDomain-com.panic.Prompt Library/Preferences/com.panic.Prompt.plist|
        assert_equal "c6b58aeb592c4dffc5003ce3cac93a057bd2625e", SillyHasher::hash(strings)
      end
    end
  end
end
