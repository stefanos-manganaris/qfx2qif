#!/usr/bin/perl
#
# QFX2QIF - converts qfx files to qif files
#
# Copyright © 2018 Stefanos Manganaris
#
# This software comes with absolutly NO WARRANTY of any kind.
#
# See also: qfx2qif.yp
#

die "Usage: $0 <filename> <acct regexp> <acct name> <securities>\n" unless $#ARGV==3;

my $fname=$ARGV[0];
local $acctregexp=$ARGV[1];		# regexp to match the account(s) to export from the QFX
my $qacct=$ARGV[2];			# the account name to use in the QIF for import
my $semap=$ARGV[3];			# perl module mapping security CUSIP codes to names - see, for example, Securities.pm
my $qfx=$fname.".qfx";			# qfx input file
my $qif=$fname."-".$qacct.".qif";	# qif output file

die ("No such file $qfx\n") if ! -f $qfx;

require $semap;

undef $/;		# slurp the whole file
open(QFX,"<$qfx") or die("Could not open $qfx for reading. $!");
open(QIF,">$qif") or die("Could not open $qif for writing. $!");
my $data=<QFX>;

print QIF "!Account\n";
print QIF "N$qacct\n";
print QIF "TInvst\n";
print QIF "^\n";
print QIF "!Type:Invst\n";

use lib ".";		# add . to @INC
use qfx2qif;		# parser perl module created by yapp from the grammar in qfx2qif.yp

my $p=new qfx2qif();

