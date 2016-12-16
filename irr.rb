class Irr
  IRRD = 'rr.ntt.net'

  def initialize(asn)
    @asn = asn
  end

  def pick_prefix
    prefixes = raw.split
    if prefixes.shift =~ /^A\d+$/
      return prefixes[0..-2].first
    end
  end


  private

  def raw
    @raw ||= `whois -h #{IRRD} '!gas#{@asn}'`
  end
end
