source "http://rubygems.org"

# Specify your gem's dependencies in resque-pause.gemspec
gemspec

gem "rake"

group :test, :development do
  platforms :mri_19, :mri_20 do
    gem "debugger"
  end

  platforms :mri_21 do
    gem "byebug"
  end
end
