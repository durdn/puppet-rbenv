Puppet::Type.type(:rbenvgem).provide :default do
  desc "Maintains gems inside an RBenv setup"

  commands :su => 'su'

  def install
    args = ['install', '--no-rdoc', '--no-ri']
    if resource[:install_params].split(',').any?
      args = args + resource[:install_params].split(',')
    end
    args << "-v#{resource[:ensure]}" if !resource[:ensure].kind_of?(Symbol)
    args << gem_name

    output = gem(*args)
    fail "Could not install: #{output.chomp}" if output.include?('ERROR')
  end

  def uninstall
    gem 'uninstall', '-aIx', gem_name
  end

  def latest
    @latest ||= list(:remote)
  end

  def current
    list
  end

  private
    def gem_name
      resource[:gemname]
    end

    def gem(*args)
      exe =  "RBENV_VERSION=#{resource[:ruby]} " + resource[:rbenv] + '/bin/gem'
      su('-', resource[:user], '-c', [exe, *args].join(' '))
    end

    def list(where = :local)
      args = ['list', where == :remote ? '--remote' : '--local', "#{gem_name}$"]

      gem(*args).lines.map do |line|
        line =~ /^(?:\S+)\s+\((.+)\)/

        return nil unless $1

        # Fetch the version number
        ver = $1.split(/,\s*/)
        ver.empty? ? nil : ver
      end.first
    end
end
