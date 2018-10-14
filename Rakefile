#!/usr/bin/env ruby

require 'xcodeproj'

task :make do
    name = "nothing"
    system "swift package -Xcc -ISources/BoringSSL/include -Xlinker -lz generate-xcodeproj"
    FileList['*.xcodeproj'].each do |source|
        name = source.match(%r{^(.+).xcodeproj$})[1]
    end
      puts name


        project = Xcodeproj::Project.open(name + '.xcodeproj')

        project.targets.each do |target|
       
        if target.name == "CgRPC"
            puts  "FOUND"
            target.build_configurations.each  { |config|
            config.build_settings['OTHER_LDFLAGS'] = "-lz"
            }
        end
    end


    project.save

end

task :xcodeproj do

  File.write("Dependencies.swift", "// Placeholder file to keep SPM happy") unless File.exist?("Dependencies.swift")

  system "swift package generate-xcodeproj"

  project = Xcodeproj::Project.open('Dependencies.xcodeproj')

  project.targets.each do |target|
    module_map_file = "Dependencies.xcodeproj/GeneratedModuleMap/#{target.name}/module.modulemap"

    project.build_configurations.each { |config|
      config.build_settings["SDKROOT"] = "macos"
      config.build_settings.delete("SUPPORTED_PLATFORMS")
    }

    target.build_configurations.each do |config|
      config.build_settings['DEFINES_MODULE'] = 'YES'

      # Uncomment this to build a static library instead of a dynamic library
      # config.build_settings['MACH_O_TYPE'] = 'staticlib'

      # Set MODULEMAP_FILE for non-Swift Frameworks
      #
      # Module maps are correctly generated for non-Swift frameworks, but SPM
      # doesn't put the path in the build config output from generate-xcodeproj.
      if File.exist? module_map_file
        config.build_settings['MODULEMAP_FILE'] = "${SRCROOT}/#{module_map_file}"
      end
    end
  end

  project.save

end
