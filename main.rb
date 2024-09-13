# frozen_string_literal: true

begin
  require 'erb'
rescue LoadError
  puts 'Installing ERB gem...'
  system('gem install erb')
end

begin
  require 'fileutils'
rescue LoadError
  puts 'Installing FileUtils gem...'
  system('gem install fileutils')
end

begin
  require 'httpparty'
rescue LoadError
  puts 'Installing HTTParty gem...'
  system('gem install httpparty')
end

begin
  require 'thor'
rescue LoadError
  puts 'Installing Thor gem...'
  system('gem install thor')
end

class MyCLI < Thor
  desc 'theme', 'create a new theme folder'
  options name: :required, type: :string, desc: 'The name of the theme'
  options color: :required, type: :string, desc: 'The color code of the theme'
  options logo: :required, type: :string, desc: 'The full url of the logo'
  long_desc <<-LONGDESC
      Example:
        $ ruby main.rb theme --name "assemblee nationale" --color "#000000" --logo "https://opensourcepolitics.eu/wp-content/uploads/2023/06/Fichier-9.png"
  LONGDESC

  def theme
    puts 'Generating new customized theme...'
    theme_name = options[:name]
    theme_name = theme_name.downcase.gsub(' ', '_')
    primary_color = options[:color]
    logo_url = options[:logo]
    logo_ext = File.extname(logo_url)
    filename = "img/logo#{logo_ext}"

    folder = "./data/#{theme_name}/"
    FileUtils.mkdir(folder) unless File.directory?(folder)
    FileUtils.cp_r('src/login', folder)

    template = File.read("#{folder}/login/resources/css/styles.css.erb")
    renderer = ERB.new(template)

    puts 'Downloading the logo...'
    request = ::HTTParty.get(logo_url, follow_redirects: true)
    raise 'Error: Unable to download the logo. Please check the url and try again.' unless request.success?

    File.open("#{folder}/login/resources/#{filename}", 'wb') do |file|
      file.write request.body
    end

    binding = binding()
    binding.local_variable_set(:color, primary_color)
    binding.local_variable_set(:logo_path, "../#{filename}")
    output = renderer.result(binding)

    File.open("#{folder}/login/resources/css/styles.css", 'wb') do |file|
      file.write output
    end

    if File.exist?("#{folder}/login/resources/css/styles.css.erb")
      FileUtils.rm_f("#{folder}/login/resources/css/styles.css.erb")
    end

    puts 'Theme generated successfully!'
    puts "You can find your theme in the data/#{theme_name} folder."
    puts "You can now upload it to your server by adding 'data/#{theme_name}' to the keycloak's themes directory"
  rescue StandardError => e
    puts "\e[31mError: #{e.message}\e[0m"
    puts "\e[31mExiting...\e[0m"
    exit 1
  end
end

MyCLI.start(ARGV)
