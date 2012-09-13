#!/usr/bin/env ruby
require "soap/wsdlDriver"

wsdl = "http://wing.comp.nus.edu.sg/~wing.nus/wing.nus.wsdl"
driver = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

## Raz
# classify the target pos-tagged file
output = driver.arg_zone_postagged_file("http://wing.comp.nus.edu.sg/~wing.nus/samples/E06-1050.postagged.txt")

puts output
