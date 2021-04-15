#!/opt/puppetlabs/puppet/bin/ruby

#require 'highline'
require 'yaml'


# cli = HighLine.new
# answer = cli.ask "Is this for Puppet Enterprise?(y/n)"

# klass = answer.eql?('n') ? 'r10k' : 'puppet_enterprise::master::code_manager'
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end
end

# @return [Hash]
# @example remote_branches(origin) => {production => {
# type => 'git', 'remote' => 'git@github.com/puppetlabs/control_repo.git',
# 'ref' => 'production'}}
def remote_branches(remote = 'origin')
  lines = `git ls-remote --heads #{remote}`.lines
  remote_url = `git remote get-url #{remote}`.chomp.strip
  # Example output
  # 340a793c2cc6079a174ee6dea2aadc694467d216        refs/heads/main
  # 4c994f3199030961dfd9a09ab51f348d7b444b8a        refs/heads/production
  lines.each_with_object({}) do |line, yaml|
    ref, name = line.chomp.split("\t")
    ref_name = name.split('refs/heads/').last
    yaml[ref_name] = {
      'type' => 'git',
      'remote' => remote_url,
      'ref' => ref_name,
    }
    yaml
  end
end

output = <<~HELP

This script produces the enviornments.yaml file content necessary#{' '}
for r10k dynamic yaml environment setup. The current git branches#{' '}
will be mapped to yaml environments.#{' '}

You can should redirect the output of this script to a environments.yaml file.
Follow these steps:

1. ruby #{__FILE__} [remote] > /etc/puppetlabs/r10k/environments.yaml

After placing the environments.yaml in /etc/puppetlabs/r10k/environments.yaml
on the primary and/or replica puppetservers.

2. Add the following hiera data to your common.yaml

puppet_enterprise::master::code_manager::sources:
  puppet:
    remote: 'N/A'
    type: yaml
    config: '/etc/puppetlabs/r10k/environments.yaml'
  git:
    remote: 'git@gitlab.com:the-guild-group/puppet-control-repo.git'
    type: git
    prefix: true#{'  '}
    ignore_branch_prefixes:
      - 'main'

3. Once the environments.yaml file and hiera data is in place run puppet on your
   r10k/code manager host.

4. Next run puppet code deploy --all -w#{' '}
5. Verify deployment was successful
6. Add new environments to environments.yaml and redeploy
HELP

default_remote = ARGV.first || 'origin'

$stderr.puts(output.yellow)
puts remote_branches(default_remote).to_yaml
