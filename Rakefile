# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.


require 'rubygems'
require 'rake'

# require(File.join(File.dirname(__FILE__), 'lib', 'tasks', 'pdf_numberer.rake'))
desc "Create documentation"
task :doc do
  require 'maruku'
  `maruku README.markdown`
end