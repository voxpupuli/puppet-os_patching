# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v2.0.0](https://github.com/voxpupuli/puppet-os_patching/tree/v2.0.0) (2025-11-13)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v1.0.0...v2.0.0)

**Breaking changes:**

- feat: add group and batch patching [\#255](https://github.com/voxpupuli/puppet-os_patching/pull/255) ([rwaffen](https://github.com/rwaffen))

**Merged pull requests:**

- chore: remove obsolete configuration [\#259](https://github.com/voxpupuli/puppet-os_patching/pull/259) ([rwaffen](https://github.com/rwaffen))

## [v1.0.0](https://github.com/voxpupuli/puppet-os_patching/tree/v1.0.0) (2025-11-06)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.23.0...v1.0.0)

**Breaking changes:**

- chore: update dependency version requirements and OS support in metadata.json, Drop all EOL OSes, switch requirements to OpenVox 8 [\#254](https://github.com/voxpupuli/puppet-os_patching/pull/254) ([rwaffen](https://github.com/rwaffen))

**Closed issues:**

- renaming repo [\#246](https://github.com/voxpupuli/puppet-os_patching/issues/246)
- Migrate to Vox Pupuli? [\#242](https://github.com/voxpupuli/puppet-os_patching/issues/242)

**Merged pull requests:**

- fix: replace egrep with grep -E for el10 compatibility [\#257](https://github.com/voxpupuli/puppet-os_patching/pull/257) ([davemcdonnell](https://github.com/davemcdonnell))
- Fix tests [\#253](https://github.com/voxpupuli/puppet-os_patching/pull/253) ([rwaffen](https://github.com/rwaffen))
- chore: prepare module for updated voxpupuli config after modulesync [\#251](https://github.com/voxpupuli/puppet-os_patching/pull/251) ([rwaffen](https://github.com/rwaffen))
- remove codeowners file [\#249](https://github.com/voxpupuli/puppet-os_patching/pull/249) ([rwaffen](https://github.com/rwaffen))
- fix: correct syntax for blackout\_windows hash in init.pp [\#248](https://github.com/voxpupuli/puppet-os_patching/pull/248) ([rwaffen](https://github.com/rwaffen))
- feat: prepare rename repo, update to voxpupuli in metadata [\#247](https://github.com/voxpupuli/puppet-os_patching/pull/247) ([rwaffen](https://github.com/rwaffen))
- feat: add transfer note, delete .sync.yml, change refs to voxpupuli in readme [\#245](https://github.com/voxpupuli/puppet-os_patching/pull/245) ([rwaffen](https://github.com/rwaffen))
- fix README and REFERENCE not adhering to Puppet Code or ISO8601 [\#241](https://github.com/voxpupuli/puppet-os_patching/pull/241) ([LirionOSS](https://github.com/LirionOSS))

## [v0.23.0](https://github.com/voxpupuli/puppet-os_patching/tree/v0.23.0) (2025-08-04)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.22.0...v0.23.0)

## [v0.22.0](https://github.com/voxpupuli/puppet-os_patching/tree/v0.22.0) (2025-02-26)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.21.0...v0.22.0)

**Implemented enhancements:**

- If the lock file tracks a non-real process clean it up [\#239](https://github.com/voxpupuli/puppet-os_patching/pull/239) ([jcpunk](https://github.com/jcpunk))
- Prevent cronjob from having output [\#238](https://github.com/voxpupuli/puppet-os_patching/pull/238) ([jcpunk](https://github.com/jcpunk))
- Fact generation json parse [\#232](https://github.com/voxpupuli/puppet-os_patching/pull/232) ([FrankVanDamme](https://github.com/FrankVanDamme))

**Fixed bugs:**

- os\_patching\_fact\_generation.sh Script runs in nil:NilClass \(NoMethodError\) [\#226](https://github.com/voxpupuli/puppet-os_patching/issues/226)

**Merged pull requests:**

- Add comma and equals sign to yum regex [\#233](https://github.com/voxpupuli/puppet-os_patching/pull/233) ([Vincevrp](https://github.com/Vincevrp))

## [v0.21.0](https://github.com/voxpupuli/puppet-os_patching/tree/v0.21.0) (2023-07-18)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.20.1...v0.21.0)

**Implemented enhancements:**

- allow open source puppet to use os\_patching [\#215](https://github.com/voxpupuli/puppet-os_patching/issues/215)
- 215 allow puppet open source to work with os\_patching [\#231](https://github.com/voxpupuli/puppet-os_patching/pull/231) ([albatrossflavour](https://github.com/albatrossflavour))

**Fixed bugs:**

- \#229 fix syntax error [\#230](https://github.com/voxpupuli/puppet-os_patching/pull/230) ([albatrossflavour](https://github.com/albatrossflavour))

## [v0.20.1](https://github.com/voxpupuli/puppet-os_patching/tree/v0.20.1) (2023-07-18)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.20.0...v0.20.1)

**Fixed bugs:**

- Syntax error with 0.20.0? [\#229](https://github.com/voxpupuli/puppet-os_patching/issues/229)

## [v0.20.0](https://github.com/voxpupuli/puppet-os_patching/tree/v0.20.0) (2023-07-13)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.19.0...v0.20.0)

**Implemented enhancements:**

- stdlib 9.x.x compat [\#227](https://github.com/voxpupuli/puppet-os_patching/issues/227)
- \#227 Support for stdlib 9.x [\#228](https://github.com/voxpupuli/puppet-os_patching/pull/228) ([albatrossflavour](https://github.com/albatrossflavour))
- Add RHEL9 to supported OS [\#225](https://github.com/voxpupuli/puppet-os_patching/pull/225) ([tuxmea](https://github.com/tuxmea))
- \#217 add an apt update as part of the fact generation [\#224](https://github.com/voxpupuli/puppet-os_patching/pull/224) ([albatrossflavour](https://github.com/albatrossflavour))
- \#222 Update os\_patching\_fact\_generation.sh [\#223](https://github.com/voxpupuli/puppet-os_patching/pull/223) ([dpavlotzky](https://github.com/dpavlotzky))
- Don't record note from subscription-manager if enabled [\#221](https://github.com/voxpupuli/puppet-os_patching/pull/221) ([jcpunk](https://github.com/jcpunk))

**Fixed bugs:**

- Add correct reboot detection for RHEL 8 and 9 [\#220](https://github.com/voxpupuli/puppet-os_patching/pull/220) ([jcpunk](https://github.com/jcpunk))

**Merged pull requests:**

- fix issue \#211 [\#219](https://github.com/voxpupuli/puppet-os_patching/pull/219) ([brajjan](https://github.com/brajjan))
- Update Apt Support - Fixes \#217 [\#218](https://github.com/voxpupuli/puppet-os_patching/pull/218) ([AMDHome](https://github.com/AMDHome))

## [0.19.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.19.0) (2023-02-26)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.18.0...0.19.0)

**Implemented enhancements:**

- The os\_patching\_fact\_generation.sh does not run apt update [\#217](https://github.com/voxpupuli/puppet-os_patching/issues/217)
- Fix up the GitHub workflows [\#209](https://github.com/voxpupuli/puppet-os_patching/pull/209) ([albatrossflavour](https://github.com/albatrossflavour))

**Closed issues:**

- Regular expression does not capture all packages [\#222](https://github.com/voxpupuli/puppet-os_patching/issues/222)

## [0.18.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.18.0) (2022-08-08)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.17.0...0.18.0)

**Implemented enhancements:**

- updated RHEL regex to accommodate colon [\#216](https://github.com/voxpupuli/puppet-os_patching/pull/216) ([prolixalias](https://github.com/prolixalias))

**Fixed bugs:**

- Fact generation on RHEL incorrectly indicating no PKGS for update [\#212](https://github.com/voxpupuli/puppet-os_patching/issues/212)

**Merged pull requests:**

- adjust upper limit [\#214](https://github.com/voxpupuli/puppet-os_patching/pull/214) ([prolixalias](https://github.com/prolixalias))

## [v0.17.0](https://github.com/voxpupuli/puppet-os_patching/tree/v0.17.0) (2021-07-12)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/v0.16.0...v0.17.0)

**Fixed bugs:**

- create version 0.17 [\#207](https://github.com/voxpupuli/puppet-os_patching/issues/207)
- os\_patching\_fact\_generation.ps1 created without required permissions [\#206](https://github.com/voxpupuli/puppet-os_patching/issues/206)
- s/udpate/update [\#208](https://github.com/voxpupuli/puppet-os_patching/pull/208) ([noahbliss](https://github.com/noahbliss))
- ensure that key exists while parsing json [\#203](https://github.com/voxpupuli/puppet-os_patching/pull/203) ([maxadamo](https://github.com/maxadamo))

## [v0.16.0](https://github.com/voxpupuli/puppet-os_patching/tree/v0.16.0) (2021-05-21)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.15.0...v0.16.0)

**Implemented enhancements:**

- Hiera support [\#204](https://github.com/voxpupuli/puppet-os_patching/issues/204)
- Delta RPM doesn't exist on RHEL8, need to move to `drpm` [\#200](https://github.com/voxpupuli/puppet-os_patching/issues/200)
- scheduled task to run os\_patching\_fact\_generation.ps1 is hardcoded to every 12 hours [\#174](https://github.com/voxpupuli/puppet-os_patching/issues/174)
- Adding os\_patching class result in failed runs on all Windows nodes on first run [\#172](https://github.com/voxpupuli/puppet-os_patching/issues/172)
- Feature/204 hiera support [\#205](https://github.com/voxpupuli/puppet-os_patching/pull/205) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/200 deltarpm [\#201](https://github.com/voxpupuli/puppet-os_patching/pull/201) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/module hiera [\#199](https://github.com/voxpupuli/puppet-os_patching/pull/199) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/174 windows update param [\#197](https://github.com/voxpupuli/puppet-os_patching/pull/197) ([albatrossflavour](https://github.com/albatrossflavour))
- fix facter no longer working on puppet 7 [\#191](https://github.com/voxpupuli/puppet-os_patching/pull/191) ([maxadamo](https://github.com/maxadamo))
- Working on \#180 : Adding rescue to allow code to continue after NoMet… [\#181](https://github.com/voxpupuli/puppet-os_patching/pull/181) ([sharumpe](https://github.com/sharumpe))
- Change yum check-update to include valid entries instead of exclude invalid [\#175](https://github.com/voxpupuli/puppet-os_patching/pull/175) ([freiheit](https://github.com/freiheit))
- Do not hardcode the path of AIO commands [\#168](https://github.com/voxpupuli/puppet-os_patching/pull/168) ([smortex](https://github.com/smortex))
- Improve os\_patching::patch\_after\_healthcheck plan [\#167](https://github.com/voxpupuli/puppet-os_patching/pull/167) ([kreeuwijk](https://github.com/kreeuwijk))
- Update README.md [\#162](https://github.com/voxpupuli/puppet-os_patching/pull/162) ([ldaneliukas](https://github.com/ldaneliukas))

**Fixed bugs:**

- undefined method `match' for nil:NilClass \(NoMethodError\) [\#202](https://github.com/voxpupuli/puppet-os_patching/issues/202)
- Locked Log file on Windows [\#186](https://github.com/voxpupuli/puppet-os_patching/issues/186)
- puppetlabs-translate deprecated [\#189](https://github.com/voxpupuli/puppet-os_patching/pull/189) ([binford2k](https://github.com/binford2k))
- expand filter inline and remove $FILTER variables [\#188](https://github.com/voxpupuli/puppet-os_patching/pull/188) ([johnson-m-d](https://github.com/johnson-m-d))
- Fixing failing development tests [\#179](https://github.com/voxpupuli/puppet-os_patching/pull/179) ([tamerz](https://github.com/tamerz))
- fix\(patch\_server\) change regex after yum history [\#171](https://github.com/voxpupuli/puppet-os_patching/pull/171) ([bmx0r](https://github.com/bmx0r))
- Inconsistence between facter and manifest [\#164](https://github.com/voxpupuli/puppet-os_patching/pull/164) ([elfranne](https://github.com/elfranne))

## [0.15.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.15.0) (2021-05-11)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.14.0...0.15.0)

**Implemented enhancements:**

- long usernames in `yum history` cause 'yum did not appear to run' [\#192](https://github.com/voxpupuli/puppet-os_patching/issues/192)
- facter -p no longer supported with Puppet 7 [\#190](https://github.com/voxpupuli/puppet-os_patching/issues/190)
- --nodes is deprecated [\#165](https://github.com/voxpupuli/puppet-os_patching/issues/165)
- v0.15.0 release [\#196](https://github.com/voxpupuli/puppet-os_patching/pull/196) ([albatrossflavour](https://github.com/albatrossflavour))

**Fixed bugs:**

- NoMethodError in os\_patching\_fact\_generation.sh [\#180](https://github.com/voxpupuli/puppet-os_patching/issues/180)

**Closed issues:**

- "Security:" filter ineffective [\#187](https://github.com/voxpupuli/puppet-os_patching/issues/187)

## [0.14.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.14.0) (2021-05-09)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.12.0...0.14.0)

**Implemented enhancements:**

- Enable a pre-patching command to be specified [\#159](https://github.com/voxpupuli/puppet-os_patching/issues/159)
- \#149 allow Debian to run `apt-get autoremove` at reboot [\#151](https://github.com/voxpupuli/puppet-os_patching/pull/151) ([albatrossflavour](https://github.com/albatrossflavour))
- Toggle to allow warnings to block patching \#143 [\#150](https://github.com/voxpupuli/puppet-os_patching/pull/150) ([albatrossflavour](https://github.com/albatrossflavour))
- Updates to facter and bug fixes [\#148](https://github.com/voxpupuli/puppet-os_patching/pull/148) ([albatrossflavour](https://github.com/albatrossflavour))
- Force usage of the 'C' locale [\#142](https://github.com/voxpupuli/puppet-os_patching/pull/142) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- \#148 ensure versionlock file is there before we read it [\#154](https://github.com/voxpupuli/puppet-os_patching/pull/154) ([albatrossflavour](https://github.com/albatrossflavour))
- Prevent error message to stderr on RedHat [\#153](https://github.com/voxpupuli/puppet-os_patching/pull/153) ([smortex](https://github.com/smortex))
- Bugfix: Add missing dependency [\#144](https://github.com/voxpupuli/puppet-os_patching/pull/144) ([theosotr](https://github.com/theosotr))
- The declared ISO format does not exist, had one extra `dd` [\#141](https://github.com/voxpupuli/puppet-os_patching/pull/141) ([rnelson0](https://github.com/rnelson0))

**Closed issues:**

- Fact generation misses Debian security packages [\#184](https://github.com/voxpupuli/puppet-os_patching/issues/184)
- Unable to fetch some archives [\#177](https://github.com/voxpupuli/puppet-os_patching/issues/177)

**Merged pull requests:**

- Litmus updates and pre-v0.14.0 work [\#195](https://github.com/voxpupuli/puppet-os_patching/pull/195) ([albatrossflavour](https://github.com/albatrossflavour))
- Master release - bug fixes and travis  [\#183](https://github.com/voxpupuli/puppet-os_patching/pull/183) ([albatrossflavour](https://github.com/albatrossflavour))
- Fix issues with empty pre\_patching\_command entries [\#161](https://github.com/voxpupuli/puppet-os_patching/pull/161) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge to production [\#160](https://github.com/voxpupuli/puppet-os_patching/pull/160) ([albatrossflavour](https://github.com/albatrossflavour))
- clear out 'Obsoleting' entries [\#158](https://github.com/voxpupuli/puppet-os_patching/pull/158) ([kreeuwijk](https://github.com/kreeuwijk))

## [0.12.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.12.0) (2019-08-21)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.11.1...0.12.0)

**Implemented enhancements:**

- add flag to run "apt-get autoremove" after patching on ubuntu servers [\#149](https://github.com/voxpupuli/puppet-os_patching/issues/149)
- Add a list of required KBs to the os\_patching fact on windows [\#145](https://github.com/voxpupuli/puppet-os_patching/issues/145)
- Create the wiki and populate some how to guides [\#128](https://github.com/voxpupuli/puppet-os_patching/issues/128)
- Timeouts on os\_patching\_fact\_generation.sh? [\#94](https://github.com/voxpupuli/puppet-os_patching/issues/94)

**Fixed bugs:**

- Travis tests taking too long [\#138](https://github.com/voxpupuli/puppet-os_patching/issues/138)
- Version 0.11.1 of module cannot be installed on Windows \(via Agent\) [\#136](https://github.com/voxpupuli/puppet-os_patching/issues/136)
- Unable to run task os\_patching::patch\_server Windows 2012r2 with puppet enterprise agent 6.4.2 [\#133](https://github.com/voxpupuli/puppet-os_patching/issues/133)
- \#138 - fix travis issues [\#139](https://github.com/voxpupuli/puppet-os_patching/pull/139) ([albatrossflavour](https://github.com/albatrossflavour))

**Merged pull requests:**

- V0.12.0 release [\#152](https://github.com/voxpupuli/puppet-os_patching/pull/152) ([albatrossflavour](https://github.com/albatrossflavour))
- V0.11.2 release [\#140](https://github.com/voxpupuli/puppet-os_patching/pull/140) ([albatrossflavour](https://github.com/albatrossflavour))
- \#136 add html to the pdkignore [\#137](https://github.com/voxpupuli/puppet-os_patching/pull/137) ([albatrossflavour](https://github.com/albatrossflavour))
- Issue/133 eventlog puppet agent 6.4.2 [\#134](https://github.com/voxpupuli/puppet-os_patching/pull/134) ([nathangiuliani](https://github.com/nathangiuliani))
- Updated ReadMe [\#131](https://github.com/voxpupuli/puppet-os_patching/pull/131) ([nathangiuliani](https://github.com/nathangiuliani))
- \#129 restrictions on stdlib are too tight [\#130](https://github.com/voxpupuli/puppet-os_patching/pull/130) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.11.1](https://github.com/voxpupuli/puppet-os_patching/tree/0.11.1) (2019-05-07)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.11.0...0.11.1)

**Implemented enhancements:**

- Update the README to show the windows paths too [\#127](https://github.com/voxpupuli/puppet-os_patching/issues/127)

**Fixed bugs:**

- puppetlabs/stdlib version 5.2.0 [\#129](https://github.com/voxpupuli/puppet-os_patching/issues/129)

**Merged pull requests:**

- V0.11.1 release to master [\#132](https://github.com/voxpupuli/puppet-os_patching/pull/132) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.11.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.11.0) (2019-05-03)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.10.0...0.11.0)

**Implemented enhancements:**

- Add litmus tests to run the tasks and validate the results [\#124](https://github.com/voxpupuli/puppet-os_patching/issues/124)
- Enable windows support for the manifests and facter [\#120](https://github.com/voxpupuli/puppet-os_patching/issues/120)

**Merged pull requests:**

- v0.11.0 release [\#126](https://github.com/voxpupuli/puppet-os_patching/pull/126) ([albatrossflavour](https://github.com/albatrossflavour))
- \#124 promote new tests to development [\#125](https://github.com/voxpupuli/puppet-os_patching/pull/125) ([albatrossflavour](https://github.com/albatrossflavour))
- Release to production in preparation for V0.11.0 release [\#123](https://github.com/voxpupuli/puppet-os_patching/pull/123) ([albatrossflavour](https://github.com/albatrossflavour))
- Community information added [\#122](https://github.com/voxpupuli/puppet-os_patching/pull/122) ([albatrossflavour](https://github.com/albatrossflavour))
- Enable windows support [\#121](https://github.com/voxpupuli/puppet-os_patching/pull/121) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.10.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.10.0) (2019-04-26)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.9.0...0.10.0)

**Implemented enhancements:**

- Create example bolt plan for patching [\#117](https://github.com/voxpupuli/puppet-os_patching/issues/117)

**Merged pull requests:**

- Release to production [\#119](https://github.com/voxpupuli/puppet-os_patching/pull/119) ([albatrossflavour](https://github.com/albatrossflavour))
- Add example plan [\#118](https://github.com/voxpupuli/puppet-os_patching/pull/118) ([albatrossflavour](https://github.com/albatrossflavour))
- Resync development [\#116](https://github.com/voxpupuli/puppet-os_patching/pull/116) ([albatrossflavour](https://github.com/albatrossflavour))
- Switch over to litmus tests [\#114](https://github.com/voxpupuli/puppet-os_patching/pull/114) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/sles [\#113](https://github.com/voxpupuli/puppet-os_patching/pull/113) ([JakeTRogers](https://github.com/JakeTRogers))

## [0.9.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.9.0) (2019-04-26)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.8.0...0.9.0)

**Merged pull requests:**

- Merge Litmus and Suse to production [\#115](https://github.com/voxpupuli/puppet-os_patching/pull/115) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.8.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.8.0) (2019-01-24)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.7.0...0.8.0)

**Closed issues:**

- Why stdlib 5.0.0? [\#107](https://github.com/voxpupuli/puppet-os_patching/issues/107)
- Don't try to upload facts on puppet apply \(no agent\) [\#106](https://github.com/voxpupuli/puppet-os_patching/issues/106)

**Merged pull requests:**

- Changelog update [\#111](https://github.com/voxpupuli/puppet-os_patching/pull/111) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge to master [\#110](https://github.com/voxpupuli/puppet-os_patching/pull/110) ([albatrossflavour](https://github.com/albatrossflavour))
- Fact upload and stdlib fixes [\#109](https://github.com/voxpupuli/puppet-os_patching/pull/109) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/pdqtest [\#108](https://github.com/voxpupuli/puppet-os_patching/pull/108) ([albatrossflavour](https://github.com/albatrossflavour))
- Bugfix for filter code [\#105](https://github.com/voxpupuli/puppet-os_patching/pull/105) ([albatrossflavour](https://github.com/albatrossflavour))
- Bugfix/filter [\#104](https://github.com/voxpupuli/puppet-os_patching/pull/104) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge pull request \#102 from albatrossflavour/development [\#103](https://github.com/voxpupuli/puppet-os_patching/pull/103) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.7.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.7.0) (2018-12-09)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.6.4...0.7.0)

**Fixed bugs:**

- 3777 updates!? \(update check should only count stdout\) [\#99](https://github.com/voxpupuli/puppet-os_patching/issues/99)
- AIX - Error resolving os\_patching \(restrict away from AIX?\) [\#93](https://github.com/voxpupuli/puppet-os_patching/issues/93)
- json encoding issue [\#92](https://github.com/voxpupuli/puppet-os_patching/issues/92)

**Merged pull requests:**

- V0.7.0 release [\#102](https://github.com/voxpupuli/puppet-os_patching/pull/102) ([albatrossflavour](https://github.com/albatrossflavour))
- metadata updates prior to 0.7.0 release [\#101](https://github.com/voxpupuli/puppet-os_patching/pull/101) ([albatrossflavour](https://github.com/albatrossflavour))
- Additional filtering based on bug \#99 [\#100](https://github.com/voxpupuli/puppet-os_patching/pull/100) ([albatrossflavour](https://github.com/albatrossflavour))
- Add confine to facter [\#98](https://github.com/voxpupuli/puppet-os_patching/pull/98) ([albatrossflavour](https://github.com/albatrossflavour))
- filter out yum check-update security messages [\#97](https://github.com/voxpupuli/puppet-os_patching/pull/97) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge pull request \#87 from albatrossflavour/development [\#88](https://github.com/voxpupuli/puppet-os_patching/pull/88) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.6.4](https://github.com/voxpupuli/puppet-os_patching/tree/0.6.4) (2018-10-03)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.6.3...0.6.4)

**Merged pull requests:**

- Push to master \(0.6.4\) [\#87](https://github.com/voxpupuli/puppet-os_patching/pull/87) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge pull request \#85 from albatrossflavour/development [\#86](https://github.com/voxpupuli/puppet-os_patching/pull/86) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.6.3](https://github.com/voxpupuli/puppet-os_patching/tree/0.6.3) (2018-10-03)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.6.2...0.6.3)

**Merged pull requests:**

- V0.6.3 release [\#85](https://github.com/voxpupuli/puppet-os_patching/pull/85) ([albatrossflavour](https://github.com/albatrossflavour))
- Debian fact improvements [\#84](https://github.com/voxpupuli/puppet-os_patching/pull/84) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge pull request \#82 from albatrossflavour/development [\#83](https://github.com/voxpupuli/puppet-os_patching/pull/83) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.6.2](https://github.com/voxpupuli/puppet-os_patching/tree/0.6.2) (2018-10-03)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.6.1...0.6.2)

**Merged pull requests:**

- V0.6.2 release [\#82](https://github.com/voxpupuli/puppet-os_patching/pull/82) ([albatrossflavour](https://github.com/albatrossflavour))
- Enable security patching in debian again [\#81](https://github.com/voxpupuli/puppet-os_patching/pull/81) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge pull request \#79 from albatrossflavour/development [\#80](https://github.com/voxpupuli/puppet-os_patching/pull/80) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.6.1](https://github.com/voxpupuli/puppet-os_patching/tree/0.6.1) (2018-10-02)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.6.0...0.6.1)

**Merged pull requests:**

- Fix a couple of strings issues [\#79](https://github.com/voxpupuli/puppet-os_patching/pull/79) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge pull request \#77 from albatrossflavour/development [\#78](https://github.com/voxpupuli/puppet-os_patching/pull/78) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.6.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.6.0) (2018-10-02)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.5.0...0.6.0)

**Implemented enhancements:**

- \[enhancement\] consider validating incoming ISO-8601 timestamps for validity [\#69](https://github.com/voxpupuli/puppet-os_patching/issues/69)
- \[bug\] invalid times parsed from blackouts file silently ignored [\#67](https://github.com/voxpupuli/puppet-os_patching/issues/67)
- \[task\] move data to /var/cache [\#60](https://github.com/voxpupuli/puppet-os_patching/issues/60)
- \[enhancement\]\[sponsored\] fixup puppetstrings output and include REFERENCE.md [\#59](https://github.com/voxpupuli/puppet-os_patching/issues/59)
- \[testing\]\[sponsored\] need mock version of `puppet fact upload` [\#58](https://github.com/voxpupuli/puppet-os_patching/issues/58)
- \[testing\]\[sponsored\] acceptance tests [\#57](https://github.com/voxpupuli/puppet-os_patching/issues/57)
- \[feature\]\[sponsored\] package cleanup before   [\#55](https://github.com/voxpupuli/puppet-os_patching/issues/55)
- \[feature\]\[sponsored\] uninstall support [\#54](https://github.com/voxpupuli/puppet-os_patching/issues/54)
- stack trace when task run before setup complete [\#52](https://github.com/voxpupuli/puppet-os_patching/issues/52)

**Fixed bugs:**

- \[bug\] task fails to run on debian \[assign geoff\] [\#70](https://github.com/voxpupuli/puppet-os_patching/issues/70)
- \[bug\] script relies on /usr/local/bin/facter but it does not always exist [\#56](https://github.com/voxpupuli/puppet-os_patching/issues/56)
- Value type appears to be incorrect [\#48](https://github.com/voxpupuli/puppet-os_patching/issues/48)

**Closed issues:**

- manage yum-utils? [\#74](https://github.com/voxpupuli/puppet-os_patching/issues/74)
- \[bug\] blackout timezone example is wrong \[assigned geoff\] [\#66](https://github.com/voxpupuli/puppet-os_patching/issues/66)

**Merged pull requests:**

- Pull to master [\#77](https://github.com/voxpupuli/puppet-os_patching/pull/77) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/data parser [\#76](https://github.com/voxpupuli/puppet-os_patching/pull/76) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/clean cache [\#75](https://github.com/voxpupuli/puppet-os_patching/pull/75) ([albatrossflavour](https://github.com/albatrossflavour))
- remove all reference to /opt/puppetlabs/facter/facts.d/os\_patching.yaml [\#72](https://github.com/voxpupuli/puppet-os_patching/pull/72) ([GeoffWilliams](https://github.com/GeoffWilliams))
- Add acceptance testing, esure=\>absent, simplfify [\#71](https://github.com/voxpupuli/puppet-os_patching/pull/71) ([GeoffWilliams](https://github.com/GeoffWilliams))
- Add reference.md [\#65](https://github.com/voxpupuli/puppet-os_patching/pull/65) ([albatrossflavour](https://github.com/albatrossflavour))
- Bugfix/strings [\#64](https://github.com/voxpupuli/puppet-os_patching/pull/64) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/move cache [\#63](https://github.com/voxpupuli/puppet-os_patching/pull/63) ([albatrossflavour](https://github.com/albatrossflavour))
- Bugfix/facter path [\#62](https://github.com/voxpupuli/puppet-os_patching/pull/62) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/rpm attribute fix [\#61](https://github.com/voxpupuli/puppet-os_patching/pull/61) ([albatrossflavour](https://github.com/albatrossflavour))
- Warn user when task is not setup yet [\#53](https://github.com/voxpupuli/puppet-os_patching/pull/53) ([GeoffWilliams](https://github.com/GeoffWilliams))
- Merge pull request \#50 from albatrossflavour/development [\#51](https://github.com/voxpupuli/puppet-os_patching/pull/51) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.5.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.5.0) (2018-09-23)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.4.1...0.5.0)

**Merged pull requests:**

- Merge to master [\#50](https://github.com/voxpupuli/puppet-os_patching/pull/50) ([albatrossflavour](https://github.com/albatrossflavour))
- Change the way we handle reboot logic [\#49](https://github.com/voxpupuli/puppet-os_patching/pull/49) ([albatrossflavour](https://github.com/albatrossflavour))
- Resync to dev [\#47](https://github.com/voxpupuli/puppet-os_patching/pull/47) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.4.1](https://github.com/voxpupuli/puppet-os_patching/tree/0.4.1) (2018-09-16)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.4.0...0.4.1)

**Merged pull requests:**

- V0.4.1 [\#46](https://github.com/voxpupuli/puppet-os_patching/pull/46) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.4.0](https://github.com/voxpupuli/puppet-os_patching/tree/0.4.0) (2018-09-16)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.3.5...0.4.0)

**Implemented enhancements:**

- `packages_updated` does not show the kernel itself [\#29](https://github.com/voxpupuli/puppet-os_patching/issues/29)

**Fixed bugs:**

- Locked, Exiting - Need trap\(s\) if we have a lockfile \(/usr/local/bin/os\_patching\_fact\_generation.sh\) [\#42](https://github.com/voxpupuli/puppet-os_patching/issues/42)
- When os\_patching reports patches but there is not enough space to install them, it reports success [\#39](https://github.com/voxpupuli/puppet-os_patching/issues/39)
- When unreachable yumrepos are present, os\_patching does not restart properly [\#36](https://github.com/voxpupuli/puppet-os_patching/issues/36)
- When no disk space is left, os\_patching reports no patches to apply rather than an error [\#35](https://github.com/voxpupuli/puppet-os_patching/issues/35)

**Merged pull requests:**

- V0.4.0 release [\#45](https://github.com/voxpupuli/puppet-os_patching/pull/45) ([albatrossflavour](https://github.com/albatrossflavour))
- Add extra error checking for the patch execution [\#44](https://github.com/voxpupuli/puppet-os_patching/pull/44) ([albatrossflavour](https://github.com/albatrossflavour))
- Feature/facter error reporting [\#43](https://github.com/voxpupuli/puppet-os_patching/pull/43) ([albatrossflavour](https://github.com/albatrossflavour))
- regex ignores pkgs starting with uppercase or digits [\#41](https://github.com/voxpupuli/puppet-os_patching/pull/41) ([f3sty](https://github.com/f3sty))
- Bugfix/needs restarting improvements [\#38](https://github.com/voxpupuli/puppet-os_patching/pull/38) ([albatrossflavour](https://github.com/albatrossflavour))
- Prod release [\#34](https://github.com/voxpupuli/puppet-os_patching/pull/34) ([albatrossflavour](https://github.com/albatrossflavour))
- Fix parsing of install/installed [\#33](https://github.com/voxpupuli/puppet-os_patching/pull/33) ([albatrossflavour](https://github.com/albatrossflavour))
- Fix issue with parsing of installed/install output from yum [\#30](https://github.com/voxpupuli/puppet-os_patching/pull/30) ([albatrossflavour](https://github.com/albatrossflavour))
- Sync back to dev [\#28](https://github.com/voxpupuli/puppet-os_patching/pull/28) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.3.5](https://github.com/voxpupuli/puppet-os_patching/tree/0.3.5) (2018-08-16)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.3.4...0.3.5)

**Merged pull requests:**

- Pre-release updates [\#27](https://github.com/voxpupuli/puppet-os_patching/pull/27) ([albatrossflavour](https://github.com/albatrossflavour))
- Release to master [\#26](https://github.com/voxpupuli/puppet-os_patching/pull/26) ([albatrossflavour](https://github.com/albatrossflavour))
- Merge timeout fixes [\#25](https://github.com/voxpupuli/puppet-os_patching/pull/25) ([albatrossflavour](https://github.com/albatrossflavour))
- Resync to development [\#24](https://github.com/voxpupuli/puppet-os_patching/pull/24) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.3.4](https://github.com/voxpupuli/puppet-os_patching/tree/0.3.4) (2018-08-10)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.3.3...0.3.4)

**Merged pull requests:**

- Pre release updates [\#23](https://github.com/voxpupuli/puppet-os_patching/pull/23) ([albatrossflavour](https://github.com/albatrossflavour))
- Missed a new variable [\#22](https://github.com/voxpupuli/puppet-os_patching/pull/22) ([albatrossflavour](https://github.com/albatrossflavour))
- Remove shell commands as much as possible [\#21](https://github.com/voxpupuli/puppet-os_patching/pull/21) ([albatrossflavour](https://github.com/albatrossflavour))
- Ooops [\#20](https://github.com/voxpupuli/puppet-os_patching/pull/20) ([albatrossflavour](https://github.com/albatrossflavour))
- Add cron job to refresh cache at reboot [\#19](https://github.com/voxpupuli/puppet-os_patching/pull/19) ([albatrossflavour](https://github.com/albatrossflavour))
- Ensure we honour reboot\_override even if a reboot isn't required [\#18](https://github.com/voxpupuli/puppet-os_patching/pull/18) ([albatrossflavour](https://github.com/albatrossflavour))
- Secure the params a little more [\#17](https://github.com/voxpupuli/puppet-os_patching/pull/17) ([albatrossflavour](https://github.com/albatrossflavour))
- Updates to detect when reboots are required [\#16](https://github.com/voxpupuli/puppet-os_patching/pull/16) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.3.3](https://github.com/voxpupuli/puppet-os_patching/tree/0.3.3) (2018-08-09)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.3.2...0.3.3)

## [0.3.2](https://github.com/voxpupuli/puppet-os_patching/tree/0.3.2) (2018-08-09)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.3.1...0.3.2)

## [0.3.1](https://github.com/voxpupuli/puppet-os_patching/tree/0.3.1) (2018-08-09)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.2.1...0.3.1)

**Merged pull requests:**

- Resync to development [\#15](https://github.com/voxpupuli/puppet-os_patching/pull/15) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.2.1](https://github.com/voxpupuli/puppet-os_patching/tree/0.2.1) (2018-08-07)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.1.19...0.2.1)

**Implemented enhancements:**

- Major documentation update [\#14](https://github.com/voxpupuli/puppet-os_patching/pull/14) ([albatrossflavour](https://github.com/albatrossflavour))

**Fixed bugs:**

- rubocop [\#13](https://github.com/voxpupuli/puppet-os_patching/pull/13) ([albatrossflavour](https://github.com/albatrossflavour))
- Rubocop updates [\#12](https://github.com/voxpupuli/puppet-os_patching/pull/12) ([albatrossflavour](https://github.com/albatrossflavour))

**Merged pull requests:**

- Rubocop is on thin ice! [\#11](https://github.com/voxpupuli/puppet-os_patching/pull/11) ([albatrossflavour](https://github.com/albatrossflavour))
- rubocop updates [\#10](https://github.com/voxpupuli/puppet-os_patching/pull/10) ([albatrossflavour](https://github.com/albatrossflavour))
- Push to production [\#9](https://github.com/voxpupuli/puppet-os_patching/pull/9) ([albatrossflavour](https://github.com/albatrossflavour))
- Start/end times added and history file fixed [\#8](https://github.com/voxpupuli/puppet-os_patching/pull/8) ([albatrossflavour](https://github.com/albatrossflavour))
- Major update for all areas [\#7](https://github.com/voxpupuli/puppet-os_patching/pull/7) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.1.19](https://github.com/voxpupuli/puppet-os_patching/tree/0.1.19) (2018-07-09)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.1.17...0.1.19)

**Merged pull requests:**

- Feature/smarter tasks [\#6](https://github.com/voxpupuli/puppet-os_patching/pull/6) ([albatrossflavour](https://github.com/albatrossflavour))

## [0.1.17](https://github.com/voxpupuli/puppet-os_patching/tree/0.1.17) (2018-06-01)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/0.1.16...0.1.17)

## [0.1.16](https://github.com/voxpupuli/puppet-os_patching/tree/0.1.16) (2018-05-29)

[Full Changelog](https://github.com/voxpupuli/puppet-os_patching/compare/44fd883ad50bccbcd0843608f71b4e7499295af8...0.1.16)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
