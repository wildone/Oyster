=xml
<document title="Logging Functions">
    <synopsis>
        Functions associated with reading or writing log data.
    </synopsis>
=cut

package log;

use exceptions;

=xml
    <function name="status">
        <synopsis>
            Saves a message to the status log
        </synopsis>
        <note>
            If a database connection is available, this message is written to the
            #     log table, otherwise it is written to logs/status.log
        </note>
        <prototype>
            log:status(string_message)
        </prototype>
        <example>
            log::status('Something happened');
        </example>
    </function>
=cut

sub status {
    _message('status', shift());
}

=xml
    <function name="error">
        <synopsis>
            Saves a message to the error log
        </synopsis>
        <note>
            If a database connection is available, this message is written to the
            log table, otherwise it is written to logs/error.log
        </note>
        <prototype>
            log::error(string message)
        </prototype>
        <example>
            log::error("We're all gonna die!");
        </example>
    </function>
=cut

sub error {
    _message('error', shift());
}

=xml
    <function name="warning">
        <synopsis>
            Saves a message to the warning log
        </synopsis>
        <note>
            If a database connection is available, this message is written to the
            log table, otherwise it is written to logs/warning.log
        </note>
        <prototype>
            log::warning(string message)
        </prototype>
        <example>
            log::warning("We're all gonna die! ...Maybe!");
        </example>
    </function>
=cut

sub warning {
    _message('warning', shift());
}

=xml
    <function name="debug">
        <synopsis>
            Saves a message to the debug log if debug is enabled in config.pl
        </synopsis>
        <note>
            If a database connection is available, this message is written to the
            log table, otherwise it is written to logs/debug.log
        </note>
        <prototype>
            log::debug(string message)
        </prototype>
        <example>
            log::debug('Something happened');
        </example>
    </function>
=cut

sub debug {
    _message('debug', shift()) if $oyster::CONFIG{'debug'};
}

=xml
    <function name="_message">
        <synopsis>
            Saves a message to a log.
        </synopsis>
        <note>
            If a database connection is available, this message is written to the
            log table, otherwise it is written to the logs/ directory
        </note>
        <note>
            This function is used internally by the Oyster library and should only
            be used by modules if you wish to create custom message types.  Use
            log_status() and log_error() instead.
        </note>
        <note>
            This function is not exported by default, to use it you must call it by
            its fully qualified name.
        </note>
        <prototype>
            log::_message(string message_type, string message)
        </prototype>
        <example>
            log::_message("error", "We're all gonna die!");
        </example>
    </function>
=cut

sub _message {
    my ($type, $message) = @_;

    # first, attempt to log it to the database
    my $success = try {
        abort() unless $oyster::DB;
        $oyster::DB->do("INSERT INTO $oyster::CONFIG{site_id}_logs (type, time, message, trace) VALUES (?, UTC_TIMESTAMP(), ?, ?)", {}, $type, $message, exceptions::trace());
        abort() if $DBI::errstr;
    }
    catch 'db_error', with {
        abort();
    }
    catch 'perl_error', with {
        abort();
    };

    unless ($success) {
        open(my $log, '>>', "$oyster::CONFIG{site_path}logs/$type.log");
        print $log scalar(localtime) . "\t$message\n";
        # TODO: should this store a trace?
    }
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
