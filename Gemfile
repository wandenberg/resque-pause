source "http://rubygems.org"

# Specify your gem's dependencies in resque-pause.gemspec
gemspec

gem "rake"

group :test, :development do
  platforms :mri_19 do
    gem "debugger"
  end

  platforms :mri_20, :mri_21 do
    gem "byebug"
  end
end
