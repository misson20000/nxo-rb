require "digest"
require "lz4-ruby"

require "nxo/nxo"
require "nxo/error"

module Nxo
  class NsoFile < NxoFile
    NSO_MAGIC = "NSO0"
    NSO_VERSION = 0
    
    def initialize(f, options = {})
      @f = f

      @f.pos = 0
      magic, version, flags = @f.read(0x10).unpack("a4L<x4L<")

      if magic != NSO_MAGIC then
        raise Error::InvalidMagicError.new(magic, NSO_MAGIC)
      end

      if version != NSO_VERSION then
        raise Error::UnknownVersionError.new(version, NSO_VERSION)
      end

      segment_headers = 3.times.map do
        Hash[[:file_offset, :memory_offset, :decompressed_size, :misc].zip(@f.read(0x10).unpack("L<L<L<L<"))]
      end

      module_offset, module_file_size, bss_size = segment_headers.map do |sh| sh[:misc] end

      @build_id = @f.read(0x20)

      @f.read(3 * 0x4).unpack("L<L<L<").each_with_index do |size, i|
        segment_headers[i][:compressed_size] = size
      end

      @f.pos = 0x88
      @extents = Hash[[:api_info, :dynstr, :dynsym].zip(@f.read(0x18).unpack("Q<Q<Q<"))]
      
      @f.read(3 * 0x20).unpack("a32a32a32").each_with_index do |hash, i|
        segment_headers[i][:hash] = hash
      end

      location_counter = 0
      segments = [:text, :rodata, :data].each_with_index.map do |name, i|
        sh = segment_headers[i]
        @f.pos = sh[:file_offset]
        contents = @f.read(sh[:compressed_size])

        if flags[i] == 1 then # is compressed
          contents = LZ4::Raw.decompress(contents, sh[:decompressed_size])[0]
        end

        if flags[i+3] == 1 && !options[:disable_hash_check] then # check hash
          if Digest::SHA256.digest(contents) != sh[:hash] then
            raise Error::HashCheckError.new(name)
          end
        end

        if sh[:memory_offset] < location_counter then
          raise Error::AddressMismatchError.new(name, sh[:memory_offset], location_counter)
        end

        location_counter = sh[:memory_offset] + contents.bytesize
        
        Segment.new(name, sh[:memory_offset], contents)
      end + [Segment.new("bss", location_counter, 0.chr * bss_size)]

      super(segments)
    end

    attr_reader :build_id
    attr_reader :extents
    attr_reader :segments
  end
end
