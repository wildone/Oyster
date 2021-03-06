Setting Up an Oyster Development Environment

* Ensure you have the software required to run Oyster.
  - Perl

    Type `perl -v` to see your Perl version (or to check if you have Perl
    installed).

    Perl 5.10.1 or higher is required.

    On Windows, visit activestate.com and download their latest version
    of perl.

    On Linux or BSD, either compile perl from source or install using your
    distribution's package management tools.

  - ImageMagick

    ImageMagick is a set of programs that allow advanced image manipulation to
    be done on the command line.  Only the Imagemagick binaries are required
    by Oyster, no ImageMagick perl libraries are required.

    NOTE: ImageMagick is NOT mandatory for development or testing, as long as 
    you will not need any image manipulation performed.

    To obtain ImageMagick, visit imagemagick.com and find the proper release
    for your platform.

    Once installed, you need to know where ImageMagick's binaries are at.

    On Windows, this directory will be the one you specified during
    installation, typically 'C:/program files/imagemagick/'.

    On Linux, the binaries are usually placed in '/usr/bin/'. On BSD, the 
    binaries are usually placed in '/usr/local/bin/'.

  - MySQL, MariaDB or PostgreSQL object-relational database management systems

    On Windows, visit mysql.org, mariadb.org or postgresql.org and download the 
    latest release.

    On Linux or BSD, either compile MySQL, MariaDB or PostgreSQL from source or 
    install using your distribution's package management tools.

    NOTE: PostgreSQL support is considered alpha.  Most, if not all, of Oyster 
    should be PostgreSQL compatible but this is not tested regularly.

  - Perl Modules

    Oyster requires the following perl modules: DBI, DBD::mysql, Digest::JHash,
    Time::HiRes, and Digest::SHA.  XML::LibXML and XML::LibXSLT are also
    also recommended (they are used for server-side XSLT), but the ssxslt module
    will automatically disable itself if they are not found.  Digest::SHA and
    Digest::JHash are not required, but recommended for high traffic sites.
    Time::HiRes usually comes with Perl.  The optionsl SOAP library requires 
    IO::Socket::SSL for https support.

    To check if you have these modules installed, type:
    `perl -Mmodulenamehere -e "print qq{success\n}"`
    If an error is printed instead of "success", you do not have the module.

    To install these modules using CPAN type:
    `perl -MCPAN -e "install modulenamehere"`

    To install these modules using Activestate's PPM type:
    `ppm install modulenamehere`

    To install these modules using FreeBSD's ports type:
    `pkg_add -r p5-DBI`
    `pkg_add -r p5-DBD-mysql`
    `pkg_add -r p5-Digest-JHash`
    `pkg_add -r p5-Digest-SHA`

* Get a fresh git clone:
  `git clone https://github.com/BitPiston/Oyster.git oyster`

* Navigate to the shared directory:
  `cd oyster/trunk/shared`

* Copy the config file template:
  `cp config.pl.tmpl config.pl`

* Edit config.pl with the text editor of your choice.

* Install Oyster:
  `perl script/update.pl`

* Start your test server:
  `perl script/server.pl`

  Note: For additional server options, type `perl script/server.pl -h`

* Visit 127.0.0.1:80 (or whatever you configured the server to bind to)

* Your Oyster development environment is ready!

  For details on spawning Oyster as FastCGI under a httpd such as Lighttpd, 
  nginx or Apache refer to the documentation which has configuration examples
  available for all three. It also includes examples for using supervisord or 
  fcgictl/spawn-fcgi.

