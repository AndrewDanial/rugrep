#!/usr/bin/env ruby
args = ARGF.argv
# args = ARGV

$usage = "USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>"
$regex_err = "Error: cannot parse regex"
# Options are powers of two so that their bits don't overlap
# This allows for checking whether an option was already received
# 220 has gotten to me
$opt_v = 1
$opt_c = 2
$opt_l = 4
$opt_L = 8
$opt_o = 16
$opt_f = 32
$opt_a = 64
$opt_b = 128
$opt_c_num = 256


def parseArgs(args)
  possible_combos = [
    0,

    $opt_c,
    $opt_v,
    $opt_l,
    $opt_L,
    $opt_o,
    $opt_f,
    $opt_a,
    $opt_b,
    $opt_c_num,

    $opt_c + $opt_v,
    $opt_c + $opt_o,

    $opt_f + $opt_c,
    $opt_f + $opt_o,
    $opt_f + $opt_v,

    $opt_a + $opt_v,
    $opt_b + $opt_v,
    $opt_c_num + $opt_v,

    $opt_f + $opt_c + $opt_v,
  ]

  patterns = []
  curr_options = 0
  files = []

  start_regex = false
  end_regex = false

  lines_before = 0
  lines_after = 0

  args.each {|val|
    a_num = false
    b_num = false
    c_num = false

    if val[0] == '"' # If the first char is double quote, that means this is the start of the regex patterns
      if end_regex # If found another regex but we're done, then return error
        return $usage
      else
        start_regex = true
        patterns.append(val)
      end
    elsif val[0] == "-" # Process options
      end_regex = true if start_regex
      underscore = val.split("_")
      equals = val.split("=")
      if underscore[0] == "-A" or equals[0] == "--after-context"
        curr_options & $opt_a == 0 ? curr_options += $opt_a : (return $usage)
        a_num = true

        if underscore.length == 2 and equals.length == 1
          if underscore[1].to_i() > 0
            lines_after = underscore[1].to_i()
          else
            return $usage
          end
        elsif underscore.length == 1 and equals.length == 2
          if equals[1].to_i() > 0
            lines_after = equals[1].to_i()
          else
            return $usage
          end
        else
          return $usage
        end
      end

      if underscore[0] == "-B" or equals[0] == "--before-context"
        curr_options & $opt_b == 0 ? curr_options += $opt_b : (return $usage)
        b_num = true

        if underscore.length == 2 and equals.length == 1
          if underscore[1].to_i() > 0
            lines_before = underscore[1].to_i()
          else
            return $usage
          end
        elsif underscore.length == 1 and equals.length == 2
          if equals[1].to_i() > 0
            lines_before = equals[1].to_i()
          else
            return $usage
          end
        else
          return $usage
        end
      end
      if underscore[0] == "-C" or equals[0] == "--context"
        curr_options & $opt_c_num == 0 ? curr_options += $opt_c_num : (return $usage)
        c_num = true

        if underscore.length == 2 and equals.length == 1
          if underscore[1].to_i() > 0
            lines_before = underscore[1].to_i()
            lines_after = underscore[1].to_i()
          else
            return $usage
          end
        elsif underscore.length == 1 and equals.length == 2
          if equals[1].to_i() > 0
            lines_before = equals[1].to_i()
            lines_after = equals[1].to_i()
          else
            return $usage
          end
        else
          return $usage
        end

      end

      case val
      when "-v", "--invert-match"
        curr_options & $opt_v == 0 ? curr_options += $opt_v : (return $usage)
      when "-c", "--count"
        curr_options & $opt_c == 0 ? curr_options += $opt_c : (return $usage)
      when "-l", "--files-with-matches"
        curr_options & $opt_l == 0 ? curr_options += $opt_l : (return $usage)
      when "-L", "--files-without-match"
        curr_options & $opt_L == 0 ? curr_options += $opt_L : (return $usage)
      when "-o", "--only-matching"
        curr_options & $opt_o == 0 ? curr_options += $opt_o : (return $usage)
      when "-F", "--fixed-strings"
        curr_options & $opt_f == 0 ? curr_options += $opt_f : (return $usage)
      else
        if !a_num and !b_num and !c_num
          return $usage
        end
      end
    else # Process files
      files.append(val)
      end_regex = true if start_regex
    end

    if !possible_combos.include?(curr_options)
      return $usage
    end
  }

  parse_files(curr_options, files, patterns, lines_before, lines_after)
end


