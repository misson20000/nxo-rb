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

      def [](tag)
        return @entries.find do |entry|
          entry.tag == tag
        end
      end

      def nchain
        return @nxo[self[DT::HASH].value + 4, 4].unpack("L<")[0]
      end

      def string(i)
        @nxo[self[DT::STRTAB].value + i, 1024].unpack("Z1024")[0]
      end
      
      SYMBOL_SIZE = 0x18
      
      def symbol(i)
        pack = @nxo[self[DT::SYMTAB].value + i * SYMBOL_SIZE, SYMBOL_SIZE]
        name, info, other, shndx, value, size = pack.unpack("L<CCS<Q<Q<")
        return Symbol.new(string(name), info, other, shndx, value, size)
      end
    end
  end
end
