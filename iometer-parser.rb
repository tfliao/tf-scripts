#! /usr/bin/ruby
require 'optparse'
require 'ostruct'

def parse()
	# init
	options = OpenStruct.new
	options.order = []
	options.verbose = false
	options.result = 'raw'
	options.field = 'auto'

	parser = OptionParser.new do |opts|
		opts.banner = "Usage: #{$0} [options] files ..."
		opts.separator "     parser to parse iometer result csv files to a copy friendly format"
		opts.separator ""

		opts.on_tail("-h", "--help", "show help message") do
			puts opts
			exit
		end
		opts.on("-o=O1, ...", "--order=O1, ...", Array, "order of result") do |v|
			options.order.concat(v)
		end
		opts.on("-v", "--verbose", "force show some message") do |v| options.verbose = v end
		opts.on("-r=R", "--result=R", "available:raw, avg, ...") do |v| options.result = v end

		opts.on("-f=F", "--field=F", "available: iops, MB/s, ...") do |v| options.field = v end

	end
	options.files = parser.parse!
	options
end

def show(key, value)
	result = $options.result

	if value == NIL
		puts "Key: " + key + ", Value is NIL" if $options.verbose
		return
	end

	case result
	when 'avg'
		avg = value.inject(0.0) { |s, v| s + v.to_f } / value.size
		puts "%.4f" % avg + "\t" + key
	else # other including raw
		value.each_with_index do |v, n|
			puts v + (n==0 ? "\t[" + key + "]" : "")
		end
	end
end

def parsefile(fp, name)
	puts "File: #{name}" if name != NIL
	data = Hash.new

	fp.each do |line|
		tokens = line.split(',')
		if tokens[0] == 'ALL'
			key = tokens[2]
			case $options.field.downcase
			when 'iops'
				value = token [6] # IOPS
			when 'mb/s'
				value = tokens[9] # MB/s
			else
				value = tokens[6] # IOPS
				if key.index('throughput') != NIL || key.index('64K') != NIL || key.index('32K') != NIL
					value = tokens[9] # MB/s
				end
			end
			data[key] = Array.new if !data.has_key?(key)
			data[key] << value
		end
	end

	if !$options.order.empty?
		$options.order.each do |o|
			show(o, data[o])
		end
	else
		data.each do |key, value|
			show(key, value)
		end
	end
	puts ""
end

$options = parse()

if $options.files.empty?
	parsefile(STDIN, NIL)
else
	$options.files.each do |f|
		fp = File.open(f)
		parsefile(fp, f)
		fp.close()
	end
end
