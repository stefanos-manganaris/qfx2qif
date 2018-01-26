QFX2QIF - converts qfx files to qif files

Copyright © 2018 Stefanos Manganaris

IMPORTANT NOTES

You may find this converter useful if you use old accounting software to
track your investment transactions that can import .qif files, but not
.qfx files. Many financial institutions provide .qfx files and no longer
provide .qif files.

This software comes with absolutly NO WARRANTY of any kind.

This converter is known to work well with qfx files provided by
TIAA-CREF and Vanguard, for certain types of investment accounts, and
for certain types of investment transactions.  It is almost certain
that it does NOT cover the full spectrum of institutions, accounts,
and transactions.  Contributions that enhance its functionality are
welcome.

REQUIREMENTS

* [Perl 5](https://www.perl.org/)
* [Parse::Yapp 1.21, Yet Another Parser Parser For Perl](http://search.cpan.org/~wbraswell/Parse-Yapp-1.21/)

USAGE

    yapp qfx2qif.yp   # compile the grammar into a parser (once)
    qfx2qif.pl "filename" "acct regexp" "acct name" "securities"

The converter reads the contents of "filename".qfx and creates
"filename"-"acct name".qif as output.  The qfx file is not changed.
If the qif file exists, it is overwritten.

A qfx file may contain transactions from multiple accounts at the
financial institution.  Imports from qif files require a single
destination account in your accounting software.  Specify the
destination account as "acct name".  Select the subset of accounts to
include in the qif file by providing a regular expression that matches
the account numbers at the institution.  For example, "^.*" to match all
the accounts, or "^A12345" to match all the accounts that start with
A12345, or "^(A123|B456)" to match prefixes A123 or B456.

The "securities" argument should refer to a perl module that defines a
mapping between security CUSIP codes and security names.  See the
provided Securities.pm module for an example. Investment transactions are
exported into the qif file using the security names you specify in this
module, to match those defined in your accounting software.

MANIFEST

	qfx2qif.yp		the grammar for the parser
	qfx2qif.pl		the converter
	debug.pm		this code originates from Parse::Yapp -- see A NOTE ON debug.pm
	Securities.pm	example - mapping of CUSIP security codes to security names

A NOTE ON debug.pm

debug.pm works around a bug. The specifics were discussed in
`comp.lang.perl.misc` in 2004 ("Perl pattern 5.6+ bug causing Parse::Yapp
to fail").  The root cause is not clear and seems to have eluded
attention for nearly 15 years...  The symptom is an error about
`_DBLoad()` when calling the parser with `yydebug` values other than
`0x0`. The code in debug.pm originates from Parse::Yapp and provides
`_DBParse()` more directly to sidestep the issue.

CONTACT

stefanos.manganaris at gmail.com
