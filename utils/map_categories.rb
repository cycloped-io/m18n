#!/usr/bin/env ruby

require 'bundler/setup'
$:.unshift "lib"
require 'slop'
require 'progress'
require 'cyclopedio/wiki'
require 'csv'

options = Slop.new do
  banner "#{$PROGRAM_NAME} -d database -o mapping.csv [-p port] [-h host] [-x offset] [-l limit] [-c c:s:n]\n"+
    "Map Cyc terms to Wikipedia categories in languages other than English."

  on :d=, :database, "ROD database with Wikipedia data", required: true
  on :i=, :input, "Input file with English category mapping", required: true
  on :o=, :output, "Output mapping file", required: true
  on :x=, :offset, "Category offset (skip first n categories)", as: Integer, default: 0
  on :l=, :limit, "Category limit (limit processing to n categories)", as: Integer
  on :L=, :language, "The target language for the mapping", required: true
  on :s=, :services, "File with addresses of ROD-rest services"
end

begin
  options.parse
rescue => ex
  puts ex
  puts options
  exit
end

include Cyclopedio::Wiki

Database.instance.open_database(options[:database])
at_exit do
  Database.instance.close_database
end

CSV.open(options[:input]) do |input|
  CSV.open(options[:output],"w") do |output|
    input.with_progress do |tuple|
      category_name,cyc_id,cyc_name,probability = tuple
      category = Category.find_by_name(category_name)
      translation = category.translations.find{|t| t.language == options[:language] }
      next if translation.nil?
      output << [translation.value,cyc_id,cyc_name,probability]
    end
  end
end
