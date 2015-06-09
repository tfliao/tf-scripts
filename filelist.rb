#! /usr/bin/ruby
require 'optparse'
require 'ostruct'

def parse()
	# init
	options = OpenStruct.new
	options.single = false
	options.vim = false
	options.binary = false
	options.key = ""
	options.basedirs = ["."]
	options.nocase = false
	options.excludes = []

	parser = OptionParser.new do |opts|
		# banner for help message
		opts.banner =  "Usage: #{$0} [options] key [basedir]"
		opts.separator "       collect files that contain key"
		opts.separator ""

		# common options
		opts.on_tail("-h", "--help", "show this help message") do
			puts opts
			exit
		end
		opts.on_tail("--version", "show version") do
			basename = File.basename(__FILE__, ".rb")
			puts "#{basename} 1.2.0"
			exit
		end

		# specific options
		opts.on("-1", "--single", "show each file in single line") do |v|
			options.single = v
		end
		opts.on("-v", "--vim", "open all files by vim with tabs") do |v|
			options.vim = v
		end
		opts.on("-b", "--[no-]binary", "show binary files") do |v|
			options.binary = v
		end
		opts.on("-i", "--ignore-case", "Ignore case distinctions") do |v|
			options.nocase = v
		end
		opts.on("-e=pattern,...", "--exclude=pattern,...", Array, "exclude files with particular pattern") do |e|
			options.excludes.concat(e)
		end

	end
	args = parser.parse!
	if args.empty? then
		puts "No Key given!"
		puts parser.help()
		exit 1
	end
	options.key = args.shift
	options.basedirs = args if !args.empty?

	options
end

o = parse()

nocase = ""
nocase = "-i" if o.nocase

files = `grep #{nocase} -nr "#{o.key}" #{o.basedirs.join(' ')} | cut -d: -f1 | uniq`.split("\n")

# remove binary files
if !o.binary then
	files.delete_if { |f| f.downcase.start_with?("binary file ") }
else
	files = files.map do |f|
		if f.downcase.start_with?("binary file ") then
			f = f.split(' ').at(2)
		end
		f
	end
end

o.excludes.each do |e|
	files.delete_if { |f| /#{e}/.match(f) != NIL }
end

if o.vim then
	exec "vim -p #{files.join(' ')}"
end

if o.single then
	puts files
else
	puts files.join(' ')
end


