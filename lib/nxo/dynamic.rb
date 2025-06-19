module Nxo
  module Dynamic
    module DT
      NULL = 0
      NEEDED = 1
      PLTRELSZ = 2
      PLTGOT = 3
      HASH = 4
      STRTAB = 5
      SYMTAB = 6
      RELA = 7
      RELASZ = 8
      RELAENT = 9
      STRSZ = 10
      SYMENT = 11
      # 12-15
      SYMBOLIC = 16
      REL = 17
      RELSZ = 18
      RELENT = 19
      PLTREL = 20
      # 21-22
      JMPREL = 23
      # 24
      INIT_ARRAY = 25
      FINI_ARRAY = 26
      INIT_ARRAYSZ = 27
      FINI_ARRAYSZ = 28
      FLAGS = 30
      GNU_HASH = 0x6ffffef5
      RELACOUNT = 0x6ffffff9
    end

    class Entry
      def initialize(nxo, tag, value)
        @nxo = nxo
        @tag = tag
        @value = value
      end

      attr_reader :nxo, :tag, :value
    end

    
    class Symbol
      def initialize(name, info, other, shndx, value, size)
        @name = name
        @info = info
        @other = other
        @shndx = shndx
        @value = value
        @size = size
      end

      attr_reader :name, :info, :other, :shndx, :value, :size
    end
    
    class DynamicSection
      def initialize(nxo, offset)
        @nxo = nxo
        @offset = offset
        @entries = []
        
        lc = offset
        while((entry = Entry.new(self, *@nxo[lc, 0x10].unpack("Q<Q<"))).tag != DT::NULL) do
          @entries.push(entry)
          lc+= 0x10
        end
      end

      attr_reader :entries

      def contains?(tag)
        return @entries.any? do |entry|
          entry.tag == tag
        end
      end
      
      def [](tag)
        return @entries.find do |entry|
          entry.tag == tag
        end
      end

      def nchain
        return @nxo[self[DT::HASH].value + 4, 4].unpack("L<")[0]
      end

      def gnu_hash_num_symbols
        # https://flapenguin.me/elf-dt-gnu-hash
        nbuckets, symoffset, bloom_size, bloom_shift = @nxo[self[DT::GNU_HASH].value, 16].unpack("L<L<L<L<")
        buckets = @nxo[self[DT::GNU_HASH].value + 16 + 8*bloom_size, 4*nbuckets].unpack("L<*")
        chain_offset = self[DT::GNU_HASH].value + 16 + 8*bloom_size + 4*nbuckets

        # Find the bucket that starts at the highest index
        index = buckets.max

        if index < symoffset then
          return symoffset
        end
        
        # Walk the chain until it ends
        while (@nxo[chain_offset + (index - symoffset)*4, 4].unpack("L<")[0] & 1) == 0 do
          index+= 1
        end

        index
      end

      def num_symbols
        if self.contains?(DT::HASH) then
          nchain
        else
          gnu_hash_num_symbols
        end
      end

      def string(i)
        @nxo[self[DT::STRTAB].value + i, 8192].unpack("Z8192")[0]
      end
      
      SYMBOL_SIZE = 0x18
      
      def symbol(i)
        pack = @nxo[self[DT::SYMTAB].value + i * SYMBOL_SIZE, SYMBOL_SIZE]
        name, info, other, shndx, value, size = pack.unpack("L<CCS<Q<Q<")
        return Symbol.new(string(name), info, other, shndx, value, size)
      end

      def symbols
        self.num_symbols.times.map do |i| self.symbol(i) end
      end
    end
  end
end
