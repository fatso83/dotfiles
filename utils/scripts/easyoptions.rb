#!/usr/bin/env ruby
# Encoding: UTF-8

##
##     EasyOptions 2015.2.28
##     Copyright (c) 2013, 2014 Renato Silva
##     BSD licensed
##
## This script is supposed to parse command line arguments in a way that,
## even though its implementation is not trivial, it should be easy and
## smooth to use. For using this script, simply document your target script
## using double-hash comments, like this:
##
##     ## Program Name v1.0
##     ## Copyright (C) Someone
##     ##
##     ## This program does something. Usage:
##     ##     @#script.name [option]
##     ##
##     ## Options:
##     ##     -h, --help              All client scripts have this by default,
##     ##                             it shows this double-hash documentation.
##     ##
##     ##     -o, --option            This option will get stored as true value
##     ##                             under EasyOptions.options[:option]. Long
##     ##                             version is mandatory, and can be specified
##     ###                            before or after short version.
##     ##
##     ##         --some-boolean      This will get stored as true value under
##     ##                             EasyOptions.options[:some_boolean].
##     ##
##     ##         --some-value=VALUE  This is going to store the VALUE specified
##     ##                             under EasyOptions.options[:some_value].
##     ##                             The equal sign is optional and can be
##     ##                             replaced with blank space when running the
##     ##                             target script. If VALUE is composed of
##     ##                             digits, it will be converted into an
##     ##                             integer, otherwise it will get stored as a
##     ##                             string. Short version is not available in
##     ##                             this format.
##
## The above comments work both as source code documentation and as help
## text, as well as define the options supported by your script. There is no
## duplication of the options specification. The string @#script.name will be
## replaced with the actual script name.
##
## After writing your documentation, you simply require this script. Then all
## command line options will get parsed into the EasyOptions.options hash, as
## described above. You can then check their values for reacting to them. All
## regular arguments will get stored into the EasyOptions.arguments array.
##
## In fact, this script is an example of itself. You are seeing this help
## message either because you are reading the source code, or you have called
## the script in command line with the --help option.
##
##     Note: the options and arguments are also available as global variables in
##     current version, but their use is discouraged and is supposed to be
##     eventually removed.
##
## This script can be used from Bash scripts as well. If the $from environment
## variable is set, that will be assumed as the source Bash script from which to
## parse the documentation and the provided options. Then, instead of parsing
## the options into Ruby variables, evaluable assignment statements will be
## generated for the corresponding Bash environment variables. For example:
##
##     eval "$(from="$0" @script.name "$@" || echo exit 1)"
##
## If the script containing this command is documented as in the example above,
## and it is executed from command line with the -o and --some-value=10 options,
## and one regular argument abc, then the evaluable output would look like this:
##
##     option="yes"
##     some_value="10"
##     unset arguments
##     arguments+=("abc")
##     arguments
##

