#!/bin/bash
  
VisIVOImporter --fformat ascii clusterfields4.ascii
VisIVOViewer -x X -y Y -z Z --scale --glyphs pixel VisIVOServerBinary.bin
