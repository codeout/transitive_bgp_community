require 'json'
require 'net/http'
require 'pp'

require_relative 'as_relationship'
require_relative 'bgplay'
require_relative 'irr'

class Transitive
  ASN_DUMP_FILE = 'data/dump.asn'
  DATA_DUMP_FILE = 'data/dump.transitive'
  MAX_ASN = 64512

  def initialize
    load_asn
    load_data
  end

  def find
    while asn = next_asn
      puts "Looking into AS#{asn}"
      next unless prefix = Irr.new(asn).pick_prefix

      Bgplay.get(prefix).each do |path|
        aspath = path[:aspath]
        community = path[:community].reject {|c| c =~ /^#{aspath[0]}:/ }

        next if community.empty?
        community.each do |c|
          analyze(aspath, c.split(/:/)[0].to_i)
        end
      end

      dump
    end
  end

  def next_asn
    @asn ||= 0
    @asn += 1
    return @asn if @asn < MAX_ASN
  end

  def dump
    dump_asn
    dump_data
  end

  def analyze(aspath, asn)
    p aspath, asn

    if i = aspath.index(asn)
      raise if i==0

      while i > 0
        from = AsRelationship.find(aspath[i-1], aspath[i])
        # assume that collector is configured as "customer"
        to = i > 1 ? AsRelationship.find(aspath[i-2], aspath[i-1]) : :customer
        count(aspath[i-1], from, to)
        i-=1
      end
    end
  end

  def count(asn, from, to)
    @data ||= {}
    p key = format(asn, from, to)
    if @data[key]
      @data[key] += 1
    else
      @data[key] = 1
    end
  end

  def stats
    stats = Hash.new {|h, k| h[k] = [] }

    @data.keys.each do |k|
      asn, from, to = k.split(':')
      asn = asn.to_i
      stats["#{from}:#{to}"] << asn if asn < MAX_ASN
    end

    Hash[stats.map {|k, v| [k, v.size] }]
  end


  private

  def format(asn, from, to)
    "#{asn}:#{from}:#{to}"
  end

  def dump_asn
    open(ASN_DUMP_FILE, 'w') {|f| f.write Marshal.dump(@asn) }
  end

  def dump_data
    open(DATA_DUMP_FILE, 'w') {|f| f.write Marshal.dump(@data) }
  end

  def load_asn
    if File.exists?(ASN_DUMP_FILE)
      open(ASN_DUMP_FILE) {|f| @asn = Marshal.load(f) }
    end
  end

  def load_data
    if File.exists?(DATA_DUMP_FILE)
      open(DATA_DUMP_FILE) {|f| @data = Marshal.load(f) }
    end
  end
end


begin
  transitive = Transitive.new
  transitive.find
  pp transitive.stats
rescue
  raise
end
