# frozen_string_literal: true

require 'json'

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

    folder = "./theme/#{theme_name}/"
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
    puts "You can find your theme in the theme/#{theme_name} folder."
    puts "You can now upload it to your server by adding 'theme/#{theme_name}' to the keycloak's themes directory"
  rescue StandardError => e
    puts "\e[31mError: #{e.message}\e[0m"
    puts "\e[31mExiting...\e[0m"
    exit 1
  end

  desc 'archive', 'Creates a jar file of the themes'
  long_desc <<-LONGDESC
      Use this command to archive the themes into a jar file.

      Note: Define a version number for the jar file. If not provided, the default version is 0.0.1

      Example:
        $ ruby main.rb archive 0.0.2
  LONGDESC
  def archive(version = '0.0.1')
    puts 'Archiving themes...'
    archive_name = "org.keycloak.osp-themes-#{version}.jar"
    themes = Dir['theme/*']
    themes_metadata = themes.map do |theme|
      next if theme == 'theme/META-INF'

      { 'name' => theme.split('/')[-1], 'types' => ['login'] }
    end.compact
    meta_inf = { themes: themes_metadata }

    filename = 'theme/META-INF/keycloak-themes.json'
    FileUtils.mkdir_p(File.dirname(filename)) unless File.exist?(filename)

    File.open(filename, 'wb') do |file|
      file.write(::JSON.pretty_generate(meta_inf))
    end

    system("jar -cvf #{archive_name} -C theme/ .")

    unless File.exist?(archive_name)
      raise 'Error: Unable to archive the themes. Please check the themes directory and try again.'
    end

    FileUtils.mv(archive_name, 'dist/')

    puts 'Themes archived successfully!'
    puts "You can find the jar files at dist/#{archive_name}"
  rescue StandardError => e
    puts "\e[31mError: #{e.message}\e[0m"
    puts "\e[31mExiting...\e[0m"
  end
end

MyCLI.start(ARGV)
