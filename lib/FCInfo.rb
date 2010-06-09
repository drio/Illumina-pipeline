#!/usr/bin/ruby
#
#Class to obtain flowcell information from LIMS
class FCInfo
  def initialize(fc)
    @limsScript = "../third_party/getAnalysisPreData.pl"
    @fcName = extractFC(fc)
    getFCInfo()
  end

  # Method to obtain number of cycles per run
  def getNumCycles()
    return @numCycles
  end

  # Method to find if FC is paired or fragment
  # True - paired, false - fragment
  def paired?()
    return @paired
  end

  # Method to retrieve reference paths for a specified lane
  def getRefPath(lane)
    return @referencePaths[lane.to_s]
  end

  # Method to find out if reference path returned from LIMS is
  # valid for specified lane. Returns true if path is valid, false
  # otherwise
  def refPathValid?(lane)
    refPath = @referencePaths[lane.to_s]

    # A reference path "sequence" implies building only sequence, and no
    # alignment. Hence it is a valid reference
    if refPath.downcase.eql?("sequence")
      return true
    end

    # A reference path is invalid if any of the following is true
    # 1) It is null (nil) or empty
    # 2) It does not exist, or is not a valid directory
    # 3) It does not end with string "/squash"
    # If all of above are false, reference path is valid
    if refPath == nil || refPath.eql?("") || !File::exist?(refPath) ||
       !File::directory?(refPath) || !refPath.match(/\/squash$/)
      return false
    end
    return true
  end

  private
  @limsScript = ""
  @paired = false
  @numCycles = 0
  @fcName = nil
  @genusName = nil
  @speciesName = nil
  @referencePaths = nil

  # Helper method to handle errors encountered in interacting with LIMS
  # such as error in connecting to LIMS
  def handleError(msg)
    # For right now, throw an exception
    raise "Error in obtaining information from LIMS. " +
          "Error from LIMS : " + msg
  end

  # Helper method to reduce full flowcell name to FC name used in LIMS
  def extractFC(fc)
    flowCellName = nil
    temp = fc.slice(/FC(.+)$/)
    if temp == nil
      flowCellName = fc.slice(/([a-zA-Z0-9]+)$/)
    else
      flowCellName = temp.slice(2, temp.size)
    end
    return flowCellName
  end

  # Helper method to obtain number of cycles, reference paths and FC type
  # (i.e. paired / fragment)
  def getFCInfo()

    # Use lane 5 to get information for reference path, FC type and
    # number of cycles
    cmd = "perl " + @limsScript + " " + @fcName.to_s + "-5"
    output = `#{cmd}`
    exitCode = $?

    # Validate that the output from LIMS was proper
    # Currently validation based on exit code is not supported since they
    # return zero for success as well as failure cases
    if output.downcase.match(/error/)
      handleError(output)
    end

    findFCType(output)
    findNumCycles(output)
    @referencePaths = Hash.new()
    @referencePaths["5"] = parseReferencePath(output)

    for i in 1..8
      if i != 5
        cmd = "perl " + @limsScript + " " + @fcName.to_s + "-" + i.to_s
        output = `#{cmd}`

        if output.downcase.match(/error/)
          handleError(output)
        end

        @referencePaths[i.to_s] = parseReferencePath(output)
      end
    end
  end

  # Helper method to parse the LIMS output to find reference path
  def parseReferencePath(output)
    referencePath = nil

    if(output.match(/BUILD_PATH=\s+[Ss]equence/) ||
       output.match(/BUILD_PATH=[Ss]equence/))
       referencePath = "sequence"

    elsif(output.match(/BUILD_PATH=\s+\/data/) ||
         output.match(/BUILD_PATH=\/data/))
         referencePath = output.slice(/\/data\/slx\/references\/\S+/)
        
         # Since reference paths starting with /data/slx/references represent
         # format of reference paths in alkek, change the prefix of these paths
         # to match the file-system structure in ardmore.
         referencePath.gsub!(/\/data\/slx\/references/,
         "/stornext/snfs5/next-gen/Illumina/genomes")

    elsif(output.match(/BUILD_PATH=\s+\/stornext/) ||
         output.match(/BUILD_PATH=\/stornext/))
         # If LIMS already has correct path corresponding to the file
         # system structure in ardmore, return that path without any
         # modifications.
         referencePath = output.slice(/\/stornext\/\S+/)
    end
    return referencePath
  end

  # Get number of cycles for the flowcell
  def findNumCycles(output)
    temp = output.slice(/NUMBER_OF_CYCLES_READ1=\d+/)
    if temp != nil && !temp.eql?("")
      @numCycles = Integer(temp.split("=")[1]) - 1
    else
      @numCycles = 0
    end
  end

  # Determine if FC is paired-end or fragment
  def findFCType(output)
    if(output.match(/FLOWCELL_TYPE=p/))
       @paired = true
    else
      @paired = false
    end
  end
end

__END__
obj = FCInfo.new("100323_USI-EAS034_0003_PE1_FC61F3YAAXX")
puts "PAIRED = " + obj.paired?().to_s
puts "Num Cycles = " + obj.getNumCycles().to_s

for i in 1..8
  refPath = obj.getRefPath(i)
  puts "Lane " + i.to_s + " : " + refPath

  if true == obj.refPathValid?(i)
    puts "Reference Path is valid"
  else
    puts "Reference Path is invalid"
  end

end
#obj = FCInfo.new("091103_USI-EAS376_0009_FC430MPAAXX")

