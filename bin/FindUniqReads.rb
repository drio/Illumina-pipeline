#!/usr/bin/ruby
$:.unshift File.join(File.dirname(__FILE__), ".", "..", "lib")

require 'rubygems'
require 'hpricot'
require 'fileutils'
require 'net/smtp'
require 'PipelineHelper'

#This class is a wrapper for SlxUniqueness.jar to find unique reads.
#It works on per-lane basis only.
class FindUniqueReads
  def initialize()
    @jarName = "/stornext/snfs5/next-gen/Illumina/ipipe/java/SlxUniqueness.jar"
    @lanes   = ""  # Lanes to consider for running uniqueness
    @fcName  = ""
    @helper  = PipelineHelper.new
    begin
      #findLaneNumbers()
      #findFCName()
      @lanes  = @helper.findAnalysisLaneNumbers()
      @fcName = @helper.findFCName()
      findUniqueness()
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
      exit -1
    end
  end

  private

  def findUniqueness()
    @lanes.each_byte do |lane|
      puts "Generating Uniqueness for lane : " + lane.chr
      fileNames = findSequenceFileNames(lane.chr)
      buildJarCommand(lane.chr, fileNames)
    end
  end

  def buildJarCommand(lane, fileNames)
    resultFileName = "Uniqueness_" + @fcName + "_" + lane + ".txt"

    # Create temp directory
    tmpDir = "tmp_" + lane
    FileUtils.mkdir(tmpDir)

    # Select analysis as fragment or paired
    if fileNames.length == 2
      analysisMode = "paired"
    else
      analysisMode = "fragment"
    end
    cmd = "java -Xmx4G -jar " + @jarName + " " + analysisMode + " " + tmpDir

    fileNames.each do |fname|
      cmd = cmd + " " + fname
    end
    puts cmd

    resultFile = File.new(resultFileName, "w")
    resultFile.write("Flowcell Name : " + @fcName + " Lane Number : " + lane)
    resultFile.close()
#    resultFile.write("")
    puts "Computing Uniqueness Results"
    cmd = cmd + " >> " + resultFileName
    `#{cmd}`

    resultFile = File.open(resultFileName, "r")
    lines = resultFile.read()

   # to = [ 'niravs@bcm.edu' ]
    to = [ "deiros@bcm.edu", "dc12@bcm.edu", "niravs@bcm.edu", "yhan@bcm.edu",
           "fongeri@bcm.edu", "javaid@bcm.edu", "yw14@bcm.edu" ]
    @helper.sendEmail("sol-pipe@bcm.edu", to, "Illumina Uniqueness Results", lines)
    puts "Finished Computing Uniqueness Results for lane : " + lane
    FileUtils.remove_dir(tmpDir, true)
  end

  # Helper method to find sequence files for a given lane
  def findSequenceFileNames(laneNum)
    return Dir["s_" + laneNum + "*sequence.txt"]
  end
end

obj = FindUniqueReads.new()
