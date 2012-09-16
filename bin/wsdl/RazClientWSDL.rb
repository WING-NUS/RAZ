#!/usr/bin/env ruby
require "soap/wsdlDriver"

wsdl = "http://wing.comp.nus.edu.sg/~wing.nus/wing.nus.wsdl"
driver = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

## Raz
# classify the target pos-tagged file
#output = driver.arg_zone_postagged_file("http://wing.comp.nus.edu.sg/~wing.nus/samples/E06-1050.postagged.txt")
# Testing - JP - 2011Jan24
output = driver.arg_zone_postagged_file("http://wing.comp.nus.edu.sg/~junping/test.txt")

puts output

# Could be useful hints about interpreting output

# Extracted from Simone Teufel's AZ page http://www.cl.cam.ac.uk/~sht25/az.html
#
#.BKG: General scientific background (yellow) 
#.OTH: Neutral descriptions of other people's work (orange) 
#.OWN: Neutral descriptions of the own, new work (blue) 
#.AIM: Statements of the particular aim of the current paper (pink) 
#.TXT: Statements of textual organization of the current paper (in chapter 1, we introduce...) (red) 
#.CTR: Contrastive or comparative statements about other work; explicit mention of weaknesses of other work (green) 
#.BAS: Statements that own work is based on other work (purple) 

