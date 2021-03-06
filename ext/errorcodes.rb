#!/usr/bin/env ruby

def camelize(lower_case_and_underscored_word)
	lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
end

ec_txt, ec_def = *ARGV

if RUBY_PLATFORM =~ /java/

def initialize_file fd_def, ec_def
  fd_def.puts <<EOCODE
import org.jruby.Ruby;
import org.jruby.RubyClass;

/*
 * #{ec_def} - Definition of error classes.
 *
 * WARNING: This file is autogenerated. Please edit #{__FILE__} !
 *
 */


public class Errors {
    public static void initializeError(Ruby ruby) {
EOCODE
end

def close_file fd_def
  fd_def.puts <<EOCODE
    }
}
EOCODE
end

def add_error fd_def, class_name, baseclass_code, sqlstate, class_code, is_sqlclass
  fd_def.puts   "        {"
  fd_def.puts   "            RubyClass klass = PgExtService.defineErrorClass( ruby, #{class_name.inspect}, #{baseclass_code.downcase} );"
  fd_def.puts   "            PgExtService.registerErrorClass( ruby, #{sqlstate.inspect}, klass );"
  if is_sqlclass
  	fd_def.puts "            PgExtService.registerErrorClass( ruby, #{class_code.inspect}, klass );"
  end
  fd_def.puts   "        }"
end

else

def initialize_file fd_def, ec_def
  fd_def.puts <<EOCODE
/*
 * #{ec_def} - Definition of error classes.
 *
 * WARNING: This file is autogenerated. Please edit #{__FILE__} !
 *
 */


EOCODE
end

def close_file fd_def
end

def add_error fd_def, class_name, baseclass_code, sqlstate, class_code, is_sqlclass
  fd_def.puts "{"
  fd_def.puts "  VALUE klass = define_error_class( #{class_name.inspect}, #{baseclass_code} );"
  fd_def.puts "  register_error_class( #{sqlstate.inspect}, klass );"
  if is_sqlclass
  	fd_def.puts "  register_error_class( #{class_code.inspect}, klass );"
  end
  fd_def.puts "}"
end

end

File.open(ec_def, 'w') do |fd_def|
  initialize_file fd_def, ec_def

	File.read(ec_txt).lines.each do |line|
		# The format of this file is one error code per line, with the following
		# whitespace-separated fields:
		#
		#      sqlstate    E/W/S    errcode_macro_name    spec_name

		if line =~ /^(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+/i
			sqlstate, ews, errcode_macro_name = $1, $2, $3
			next unless ews=='E'

			is_sqlclass = sqlstate[2..-1] == '000'
			class_code = sqlstate[0,2]
			baseclass_code = is_sqlclass ? 'NULL' : class_code.inspect
			class_name = camelize(errcode_macro_name.sub('ERRCODE_', '').downcase)

      add_error fd_def, class_name, baseclass_code, sqlstate, class_code, is_sqlclass
		end
	end

  close_file fd_def
end
