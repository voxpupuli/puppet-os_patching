require 'spec_helper'

describe 'os_patching' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      case os_facts[:kernel]
      when 'Linux', 'FreeBSD'
        let(:cache_dir) { '/var/cache/os_patching' }
        let(:fact_cmd) { '/usr/local/bin/os_patching_fact_generation.sh' }

        context 'default installation path for Puppet' do
          # rubocop:disable Style/StringLiterals
          it {
            is_expected.to contain_exec('os_patching::exec::fact_upload').with(
              'command' => "\"/usr/local/bin/puppet\" facts upload",
            )
          }
          # rubocop:enable Style/StringLiterals
        end

        context 'alternate installation path for Puppet' do
          let(:params) { {'puppet_binary' => '/opt/local/bin/puppet' } }

          # rubocop:disable Style/StringLiterals
          it {
            is_expected.to contain_exec('os_patching::exec::fact_upload').with(
              'command' => "\"/opt/local/bin/puppet\" facts upload",
            )
          }
          # rubocop:enable Style/StringLiterals
        end
      when 'windows'
        let(:cache_dir) { 'C:/ProgramData/os_patching' }
        let(:fact_cmd) { 'C:/ProgramData/os_patching/os_patching_fact_generation.ps1' }

        context 'default installation path for Puppet' do
          # rubocop:disable Style/StringLiterals
          it {
            is_expected.to contain_exec('os_patching::exec::fact_upload').with(
              'command' => "\"C:/Program Files/Puppet Labs/Puppet/bin/puppet.bat\" facts upload",
            )
          }
          # rubocop:enable Style/StringLiterals
        end

        context 'alternate installation path for Puppet' do
          let(:params) { {'puppet_binary' => 'D:/Program Files/Puppet Labs/Puppet/bin/puppet.bat' } }

          # rubocop:disable Style/StringLiterals
          it {
            is_expected.to contain_exec('os_patching::exec::fact_upload').with(
              'command' => "\"D:/Program Files/Puppet Labs/Puppet/bin/puppet.bat\" facts upload",
            )
          }
          # rubocop:enable Style/StringLiterals
        end
      end

      case os_facts[:osfamily]
      when 'RedHat'
        context 'with package management enabled' do
          let(:params) {
            {
              'manage_yum_utils'           => true,
              'manage_delta_rpm'           => true,
              'manage_yum_plugin_security' => true,
            }
          }
          if os_facts[:os]['release']['major'] == '8'
            it { is_expected.to contain_package('drpm') }
          else
            it { is_expected.to contain_package('deltarpm') }
          end
          it { is_expected.to contain_package('yum-utils') }
          it { is_expected.to contain_package('yum-plugin-security') }
        end
        context 'with package management default' do
          if os_facts[:os]['release']['major'] == '8'
            it { is_expected.not_to contain_package('drpm') }
          else
            it { is_expected.not_to contain_package('deltarpm') }
          end
          it { is_expected.not_to contain_package('yum-utils') }
          it { is_expected.not_to contain_package('yum-plugin-security') }
        end
      end

      case os_facts[:osfamily]
      when 'Debian'
        context 'with apt_autoremove => true' do
          let(:params) { {'apt_autoremove' => true } }
          it { is_expected.to contain_cron('Run apt autoremove on reboot').with_ensure('present') }
        end
        context 'with apt_autoremove => default' do
          it { is_expected.to contain_cron('Run apt autoremove on reboot').with_ensure('absent') }
        end
      end

      context 'with block_patching_on_warnings => true' do
        let(:params) { {'block_patching_on_warnings' => true } }
        it { is_expected.to contain_file("#{cache_dir}/block_patching_on_warnings").with({
          'ensure' => 'file',
        })}
      end

      context 'with block_patching_on_warnings => false' do
        let(:params) { {'block_patching_on_warnings' => false } }
        it { is_expected.to contain_file("#{cache_dir}/block_patching_on_warnings").with({
          'ensure' => 'absent',
        })}
      end

      context 'with block_patching_on_warnings => default' do
        it { is_expected.to contain_file("#{cache_dir}/block_patching_on_warnings").with({
          'ensure' => 'absent',
        })}
      end

      context 'with reboot_override => always' do
        let(:params) { {'reboot_override' => 'always'} }
        it { is_expected.to contain_file("#{cache_dir}/reboot_override").with({
          'ensure' => 'file',
        })}
        it { is_expected.to contain_file("#{cache_dir}/reboot_override").with_content(/^always$/)}
      end

      context 'with reboot_override => never' do
        let(:params) { {'reboot_override' => 'never'} }
        it { is_expected.to contain_file("#{cache_dir}/reboot_override").with({
          'ensure' => 'file',
        })}
        it { is_expected.to contain_file("#{cache_dir}/reboot_override").with_content(/^never$/)}
      end

      context 'with reboot_override => foobar' do
        let(:params) { {'reboot_override' => 'foobar'} }
        it { is_expected.to compile.and_raise_error(/reboot_override/) }
      end

      context 'with patch_window => $#&!RYYQ!' do
        let(:params) { {'patch_window' => '(((((##(@(!$#&!RYYQ!'} }
        it { is_expected.to compile }
      end

      context 'with patch_window => Week3' do
        let(:params) { {'patch_window' => 'Week3'} }
        it { is_expected.to contain_file(cache_dir + '/patch_window').with({
          'ensure' => 'file',
        })}
        it { is_expected.to contain_file(cache_dir + '/patch_window').with_content(/^Week3$/)}
      end

      context 'with pre_patching_command => /bin/true' do
        let(:params) { {'pre_patching_command' => '/bin/true'} }
        it { is_expected.to contain_file(cache_dir + '/pre_patching_command').with({
          'ensure' => 'file',
        })}
        it { is_expected.to contain_file(cache_dir + '/pre_patching_command').with_content(/^\/bin\/true$/)}
      end

      context 'with pre_patching_command => undef' do
        let(:params) { {'pre_patching_command' => :undef } }
        it { is_expected.to contain_file(cache_dir + '/pre_patching_command').with({
          'ensure' => 'absent',
        })}
      end

      context 'with blackout window set' do
        let(:params) {
          {
            'blackout_windows' => { 'End of year change freeze': { 'start': '2018-12-15T00:00:00+10:00', 'end': '2019-01-15T23:59:59+10:00' } }
          }
        }
        it { is_expected.to contain_file(cache_dir + '/blackout_windows').with({
          'ensure' => 'file',
        })}
        it { is_expected.to contain_file(cache_dir + '/blackout_windows').with_content(/End of year change/)}
      end

      it { is_expected.to compile }
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('os_patching') }
      it { is_expected.to contain_file(cache_dir).with({
        'ensure' => 'directory',
      })}

      it { is_expected.to contain_file(cache_dir + '/blackout_windows').with({
        'ensure' => 'absent',
      })}

      it { is_expected.to contain_file(cache_dir + '/patch_window').with({
        'ensure' => 'absent',
      })}

      it { is_expected.to contain_file(cache_dir + '/reboot_override').with({
        'ensure' => 'file',
      })}

      it { is_expected.to contain_file(cache_dir + '/reboot_override').with_content(/^default$/)}

      it { is_expected.to contain_file(fact_cmd).with({
        'ensure' => 'file',
      })}

      case os_facts[:kernel]
      when 'Linux'
        it { is_expected.to contain_cron('Cache patching data').with_ensure('present') }
        it { is_expected.to contain_cron('Cache patching data at reboot').with_ensure('present') }
        it { is_expected.to contain_exec('os_patching::exec::fact').that_requires(
          'File[' + cache_dir + '/reboot_override]',
        )}
      end
      it { is_expected.to contain_exec('os_patching::exec::fact') }
      it { is_expected.to contain_exec('os_patching::exec::fact_upload') }

      context 'block on warnings' do
        let(:params) { { 'block_patching_on_warnings' => true } }
        it { is_expected.to contain_file(cache_dir + '/block_patching_on_warnings') }
      end

      case os_facts[:osfamily]
      when 'Debian'
        context 'debian reboot' do
          let(:params) { { 'apt_autoremove' => true } }
          it { is_expected.to contain_cron('Run apt autoremove on reboot').with_ensure('present') }
        end
      end

      context 'purge module' do
        let(:params) { {'ensure' => 'absent'} }
        it { is_expected.to contain_file(cache_dir).with({
          'ensure' => 'absent',
        })}
      end
    end
  end
end
