cache_dir = '/var/cache/os_patching'

pp_class_base = <<-PUPPETCODE
    class { 'cron':
      manage_service => false,
    }
    class { 'os_patching':
      fact_upload => false,
    }
PUPPETCODE

pp_class_patch_window = <<-PUPPETCODE
    class { 'cron':
      manage_service => false,
    }
    class { 'os_patching':
      patch_window => 'Week1',
      fact_upload  => false,
    }
PUPPETCODE

pp_class_blackout_window = <<-PUPPETCODE
    class { 'cron':
      manage_service => false,
    }
    class { 'os_patching':
      blackout_windows => { 'End of year change freeze' => { 'start' => '2018-12-15T00:00:00+10:00', 'end' => '2030-01-15T23:59:59+10:00' }},
      fact_upload => false,
    }
PUPPETCODE

pp_class_absent = <<-PUPPETCODE
    class { 'os_patching':
      ensure      => absent,
    }
PUPPETCODE

describe 'os_patching module' do
  context 'base class' do
    it do
      idempotent_apply(pp_class_base)
      expect(file(cache_dir)).to be_directory
      expect(file(cache_dir + '/security_package_updates')).to be_file
      expect(file(cache_dir + '/package_updates')).to be_file
      expect(file(cache_dir + '/apps_to_restart')).to be_file
      expect(file(cache_dir + '/reboot_required')).to be_file
      expect(file(cache_dir + '/reboot_override')).to be_file
      expect(file(cache_dir + '/blackout_windows')).not_to be_file
      expect(file(cache_dir + '/patch_window')).not_to be_file
      expect(file('/usr/local/bin/os_patching_fact_generation.sh')).to be_file
      if host_inventory['facter']['os']['name'] == 'CentOS' || host_inventory['facter']['os']['name'] == 'Ubuntu'
        run_bolt_task('os_patching::clean_cache')
        run_bolt_task('os_patching::refresh_fact')
      end
    end
  end
end

describe 'os_patching module with blackout window' do
  context 'base class' do
    it do
      idempotent_apply(pp_class_blackout_window)
      expect(file(cache_dir)).to be_directory
      expect(file(cache_dir + '/security_package_updates')).to be_file
      expect(file(cache_dir + '/package_updates')).to be_file
      expect(file(cache_dir + '/apps_to_restart')).to be_file
      expect(file(cache_dir + '/reboot_required')).to be_file
      expect(file(cache_dir + '/reboot_override')).to be_file
      expect(file(cache_dir + '/blackout_windows')).to be_file
      expect(file(cache_dir + '/blackout_windows')).to contain (/End of year/)
      expect(file(cache_dir + '/patch_window')).not_to be_file
      expect(file('/usr/local/bin/os_patching_fact_generation.sh')).to be_file
      expect { run_bolt_task('os_patching::patch_server') }.to raise_error(/Patching blocked/)
    end
  end
end

describe 'os_patching module with patching window' do
  context 'base class' do
    it do
      idempotent_apply(pp_class_patch_window)
      expect(file(cache_dir)).to be_directory
      expect(file(cache_dir + '/security_package_updates')).to be_file
      expect(file(cache_dir + '/package_updates')).to be_file
      expect(file(cache_dir + '/apps_to_restart')).to be_file
      expect(file(cache_dir + '/reboot_required')).to be_file
      expect(file(cache_dir + '/reboot_override')).to be_file
      expect(file(cache_dir + '/blackout_windows')).not_to be_file
      expect(file(cache_dir + '/patch_window')).to be_file
      expect(file(cache_dir + '/patch_window')).to contain (/Week1/)
      expect(file('/usr/local/bin/os_patching_fact_generation.sh')).to be_file
    end
  end
end

describe 'os_patching module purge' do
  context 'base class' do
    it do
      idempotent_apply(pp_class_absent)
      expect(file(cache_dir)).not_to be_directory
      expect(file('/usr/local/bin/os_patching_fact_generation.sh')).not_to be_file
    end
  end
end
