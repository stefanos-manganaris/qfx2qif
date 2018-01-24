# This code originates from Parse::Yapp - Yet Another Parser Parser For Perl
# Parse::Yapp is Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien. Copyright © 2017 William N. Braswell, Jr.
# It is included here to work around a bug that breaks _DBLoad() when yydebug is not 0x0.
# It works around the bug by providing _DBParse() more directly.

package Parse::Yapp::Driver;

sub _DBParse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

	my($debug)=$$self{DEBUG};
	my($dbgerror)=0;

	my($ShowCurToken) = sub {
		my($tok)='>';
		for (split('',$$token)) {
			$tok.=		(ord($_) < 32 or ord($_) > 126)
					?	sprintf('<%02X>',ord($_))
					:	$_;
		}
		$tok.='<';
	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

	print STDERR ('-' x 40),"\n";
		$debug & 0x2
	and	print STDERR "In state $stateno:\n";
		$debug & 0x08
	and	print STDERR "Stack:[".
					 join(',',map { $$_[0] } @$stack).
					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
				$debug & 0x01
			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
			$debug & 0x01
		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

				$debug & 0x04
			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

					$debug & 0x10
				and	$dbgerror
				and	$$errstatus == 0
				and	do {
					print STDERR "**End of Error recovery.\n";
					$dbgerror=0;
				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

			$debug & 0x04
		and	$act
		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

			$debug & 0x04
		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

			$debug & 0x04
		and	print STDERR "Abort.\n";

				return(undef);

			};

			$debug & 0x04
		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
				$debug & 0x04
			and	print STDERR
				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

				$debug & 0x10
			and	$dbgerror
			and	$$errstatus == 0
			and	do {
				print STDERR "**End of Error recovery.\n";
				$dbgerror=0;
			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

			$debug & 0x04
		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

			$debug & 0x10
		and	do {
			print STDERR "**Entering Error recovery.\n";
			++$dbgerror;
		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
				$debug & 0x10
			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

			$debug & 0x10
		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

			$debug & 0x10
		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

			$debug & 0x10
		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

			$debug & 0x10
		and	print STDERR "**Shift \$error token and go to state ".
						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse

1;
