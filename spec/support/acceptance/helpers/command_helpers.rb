require_relative 'base_helpers'
require_relative '../../tests/command_runner'

module AcceptanceTests
  module CommandHelpers
    include BaseHelpers
    extend RSpec::Matchers::DSL

    def run_command(*args)
      Tests::CommandRunner.run(*args) do |runner|
        runner.directory = fs.project_directory
        yield runner if block_given?
      end
    end

    def run_command!(*args)
      run_command(*args) do |runner|
        runner.run_successfully = true
        yield runner if block_given?
      end
    end

    def run_command_isolated_from_bundle(*args)
      run_command(*args) do |runner|
        runner.around_command do |run_command|
          Bundler.with_clean_env(&run_command)
        end

        yield runner if block_given?
      end
    end

    def run_command_isolated_from_bundle!(*args)
      run_command_isolated_from_bundle(*args) do |runner|
        runner.run_successfully = true
        yield runner if block_given?
      end
    end

    def run_command_within_bundle(*args)
      run_command_isolated_from_bundle(*args) do |runner|
        bundler_version = `bundle -v`.sub(/Bundler version /, '')

        if bundler_version !~ /^1\./
          puts 'Installing Bundler 1.x...'
          system('gem', 'install', 'bundler', '-v', '~> 1')
        end

        runner.command_prefix = 'bundle exec'
        runner.env['BUNDLE_GEMFILE'] = fs.find_in_project('Gemfile').to_s

        yield runner if block_given?
      end
    end

    def run_command_within_bundle!(*args)
      run_command_within_bundle(*args) do |runner|
        runner.run_successfully = true
        yield runner if block_given?
      end
    end

    def run_rake_tasks(*tasks)
      options = tasks.last.is_a?(Hash) ? tasks.pop : {}
      args = ['rake', *tasks, '--trace'] + [options]
      run_command_within_bundle(*args)
    end

    def run_rake_tasks!(*tasks)
      options = tasks.last.is_a?(Hash) ? tasks.pop : {}
      args = ['rake', *tasks, '--trace'] + [options]
      run_command_within_bundle!(*args)
    end
  end
end
