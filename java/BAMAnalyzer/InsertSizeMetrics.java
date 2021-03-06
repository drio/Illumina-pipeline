/*
 * The MIT License
 *
 * Copyright (c) 2009 The Broad Institute
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import java.util.TreeMap;
import net.sf.picard.sam.SamPairUtil.PairOrientation;
import java.io.*;
import java.util.LinkedList;

/**
 * Class to encapsulate insert size metrics
 */

/**
 * @author Nirav Shah niravs@bcm.edu
 * Class encapsulating insert size metrics
 */
public class InsertSizeMetrics
{
  private PairOrientation orientation;  // Orientation of the read pair
  private int medianInsertSize  = 0;    // Median value of insert size
  private int modalInsertSize   = 0;    // Modal value of insert size
  private int totalPairs        = 0;    // Total pairs of records
  private double meanInsertSize = 0;    // Mean insert size
  private double threshold      = 0.01; // To clip insert size chart
  
  private TreeMap<Integer, Integer> insertSizeList = null;

  /**
   * Class constructor
   * @param orient - Orientation of the pair 
   */ 
  public InsertSizeMetrics(PairOrientation orient)
  {
    this.orientation = orient;
    insertSizeList = new TreeMap<Integer, Integer>();
  }
 
  /**
   * Method to remember the insert size for the current read
   * @param insertSize - integer corresponding to insert size for the read
   */ 
  public void addInsertSize(int insertSize)
  {
    totalPairs++;
    
    Integer iSize = new Integer(insertSize); 
    if(insertSizeList.containsKey(iSize))
    {
      Integer val = insertSizeList.get(iSize);
      val++;
      insertSizeList.put(iSize, val);
      val = null;
    }
    else
    {
      insertSizeList.put(iSize, 1);
    }
    iSize = null;
  }
  
  /**
   * Returns total number of pairs for specified orientation
   * @return - total pairs
   */
  public int getTotalPairs()
  {
    return totalPairs;
  }

  public int getMedianInsertSize()
  {
    return medianInsertSize;
  }

  public int getModeInsertSize()
  {
    return modalInsertSize;
  } 

  public PairOrientation getPairOrientation()
  {
    return orientation;
  }

  /**
   * Log insert size distribution in a CSV
   */
  private void logInsertSizeDistribution() throws IOException
  {
    System.err.println("Logging time");
    String logFileName    = orientation.toString() + "_InsertSizeDist.csv";
    BufferedWriter writer = new BufferedWriter(new FileWriter(logFileName));
    
    for(Integer key : insertSizeList.keySet())
    {
      writer.write(key.toString() + "," + insertSizeList.get(key).toString());
      writer.newLine();
    }
    writer.close();
  }

  /**
   * Plot the distribution of insert size using GNUPlot
   */
  private void createDistributionChart()
  {
    System.err.println("chart time");
    String outputFile = orientation.toString() + "_InsertSizeDist.png";

    trimInsertSizeDistribution();
   
    System.err.println("CHART TRIMMED.. PLOT TIME");
 
    int length = insertSizeList.keySet().size();
    double xAxis[] = new double[length];
    double yAxis[] = new double[length];
    int idx = 0;
    
    for(Integer key : insertSizeList.keySet())
    {
      xAxis[idx] = key.doubleValue();
      yAxis[idx] = insertSizeList.get(key).doubleValue();
      idx++;
    }
    try
    {
    	Plot p = new Plot(outputFile, "Insert Size Distribution", "Insert Size", 
    			          "Number of Reads", orientation.toString() + "_Distribution",
    			          xAxis, yAxis);
      p.plotGraph();
    }
    catch(Exception e)
    {
      System.err.println(e.getMessage());
    }
  }
 
  /**
   * Method to calculate median and mode values of insert size
   */
  private void calculateStats()
  {
    int medianIndex     = totalPairs / 2;
    int numElements     = 0;
    boolean foundMedian = false;
    
    Integer modeInsert = insertSizeList.firstKey();
    Integer modeValue  = insertSizeList.get(modeInsert);
    
    for(Integer key : insertSizeList.keySet())
    {
      numElements = numElements + insertSizeList.get(key).intValue();
      
      if(numElements > medianIndex && foundMedian == false)
      {
			  medianInsertSize = key.intValue();
			  foundMedian = true;
      }
      
      if(modeValue < insertSizeList.get(key))
      {
        modeInsert = key;
        modeValue  = insertSizeList.get(key);
      }
      key = null;
    }
    modalInsertSize = modeInsert.intValue();
  }
  
  /**
   * Calculate mean insert size
   */ 
  private void findMeanInsertSize()
  {
    double sumInsertSize = 0;
    double numElem = 0;
    
    for(Integer key : insertSizeList.keySet())
    {
      numElem = numElem + insertSizeList.get(key).doubleValue();
      sumInsertSize = sumInsertSize + insertSizeList.get(key).doubleValue() *
                      key.doubleValue();
      key = null;
    }
    meanInsertSize = sumInsertSize / numElem;
  }

  /**
   * Trim insert size distribution to plot a meaningful graph
   */
  private void trimInsertSizeDistribution()
  {
    int numModeElements = insertSizeList.get(modalInsertSize).intValue();
    int minValue = (int)(threshold * numModeElements);
    int val;
    LinkedList<Integer> binsToRemove = new LinkedList<Integer>();
    
    /**
     * Keep all the insert size values lower than the modal value.
     * For the insert size value beyond the modal value, keep only the
     * records that exceed the minimum threshold.
     */
    for(Integer key : insertSizeList.keySet())
    {
      val = insertSizeList.get(key).intValue();
      if((key.intValue() > modalInsertSize) && (val < minValue))
      {
        binsToRemove.add(key);
      }
    }
    
    for(int i = 0; i < binsToRemove.size(); i++)
    {
      insertSizeList.remove(binsToRemove.get(i));
    }
    System.err.println("List size after trimming : " + insertSizeList.size());
  }
 
  /**
   * Display the insert size metrics
   */
  public void calculateResult()
  {
    System.err.println("Number of Elements in TreeMap : " + insertSizeList.size()); 
    calculateStats();
    
    try
    {
      logInsertSizeDistribution();
      createDistributionChart();
    }
    catch(Exception e)
    {
      System.err.println(e.getMessage());
    }
  }
}

