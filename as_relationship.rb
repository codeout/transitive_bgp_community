class AsRelationship
  DATA_FILE = 'data/20161201.as-rel.txt'

  class << self
    def find(asn1, asn2)
      data[format(asn1, asn2)] || :unknown
    end

    def data
      return @data if @data

      @data = {}
      File.open DATA_FILE do |f|
        f.each_line do |l|
          next unless l =~ /^(\d+)\|(\d+)\|(0|-1)$/

          @data[format($1, $2)] = $3 == '0' ? :peer : :customer
          @data[format($2, $1)] = $3 == '0' ? :peer : :transit
        end
      end

      return @data
    end


    private

    def format(asn1, asn2)
      "#{asn1}:#{asn2}"
    end
  end
end
