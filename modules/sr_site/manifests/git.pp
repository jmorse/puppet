# NB: a lot of configuration here is related to the old lumps of code SR used
# to generate RSS feeds for pushes/commits, which were replaced by Gerrit, and
# are thus commented out.

class sr_site::git($git_root) {
  # Git package is installed in the kickstart file,

  # Ldapres defaults,
#  Ldapres {
#    binddn => 'cn=Manager,o=sr',
#    bindpw => extlookup('ldap_manager_pw'),
#    ldapserverhost => 'localhost',
#    ldapserverport => '389',
#    require => Class['ldap'],
#  }

#  ldapres {"cn=git-admin,${openldap::groupdn}":
#    ensure => present,
#    cn => 'git-admin',
#    objectclass => 'posixGroup',
#    gidnumber => '3076',
#    # Don't configure memberuid
#    notify => Exec['ldap-groups-flushed'],
#  }

#  ldapres {"cn=git-commit,${openldap::groupdn}":
#    ensure => present,
#    cn => 'git-commit',
#    objectclass => 'posixGroup',
#    gidnumber => '3075',
#    # Don't configure memberuid
#    notify => Exec['ldap-groups-flushed'],
#  }

  # A user for git tasks to be run as.
  user { 'git':
    ensure => present,
    comment => 'Owner of git maintenence scripts and cron jobs',
    shell => '/sbin/nologin',
    gid => 'users', # Dummy group, I've no idea what it should be in.
    home => '/'
  }

  if !$devmode {
    # On a production machine, the dir /srv/git/scripts will already exist
    # as a matter of course (because git is stored on said production machine)
    cron { 'cgit-reconf':
      command => '/srv/git/scripts/cgit-reconf',
      hour => '*/4',
      minute => '13',
      user => 'git',
      require => Package['GitPython'],
    }
  } else {
    # On a dev machine, the scripts repo needs to be checked out manually.
    cron { 'cgit-reconf':
      command => '/srv/git/scripts/cgit-reconf',
      hour => '*/4',
      minute => '13',
      user => 'git',
      require => [Vcsrepo['/srv/git/scripts'], Package['GitPython']],
    }
  }

  # Ensure the git serving dir exists
  $git_dir = '/srv/git'
  file { $git_dir:
    ensure => directory,
    owner => 'gerrit',
    group => 'users',
    mode => '0755',
    require => User['gerrit'],
  }

  # Our custom cgit logo
  file { "${git_dir}/srgit.png":
    ensure => 'file',
    owner => 'gerrit',
    group => 'users',
    mode => '0644',
    source => 'puppet:///modules/sr_site/srgit.png',
    require => File[$git_dir],
  }


  # Maintain a clone of the git admin scripts.
  if $devmode {
    vcsrepo { '/srv/git/scripts':
      ensure => present,
      provider => git,
      source => "${git_root}/scripts",
      revision => 'origin/master',
      owner => 'gerrit',
      group => 'users',
      require => [File['/srv/git'], Exec['ldap-groups-flushed']],
    }
  }

  package { 'GitPython':
    ensure => present,
  }

#  package { 'python-pyrss2gen.noarch':
#    ensure => present,
#    provider => rpm,
#    source => '/root/python-pyrss2gen.noarch.rpm',
#   }

#  file { '/root/python-pyrss2gen.noarch.rpm':
#    ensure => present,
#    owner => 'root',
#    mode => '0400',
#    source => 'puppet:///modules/sr_site/python-pyrss2gen-1.0.0-2.2.noarch.rpm',
#    before => Package['python-pyrss2gen.noarch'],
#  }

#  cron { 'commitrss':
#    command => '/srv/git/scripts/rss',
#    minute => '*/15',
#    user => 'git',
#    require => [Vcsrepo['/srv/git/scripts'], Package['GitPython','python-pyrss2gen.noarch']],
#  }

#  cron { 'pushrss':
#    command => '/srv/git/scripts/pushlog-rss',
#    minute => '10',
#    user => 'git',
#    require => [Vcsrepo['/srv/git/scripts'], Package['GitPython','python-pyrss2gen.noarch']],
#  }

#  file { '/srv/git/commits.rss':
#    ensure => present,
#    owner => 'git',
#    group => 'srusers',
#    mode => '0644',
#    before => Vcsrepo['/srv/git/scripts'],
#  }

#  file { '/srv/git/pushes.rss':
#    ensure => present,
#    owner => 'git',
#    group => 'srusers',
#    mode => '0644',
#    before => Vcsrepo['/srv/git/scripts'],
#  }

#  file { '/srv/git/push-log':
#    ensure => present,
#    owner => 'root',
#    group => 'git-commit',
#    mode => '0664',
#    before => Vcsrepo['/srv/git/scripts'],
#  }

#  file { '/srv/git/update-log':
#    ensure => present,
#    owner => 'root',
#    group => 'git-commit',
#    mode => '0664',
#    before => Vcsrepo['/srv/git/scripts'],
#  }

#  file { '/srv/git/repolist':
#    ensure => present,
#    owner => 'root',
#    group => 'git-admin',
#    mode => '0664',
#    before => Vcsrepo['/srv/git/scripts'],
#    require => Exec['ldap-groups-flushed'],
#  }

  # The cgit package is a decent repo explorer / gui, see srobo.org/cgit
  package { 'cgit':
    ensure => present,
  }

  # Config file for serving our repos; no contents provided, because they're
  # auto generated by the cgit-reconf cron job.
  file { '/etc/cgitrc':
    ensure => present,
    owner => 'git',
    group => 'root',
    mode => '0644',
    require => [Package['cgit'], Exec['ldap-groups-flushed']],
  }

#  package { ['perl', 'perl-RPC-XML']:
#    ensure => present,
#  }
}