sub yylex {
    for($data) {
	1 while (s!^(\s+|\n)!!g);	# advance spaces
	return ("",undef) if $_ eq "";	# EOF
	# tokens
	s!^(\d+)!! and return ("integer", $1);
	s!^([A-Za-z]+)!! and return ("identifier", $1);
	# operators
	s!^([:])!! and return ($1,$1);
	# XML sections
	s!^<SIGNONMSGSRSV1>.*</SIGNONMSGSRSV1>!! and return ("SIGNONMSGSRSV1", "");
	s!^<SECLISTMSGSRSV1>.*</SECLISTMSGSRSV1>!! and return ("SECLISTMSGSRSV1", "");
	s!^<TRNUID>.*?</STATUS>!! and return ("TRNUIDSTATUS", "");
	s!^<DTASOF>.*?<CURDEF>USD!! and return ("DTASOFCURDEF", "");
	s!^<INVACCTFROM>.*?<ACCTID>(\w+)\s?.*?</INVACCTFROM>!! and return ("INVACCTFROM", $1);
	s!^<DTSTART>[^<>]*<DTEND>[^<>]*<!<! and return ("DTSTARTEND", "");
	s!^<INVPOSLIST>.*?</INVPOSLIST>!! and return ("INVPOSLIST", "");
	s!^<INVBAL>.*?</INVBAL>!! and return ("INVBAL", "");
	s!^<INV401K>.*</INV401K><INV401KBAL>.*?</INV401KBAL>!! and return ("INVBAL", "");
	s!^<FITID>[\w\.]*<!<! and return ("FITID", "");
	s!^<DTTRADE>([\w.:\-\[\]]*)<!<! and return ("DTTRADE", "$1");
	s!^<DTSETTLE>([\w.:\-\[\]]*)<!<! and return ("DTSETTLE", "$1");
	s!^<DTPOSTED>([\w.:\-\[\]]*)<!<! and return ("DTPOSTED", "$1");
	s!^<MEMO>([\w\s\-]*)<!<! and return ("MEMO", "$1");
	s!^<SECID><UNIQUEID>([^<>]*)<UNIQUEIDTYPE>CUSIP</SECID>!! and return ("SECID", $1);
	s!^<UNITS>([\d\-.]*)<!<! and return ("UNITS", "$1");
	s!^<UNITPRICE>([\d\-.]*)<!<! and return ("UNITPRICE", "$1");
	s!^<COMMISSION>([\d\-.]*)<!<! and return ("COMMISSION", "$1");
	s!^<FEES>([\d\-.]*)<!<! and return ("FEES", "$1");
	s!^(<WITHHOLDING>[\d\-.]*)?<TOTAL>([\d\-.]*)<!<! and return ("TOTAL", "$2");
	s!^<TRNAMT>([\d\-.]*)<!<! and return ("TRNAMT", "$1");
	s!^<TRNTYPE>(\w*)<!<! and return ("TRNTYPE", $1);
	s!^<SUBACCTSEC>CASH<SUBACCTFUND>CASH!! and return ("SUBACCTSEC", "");
	s!^<SUBACCTSEC>CASH<SUBACCTFUND>OTHER!! and return ("SUBACCTSEC", "");
	s!^<SUBACCTSEC>CASH!! and return ("SUBACCTSEC", "");
	s!^<SUBACCTFUND>CASH!! and return ("SUBACCTSEC", "");
	s!^<INCOMETYPE>(\w*)<!<! and return ("INCOMETYPE", $1);
	s!^<TFERACTION>(\w*)<!<! and return ("TFERACTION", $1);
	s!^<POSTYPE>LONG!! and return ("POSTYPE", "");
	# tags
	s!^<OFX>!!  and return ("OFXstag", "");
	s!^</OFX>!! and return ("OFXetag", "");
	s!^<INVSTMTMSGSRSV1>!!  and return ("INVSTMTMSGSRSV1stag", "");
	s!^</INVSTMTMSGSRSV1>!! and return ("INVSTMTMSGSRSV1etag", "");
	s!^<INVSTMTTRNRS>!!  and return ("INVSTMTTRNRSstag", "");
	s!^</INVSTMTTRNRS>!! and return ("INVSTMTTRNRSetag", "");
	s!^<INVSTMTRS>!!  and return ("INVSTMTRSstag", "");
	s!^</INVSTMTRS>!! and return ("INVSTMTRSetag", "");
	s!^<INVTRANLIST>!!  and return ("INVTRANLISTstag", "");
	s!^</INVTRANLIST>!! and return ("INVTRANLISTetag", "");
	s!^<BUYOTHER><INVBUY>!!   and return ("BUYOTHERstag", "");
	s!^</INVBUY></BUYOTHER>!! and return ("BUYOTHERetag", "");
	s!^<BUYSTOCK><INVBUY>!!   and return ("BUYOTHERstag", "");
	s!^</INVBUY></BUYSTOCK>!! and return ("BUYOTHERetag", "");
	s!^</INVBUY><BUYTYPE>BUY</BUYSTOCK>!! and return ("BUYOTHERetag", "");
	s!^<BUYMF><INVBUY>!!   and return ("BUYOTHERstag", "");
	s!^</INVBUY></BUYMF>!! and return ("BUYOTHERetag", "");
	s!^</INVBUY><BUYTYPE>BUY</BUYMF>!! and return ("BUYOTHERetag", "");
	s!^<INV401KSOURCE>OTHERVEST</INVBUY><BUYTYPE>BUY</BUYMF>!! and return ("BUYOTHERetag", "");
	s!^<INV401KSOURCE>AFTERTAX</INVBUY><BUYTYPE>BUY</BUYMF>!! and return ("BUYOTHERetag", "");
	s!^<INV401KSOURCE>OTHERNONVEST</INVBUY><BUYTYPE>BUY</BUYMF>!! and return ("BUYOTHERetag", "");
	s!^<SELLOTHER><INVSELL>!!   and return ("SELLOTHERstag", "");
	s!^</INVSELL></SELLOTHER>!! and return ("SELLOTHERetag", "");
	s!^<SELLMF><INVSELL>!!   and return ("SELLOTHERstag", "");
	s!^</INVSELL></SELLMF>!! and return ("SELLOTHERetag", "");
	s!^</INVSELL><SELLTYPE>SELL</SELLMF>!! and return ("SELLOTHERetag", "");
	s!^<SELLSTOCK><INVSELL>!!   and return ("SELLSTOCKstag", "");
	s!^</INVSELL></SELLSTOCK>!! and return ("SELLSTOCKetag", "");
	s!^</INVSELL><SELLTYPE>SELL</SELLSTOCK>!! and return ("SELLSTOCKetag", "");
	s!^<INVTRAN>!!  and return ("INVTRANstag", "");
	s!^</INVTRAN>!! and return ("INVTRANetag", "");
	s!^<REINVEST>!!  and return ("REINVESTstag", "");
	s!^</REINVEST>!! and return ("REINVESTetag", "");
	s!^<TRANSFER>!!  and return ("TRANSFERstag", "");
	s!^</TRANSFER>!! and return ("TRANSFERetag", "");
	s!^<INV401KSOURCE>OTHERVEST</TRANSFER>!! and return ("TRANSFERetag", "");
	s!^<INV401KSOURCE>AFTERTAX</TRANSFER>!! and return ("TRANSFERetag", "");
	s!^<INV401KSOURCE>OTHERNONVEST</TRANSFER>!! and return ("TRANSFERetag", "");
	s!^<INCOME>!!  and return ("INCOMEstag", "");
	s!^</INCOME>!! and return ("INCOMEetag", "");
	s!^<INVBANKTRAN>!!  and return ("INVBANKTRANstag", "");
	s!^</INVBANKTRAN>!! and return ("INVBANKTRANetag", "");
	s!^<STMTTRN>!!  and return ("STMTTRNstag", "");
	s!^</STMTTRN>!! and return ("STMTTRNetag", "");
	# otherwise
	print STDERR "Unexpected symbols: '$_'\n" ;
    }
}

sub yyerror {
    if ($_[0]->YYCurtok) {
	printf STDERR ('Error: a "%s" (%s) was found where %s was expected'."\n", $_[0]->YYCurtok, $_[0]->YYCurval, $_[0]->YYExpect)
    } else {
	print STDERR "Expecting one of ",join(", ",$_[0]->YYExpect),"\n";
    }
}

use debug;	# work around for bug causing "can't locate object method_DBParse" error when yydebug is non-zero

$p->YYParse( yylex => \&yylex, yyerror => \&yyerror, yydebug => 0x00);		# 0x01 to see the tokens from the lexer

close(QFX);
close(QIF);
