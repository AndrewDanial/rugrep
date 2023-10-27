#  gem install simplecov for coverage
# uncomment the following two lines to generate coverage report
require 'simplecov'
SimpleCov.start
require_relative File.join("..", "src", "rugrep")

# write rspec tests
describe "Failing Test Cases!" do
  context "No Args" do
    it "0 Args" do
      expect(parseArgs([])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Invalid Regex" do
      expect(parseArgs(["-v", "\"[\"", "../test.txt"])).to eq("Error: cannot parse regex\n")
    end
    it "Invalid File" do
      expect(parseArgs(["-v", "\"hello\"", "tewtwet.txt"])).to eq("Error: could not read file tewtwet.txt\n")
    end
    it "2 Invalid Files" do
      expect(parseArgs(["-v", "\"hello\"", "a.txt", "b.txt"])).to eq("Error: could not read file a.txt\nError: could not read file b.txt\n")
    end
    it "Invalid Options" do
      expect(parseArgs(["-j", "\"hello\"", "../test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Badly written after context" do
      expect(parseArgs(["-A_1_2", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Badly written before context" do
      expect(parseArgs(["-B_1_2", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Badly written context" do
      expect(parseArgs(["-C_1_2", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end

    it "Badly written after context but less" do
      expect(parseArgs(["-A_a", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Badly written before context but big" do
      expect(parseArgs(["-B_a", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Badly written context but big" do
      expect(parseArgs(["-C_a", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
    it "Invalid combo" do
      expect(parseArgs(["-L", "-c", "\"hello\"", "test.txt"])).to eq("USAGE: ruby rugrep.rb <OPTIONS> <PATTERNS> <FILES>")
    end
  end
  context "Valid Args" do
    it "No Options" do
      expect(parseArgs(["\"this\"", "test.txt"])).to eq("this is a line this this\nthis\n")
    end
    it "No Options 2 Files" do
      expect(parseArgs(["\"this\"", "\"1\"","test.txt", "test2.txt"])).to eq("test.txt: this is a line this this\ntest.txt: this\ntest2.txt: 1\n")
    end
    it "Count" do
      expect(parseArgs(["-c", "\"this\"","test.txt"])).to eq("2\n")
    end
    it "Literal" do
      expect(parseArgs(["-F", "-c", "\"this\"","test.txt"])).to eq("2\n")
    end
    it "Before" do
      expect(parseArgs(["-B_1", "\"this\"", "test.txt"])).to eq("this is a line this this\nhello\n--\nthis\ngeegergergerg\n")
    end
    it "Before long" do
      expect(parseArgs(["--before-context=1", "\"this\"", "test.txt"])).to eq("this is a line this this\nhello\n--\nthis\ngeegergergerg\n")
    end
    it "After" do
      expect(parseArgs(["-A_1", "\"this\"", "test.txt"])).to eq("this is a line this this\nline 3 perhaps\n--\nthis\nreal\n")
    end

    it "After long" do
      expect(parseArgs(["--after-context=1", "\"this\"", "test.txt"])).to eq("this is a line this this\nline 3 perhaps\n--\nthis\nreal\n")
    end

    it "Context" do
      expect(parseArgs(["-C_1", "\"this\"", "test.txt"])).to eq("this is a line this this\nhello\nline 3 perhaps\n--\nthis\ngeegergergerg\nreal\n")
    end

    it "Context long" do
      expect(parseArgs(["--context=1", "\"this\"", "test.txt"])).to eq("this is a line this this\nhello\nline 3 perhaps\n--\nthis\ngeegergergerg\nreal\n")
    end
    it "Before inv" do
      expect(parseArgs(["-B_1", "-v", "\"this\"", "test.txt"])).to eq("hello\n--\nline 3 perhaps\nthis is a line this this\n--\nfin.\nline 3 perhaps\n--\ngeegergergerg\nfin.\n--\nreal\nthis\n")
    end
    it "After inv" do
      expect(parseArgs(["-A_1", "-v", "\"hello\"", "\"this\"", "test.txt"])).to eq("line 3 perhaps\nfin.\n--\nfin.\ngeegergergerg\n--\ngeegergergerg\nthis\n--\nreal\n")
    end
    it "Context inv" do
      expect(parseArgs(["-C_1", "-v", "\"hello\"", "\"this\"", "\"real\"", "test.txt"])).to eq("line 3 perhaps\nthis is a line this this\nfin.\n--\nfin.\nline 3 perhaps\ngeegergergerg\n--\ngeegergergerg\nfin.\nthis\n")
    end
    it "Only matching" do
      expect(parseArgs(["-o", "\"this\"", "test.txt"])).to eq("this\nthis\nthis\nthis")
    end
    it "Files Matching" do
      expect(parseArgs(["-l", "\"this\"", "test.txt"])).to eq("test.txt")
    end
    it "Files Not Matching" do
      expect(parseArgs(["-L", "\"this\"", "test.txt"])).to eq("")
    end
    it "Multiple Files Not Matching" do
      expect(parseArgs(["-L", "\"this\"", "test.txt", "test2.txt"])).to eq("test2.txt")
    end
    it "Invert" do
      expect(parseArgs(["-v", "\"hello\"", "test.txt"])).to eq("this is a line this this\nline 3 perhaps\nfin.\n\geegergergerg\nthis\nreal\n")
    end
  end
end

