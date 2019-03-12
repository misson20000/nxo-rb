module Nxo
  module Error
    class InvalidMagicError < RuntimeError
      def initialize(actual, expected)
        super("Invalid magic number (got \"#{actual}\", expected \"#{expected}\")")
        @actual = actual
        @expected = expected
      end

      attr_reader :actual, :expected
    end

    class UnknownVersionError < RuntimeError
      def initialize(actual, expected)
        super("Invalid version (got \"#{actual}\", expected \"#{expected}\")")
        @actual = actual
        @expected = expected
      end

      attr_reader :actual, :expected
    end

    class HashCheckError < RuntimeError
      def initialize(segment)
        super("Hash check failed while loading segment \"#{segment}\"")
        @segment = segment
      end

      attr_reader :segment
    end

    class AddressMismatchError < RuntimeError
      def initialize(segment, expected, actual)
        super("Attempted to place segment \"#{segment}\" at 0x#{actual.to_s(16)}, but headers puts it at 0x#{expected.to_s(16)}")
        @segment = segment
        @expected = expected
        @actual = actual
      end

      attr_reader :segment, :expected, :actual
    end

    class UnmappedAddressError < RuntimeError
      def initialize(address)
        super("No segment at 0x#{address.to_s(166)}")
        @address = address
      end

      attr_reader :address
    end
  end
end
