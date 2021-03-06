# 'comp-api' is the web API to the SRComp library which contains information
# about the state of the competition

class www::comp_api ( $root_dir ) {

  # Containing folder
  file { $root_dir:
    ensure  => directory,
    force   => true,
    owner   => 'wwwcontent',
    group   => 'apache',
  }

  # Syslog configuration, using local1
  file { '/etc/rsyslog.d/comp-api.conf':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    source => 'puppet:///modules/www/comp-api-syslog.conf',
    notify => Service['rsyslog'],
    require => Package['rsyslog'],
  }

  # Checkout of the competition state
  $compstate_dir = "${root_dir}/compstate"
  $ref_compstate = $sr_site::srcomp::ref_compstate
  vcsrepo { $compstate_dir:
    ensure    => present,
    provider  => git,
    source    => $ref_compstate,
    owner     => 'srcomp',
    group     => 'apache',
    require   => [File[$root_dir],User['srcomp'],Vcsrepo[$ref_compstate]],
  }

  # Update trigger and lock files
  file { "${compstate_dir}/.update-pls":
    ensure  => present,
    owner   => 'srcomp',
    group   => 'apache',
    mode    => '0644',
    require => Vcsrepo[$compstate_dir],
  }
  # The lock file is writable by apache so it can get a lock on it
  file { "${compstate_dir}/.update-lock":
    ensure  => present,
    owner   => 'srcomp',
    group   => 'apache',
    mode    => '0664',
    require => Vcsrepo[$compstate_dir],
  }

  # A WSGI config file for serving inside of apache.
  file { "${root_dir}/comp-api.wsgi":
    ensure  => present,
    owner   => 'wwwcontent',
    group   => 'apache',
    mode    => '0644',
    content => template('www/comp-api.wsgi.erb'),
    require => [File[$root_dir]],
  }
}
