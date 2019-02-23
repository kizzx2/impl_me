#!/usr/bin/env ruby -w

require 'fileutils'
require 'tempfile'
require 'rexml/document'

def usage
    puts "ImplMe v0.1 by Chris Yuen <chris@kizzx2.com> 2010"
    puts "Usage: #{$0} [-f] <header_file>"
end

# @yield swig generated XML filename
def swig(filename)
    # Create a stub swig interface file
    interface_filename = "#{filename}.i"
    open(interface_filename, "w") do |file|
        file.puts %(%module impl_me)
        file.puts %(%{)
        file.puts %(#include "#{File.basename(filename)}")
        file.puts %(%})
        file.puts %(%include "#{File.basename(filename)}")
    end

    xml_filename = "#{filename}.xml"
    command = %(swig -c++ -Wall -xml -o #{xml_filename} \
        #{interface_filename})
    if not system(command) 
        raise %(swig returned and error, aborting...)
    end

    yield xml_filename
ensure
    FileUtils.rm_f interface_filename if interface_filename
    FileUtils.rm_f xml_filename if xml_filename
end

def attr_val(attr_node, attr_name)
    REXML::XPath.first(attr_node, %(attribute[@name='#{attr_name}'])).
        attributes['value']
end

def preflight_check
    if ARGV.length != 1
        usage
        exit(-1)
    end

    # Both files should exist
    if not File.file?(ARGV[0])
        then raise %("#{ARGV[0]}" is not an existing file!)
    end
end

# Given an attributelist XML node from the swig XML file
# @return String of the method's signature
def signature(attributelist_node)
    # Return type
    decl = ""
    decl += attr_val(attributelist_node, 'type')
    decl += " " 

    # Class name
    decl += "ImplClass::"

    # Mehtod name
    decl += attr_val(attributelist_node, 'name')

    # Param list
    params = []
    REXML::XPath.each(attributelist_node,
        "parmlist/parm/attributelist")do |param_node|
        param = ""
        typename = ""
        ptrs_and_refs = ""
        qualifiers = []

        # Pointers are like this "p.float"
        # References are like this "r.int"
        # Normal types are like this "float"
        # "MyType ** type" => "p.p.type"
        # etc...
        type_info = attr_val(param_node, 'type').split('.')

        type_info.slice(0, type_info.length - 1).each do |piece|
            ptrs_and_refs += "*" if piece == 'p'
            ptrs_and_refs += "&" if piece == 'r'
            qualifiers << "const" if piece == 'q(const)'
        end

        typename = type_info.last

        # Add a nice space after points and refs
        ptrs_and_refs += " " if not ptrs_and_refs.empty?

        param += [qualifiers.empty? ? nil:qualifiers * ' ',
            typename,ptrs_and_refs].compact * ' '
        param += attr_val(param_node, 'name')

        params << param
    end
    decl += "(" + params * ', ' + ")"
end

# @return Array of signatures defined in the swig XML file
def signatures(xml_filename)
    xml_file = File.new(xml_filename)
    xmldoc = REXML::Document.new(xml_file)
    REXML::XPath.match(xmldoc, %(//cdecl/attributelist)).map do |node|
        # If it already has a body defined in header, nil it
        next if REXML::XPath.first(node, %(attribute[@name="code"]))
        signature(node)
    end
ensure
    xml_file.close if xml_file
end

#===================
# Application start
#===================

HEADER_FILE = ARGV[0]

preflight_check
header_sigs = swig(HEADER_FILE) {|xml_filename| signatures(xml_filename)}

puts "// TODO: Substitue ImplClass with your actual class name"
puts header_sigs.compact.map {|sig| sig += "{}"} * "\n"