module EasyOptions
    class Option
        def initialize(long_version, short_version, boolean = true)
            fail ArgumentError.new('Long version is mandatory') if !long_version || long_version.length < 2
            @short = short_version.to_sym if short_version
            @long = long_version.to_s.gsub('-', '_').to_sym
            @boolean = boolean
        end

        def to_s
            "--#{long_dashed}"
        end

        def in?(string)
            string =~ /^--#{long_dashed}$/ || (@short && string =~ /^-#{@short}$/)
        end

        def in_with_value?(string)
            string =~ /^--#{long_dashed}=.*$/
        end

        def long_dashed
            @long.to_s.gsub('_', '-')
        end
        attr_accessor :short
        attr_accessor :long
        attr_accessor :boolean
    end

    class Parser
        def initialize
            @known_options = [Option.new(:help, :h)]
            @documentation = parse_doc
            @arguments = []
            @options = {}
        end

        def parse_doc
            begin
                doc = File.readlines($PROGRAM_NAME)
            rescue Errno::ENOENT
                exit false
            end
            doc = doc.find_all do |line|
                line =~ /^##[^#]*/
            end
            doc.map do |line|
                line.strip!
                line.sub!(/^## ?/, '')
                line.gsub!(/@script.name/, File.basename($PROGRAM_NAME))
                line.gsub(/@#/, '@')
            end
        end

        def parse
            # Parse known options from documentation
            @documentation.map do |line|
                line = line.strip
                case line
                when /^-h, --help.*/ then next
                when /^--help, -h.*/ then next
                when /^-.*, --.*/    then line = line.split(/(^-|,\s--|\s)/);  @known_options << Option.new(line[4], line[2])
                when /^--.*, -.*/    then line = line.split(/(--|,\s-|\s)/);   @known_options << Option.new(line[2], line[4])
                when /^--.*=.*/      then line = line.split(/(--|=|\s)/);      @known_options << Option.new(line[2], nil, false)
                when /^--.* .*/      then line = line.split(/(--|\s)/);        @known_options << Option.new(line[2], nil)
                end
            end

            # Format arguments input
            raw_arguments = ARGV.map do |argument|
                if argument =~ /^-[^-].*$/i
                    argument.split('')[1..-1].map { |char| "-#{char}" }
                else
                    argument
                end
            end.flatten

            # Parse the provided options
            raw_arguments.each_with_index do |argument, index|
                unknown_option = true
                @known_options.each do |known_option|

                    # Boolean option
                    if known_option.in?(argument) && known_option.boolean
                        @options[known_option.long] = true
                        unknown_option = false
                        break

                    # Option with value in next parameter
                    elsif known_option.in?(argument) && !known_option.boolean
                        value = raw_arguments[index + 1]
                        Parser.finish("you must specify a value for #{known_option}") if !value || value.start_with?('-')
                        value = value.to_i if value =~ /^[0-9]+$/
                        @options[known_option.long] = value
                        unknown_option = false
                        break

                    # Option with value after equal sign
                    elsif known_option.in_with_value?(argument) && !known_option.boolean
                        value = argument.split('=')[1]
                        value = value.to_i if value =~ /^[0-9]+$/
                        @options[known_option.long] = value
                        unknown_option = false
                        break

                    # Long option with unnecessary value
                    elsif known_option.in_with_value?(argument) && known_option.boolean
                        value = argument.split('=')[1]
                        Parser.finish("#{known_option} does not accept a value (you specified \"#{value}\")")
                    end
                end

                # Unrecognized option
                Parser.finish("unrecognized option \"#{argument}\"") if unknown_option && argument.start_with?('-')
            end

            # Help option
            if @options[:help]
                if BashOutput
                    print "printf '"
                    puts @documentation
                    puts "'"
                    puts 'exit'
                else
                    puts @documentation
                end
                exit(-1)
            end

            # Regular arguments
            next_is_value = false
            raw_arguments.each do |argument|
                if argument.start_with?('-')
                    known_option = @known_options.find { |option| option.in?(argument) }
                    next_is_value = (known_option && !known_option.boolean)
                else
                    arguments << argument unless next_is_value
                    next_is_value = false
                end
            end

            # Bash support
            return unless BashOutput
            @options.keys.each do |name|
                puts "#{name}=\"#{@options[name].to_s.sub('true', 'yes')}\""
            end
            puts 'unset arguments'
            arguments.each do |argument|
                puts "arguments+=(\"#{argument}\")"
            end
        end

        def self.finish(error)
            warn "Error: #{error}."
            warn 'See --help for usage and options.'
            puts 'exit 1' if BashOutput
            exit false
        end

        def self.check_bash_output
            $0 = ENV['from'] || $PROGRAM_NAME
            $PROGRAM_NAME == ENV['from']
        end

        BashOutput = check_bash_output
        attr_accessor :documentation
        attr_accessor :arguments
        attr_accessor :options
    end

    class << self
        @@parser = Parser.new
        @@parser.parse
        def options
            @@parser.options
        end

        def arguments
            @@parser.arguments
        end

        def documentation
            @@parser.documentation
        end

        def all
            [options, arguments, documentation]
        end

        def finish(error)
            Parser.finish(error)
        end
    end

    # This is supposed to be eventually removed
    $documentation = @@parser.documentation
    $arguments = @@parser.arguments
    $options = @@parser.options
end