def parse_files(options, files, patterns, lines_before, lines_after)

  matched_strings = [] # All the strings from every file

  if patterns.empty? or files.empty? or patterns.empty?
    return $usage
  end

  if options & $opt_f == 0 # if not fixed string, convert to regex
    patterns = patterns.map {|pattern|
      begin
        Regexp.new pattern[1, pattern.length-2]
      rescue
        matched_strings.prepend("Error: cannot parse regex\n")
        nil
      end
    }
  else
    patterns.map! { |pattern| pattern[1, pattern.length-2]}
  end

  patterns.compact!
  if patterns.empty?
    matched_strings = matched_strings.join("")
    return matched_strings
  end

  prefix = files.length > 1

  files.each{|file| # For each file
    curr_file = nil

    begin # Check if we can open file
      curr_file = File.new(file, 'r')
    rescue
      broken = false
      e = false
      if !matched_strings.empty?
        for i in (0...matched_strings.length)
          if !matched_strings[i].include?("Error")
            matched_strings.insert(i, "Error: could not read file #{file}\n")
            broken = true
            break
          end
        end
      else
        matched_strings.append("Error: could not read file #{file}\n")
        e = true
      end
      if !broken and !e
        matched_strings.append("Error: could not read file #{file}\n")
      end
      next
    end

    file_matches = []
    group = false
    curr_file.each_line.with_index {|line, i| # For each line in a file
      line_matches = []
      patterns.each {|pattern| # For each pattern
        if options == $opt_l
          if line.scan(pattern).length > 0
            line_matches.append(file)
            file_matches += line_matches
          end
          break # go to next line because we match a pattern
        end
        if options & $opt_o > 0
          line_matches += line.scan(pattern)
          if line_matches.length == 0
            next
          elsif options & $opt_c > 0
            line_matches.uniq!
            break
          else
            next
          end
        end

        if options & $opt_a > 0
          if !patterns.any?{|patt| line.scan(patt).length > 0} and options & $opt_v > 0

            line_matches.append("--\n") if !file.empty? and group
            group = true
            for x in (i..i+lines_after)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            break
          end
          if line.scan(pattern).length > 0 and options & $opt_v == 0
            line_matches.append("--\n") if !file.empty? and group
            group = true
            for x in (i..i+lines_after)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            break
          end
        end

        if options & $opt_b > 0
          if !patterns.any?{|patt| line.scan(patt).length > 0} and options & $opt_v > 0 # if invert and no patterns match
            line_matches.append("--\n") if !file.empty? and group
            min = i-lines_before < 0 ? 0 : i-lines_before
            group = true
            line_matches.append(line)
            for x in (min..i-1)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            break
          end
          if line.scan(pattern).length > 0 and options & $opt_v == 0
            line_matches.append("--\n") if !file.empty? and group
            min = i-lines_before < 0 ? 0 : i-lines_before
            group = true
            IO.readlines(file)[i] != nil ? line_matches.append(IO.readlines(file)[i]) : break
            for x in (min..i-1)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            break
          end
        end

        if options & $opt_c_num > 0
          if !patterns.any?{|patt| line.scan(patt).length > 0} and options & $opt_v > 0
            line_matches.append("--\n") if !file.empty? and group
            min = i-lines_before < 0 ? 0 : i-lines_before
            group = true
            IO.readlines(file)[i] != nil ? line_matches.append(IO.readlines(file)[i]) : break
            for x in (min..i-1)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            for x in (i+1..i+lines_after)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            break
          end
          if line.scan(pattern).length > 0 and options & $opt_v == 0
            line_matches.append("--\n") if !file.empty? and group
            min = i-lines_before < 0 ? 0 : i-lines_before
            group = true
            IO.readlines(file)[i] != nil ? line_matches.append(IO.readlines(file)[i]) : break
            for x in (min..i-1)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            for x in (i+1..i+lines_after)
              IO.readlines(file)[x] != nil ? line_matches.append(IO.readlines(file)[x]) : break
            end
            break
          end
        end

        if line.scan(pattern).length > 0 and options & $opt_v == 0
          line_matches.append(line)
          break
        end

      }

      if options & $opt_v > 0 and options < 64 # If we want to invert
        if !patterns.any?{|pattern| line.scan(pattern).length > 0} #if no pattern matches, add it
          line_matches.append(line)
        end
      end

      file_matches += line_matches

    }

    if options & $opt_c > 0 # If -c is specified then change from lines to # of lines
      file_matches = [file_matches.length.to_s + "\n"]
    end

    if prefix and options != $opt_l # if more than 1 file then prepend the prefix filename
      file_matches.map! {|string|
        string != "--\n" ?  File.basename(curr_file) + ": " + string : "--\n"
      }
    end

    if options == $opt_l # If we want files that match
      if files.length > 1
        file_matches.map! {|matches| matches.split(":")[0]}
      end
      file_matches.uniq!
    end

    matched_strings += file_matches

    curr_file.close
  }

  if options == $opt_L
    arr = []

    if matched_strings.length > 0 and files.length == 1
      return arr.join("")
    end

    files.each{|file|
      x = nil
      begin # Check if we can open file
        x = File.new(file, 'r')
      rescue
        next
      end

      # If any of the strings in the array contain the file name, that means it matched
      #puts matched_strings
      included = matched_strings.any?{|string|
        string.include?(file)
      }

      if !included
        arr.append(file)
      end

      x.close
    }
    arr.uniq!
    return arr.join("")
  end

  if options & $opt_o > 0
    return matched_strings.join("\n")
  end

  matched_strings.join("")

end
puts parseArgs(args)
