namespace :my_namespace2 do
  task :make_coffee do
    Rake::Task['morning:make_coffee'].invoke
    puts "Ready for the rest of the day!"
  end
end