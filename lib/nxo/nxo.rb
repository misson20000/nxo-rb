require "nxo/error"
require "nxo/dynamic"

module Nxo
  class NxoFile
    MOD_MAGIC = "MOD0"
    
    class Segment
      def initialize(name, address, contents)
        @name = name
        @address = address
        @contents = contents
      end

      attr_reader :name
      attr_reader :address
      attr_reader :contents

      def size
        @contents.bytesize
      end
      
      def contains?(addr)
        return addr >= @address && addr < @address + contents.bytesize
      end
      
      def [](offset, size)
        return @contents[offset, size]
      end
    end

    def initialize(segments)
      @segments = segments

      module_offset = self[4, 4].unpack("L<")[0]
      
      magic, o_dynamic, o_bss_b, o_bss_e, o_eh_frame_hdr_b, o_eh_frame_hdr_e, o_ro_module = self[module_offset, 0x1c].unpack("a4L<L<L<L<L<L<")

      if magic != MOD_MAGIC then
        raise Error::InvalidMagicError.new(module_magic, MOD_MAGIC)
      end

      if module_offset + o_bss_b != bss.address then # sanity check
      #  raise Error::AddressMismatchError.new(:module_bss, module_offset + o_bss_b, bss.address)
      end

      @dynamic = Dynamic::DynamicSection.new(self, module_offset + o_dynamic)
    end

    attr_reader :dynamic
    
    def [](address, size)
      @segments.each do |seg|
        if seg.contains?(address) then
          offset = address - seg.address
          available_size = seg.size - offset
          safe_size = [size, available_size].min
          str = seg[offset, safe_size]
          if safe_size < size then
            return str + self[address + safe_size, size - safe_size]
          else
            return str
          end
        end
      end
      raise Error::UnmappedAddressError.new(address)
    end

    def text
      @segments[0]
    end

    def rodata
      @segments[1]
    end

    def data
      @segments[2]
    end

    def bss
      @segments[3]
    end

    def fs_sdk_versions
      rodata.contents.scan(/sdk_version: ([0-9.]*)/).map do |m| m[0] end
    end

    def name_heuristic
      l = rodata[4, 4].unpack("L<")[0]
      return rodata[8, l]
    end
  end
end
