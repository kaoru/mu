
use v6-alpha;

class KindaPerl6::Visitor::EmitPerl5 {

    # This visitor is a perl5 emitter
    
    method visit ( $node ) {
        $node.emit_perl5;
    };

}

# for MOP emitter:

#class Module {
#    has $.name;
#    has $.body;
#    method emit_perl5 {
#          '{ package ' ~ $.name ~ ';' ~ Main::newline() 
#        ~ $.body.emit_perl5 
#        ~ ' }' ~ Main::newline();
#    }
#}

# from mp6 perl5 emitter:

class CompUnit {
    has $.unit_type;
    has $.name;
    has %.attributes;
    has %.methods;
    has $.body;
    method emit_perl5 {
          '{ package ' ~ $.name ~ "; " 
        ~ ( $.unit_type eq 'module'
            ?? ''
            !! 'sub new { shift; bless { @_ }, "' ~ $.name ~ '" }' ~ " " 
          )
        ~ $.body.emit_perl5
        ~ ' }' ~ Main::newline();
    }
}

class Val::Int {
    has $.int;
    method emit_perl5 { 
        # $.int 
        '( bless \\( do{ my $v = ' ~ $.int ~ ' } ), \'Type_Constant_Int\' )'
    }
}

class Val::Bit {
    has $.bit;
    method emit_perl5 { 
        # $.bit 
        '( bless \\( do{ my $v = ' ~ $.bit ~ ' } ), \'Type_Constant_Bit\' )'
    }
}

class Val::Num {
    has $.num;
    method emit_perl5 { $.num }
}

class Val::Buf {
    has $.buf;
    method emit_perl5 { 
        # '\'' ~ $.buf ~ '\'' 
        '( bless \\( do{ my $v = ' ~ '\'' ~ $.buf ~ '\'' ~ ' } ), \'Type_Constant_Buf\' )'
    }
}

class Val::Undef {
    method emit_perl5 { 
        #'(undef)' 
        '$GLOBAL::undef'
    }
}

class Val::Object {
    has $.class;
    has %.fields;
    method emit_perl5 {
        'bless(' ~ %.fields.perl ~ ', ' ~ $.class.perl ~ ')';
    }
}

class Native::Buf {
    has $.buf;
    method emit_perl5 { 
        '\'' ~ $.buf ~ '\''
    }
}

class Lit::Seq {
    has @.seq;
    method emit_perl5 {
        '(' ~ (@.seq.>>emit_perl5).join(', ') ~ ')';
    }
}

class Lit::Array {
    has @.array;
    method emit_perl5 {
        '[' ~ (@.array.>>emit_perl5).join(', ') ~ ']';
    }
}

class Lit::Hash {
    has @.hash;
    method emit_perl5 {
        my $fields := @.hash;
        my $str := '';
        for @$fields -> $field { 
            $str := $str ~ ($field[0]).emit_perl5 ~ ' => ' ~ ($field[1]).emit_perl5 ~ ',';
        }; 
        '{ ' ~ $str ~ ' }';
    }
}

class Lit::Code {
    has $.pad;   # see Pad.pm
    has $.state;
    has $.sig;
    has @.body;
    method emit_perl5 {
        my $s;
        for @($.pad.variable_names) -> $name {
            my $decl := ::Decl(
                decl => 'my',
                type => '',
                var  => ::Var(
                    sigil => '',
                    twigil => '',
                    name => $name,
                ),
            );
            $s := $s ~ $name.emit_perl5 ~ '; ';
            #$s := $s ~ 'my ' ~ $name ~ '; ';
        };
        return 
            $s
            ~ (@.body.>>emit_perl5).join('; ');
#        my $a := $.body;
#        my $s;
#        for @$a -> $item {
#            $s := $s ~ $item.emit_perl5 ~ ';' ~ Main::newline();
#        };
#        return $s;
    }
}

class Lit::Object {
    has $.class;
    has @.fields;
    method emit_perl5 {
        # $.class ~ '->new( ' ~ @.fields.>>emit_perl5.join(', ') ~ ' )';
        my $fields := @.fields;
        my $str := '';
        # say @fields.map(sub { $_[0].emit_perl5 ~ ' => ' ~ $_[1].emit_perl5}).join(', ') ~ ')';
        for @$fields -> $field { 
            $str := $str ~ ($field[0]).emit_perl5 ~ ' => ' ~ ($field[1]).emit_perl5 ~ ',';
        }; 
        $.class ~ '->new( ' ~ $str ~ ' )';
    }
}

class Index {
    has $.obj;
    has $.index;
    method emit_perl5 {
        $.obj.emit_perl5 ~ '->INDEX(' ~ $.index.emit_perl5 ~ ')';
        # TODO
        # if ($.obj.isa(Lit::Seq)) {
        #    $.obj.emit_perl5 ~ '[' ~ $.index.emit_perl5 ~ ']';
        # }
        # else {
        #    $.obj.emit_perl5 ~ '->[' ~ $.index.emit_perl5 ~ ']';
        # }
    }
}

class Lookup {
    has $.obj;
    has $.index;
    method emit_perl5 {
        $.obj.emit_perl5 ~ '->LOOKUP(' ~ $.index.emit_perl5 ~ ')';
    }
}

class Assign {
    has $.parameters;
    has $.arguments;
    method emit_perl5 {
        # TODO - same as ::Bind
        $.parameters.emit_perl5 ~ '->STORE(' ~ $.arguments.emit_perl5 ~ ')';
    }
}

class Var {
    has $.sigil;
    has $.twigil;
    has $.name;
    method emit_perl5 {
        # Normalize the sigil here into $
        # $x    => $x
        # @x    => $List_x
        # %x    => $Hash_x
        # &x    => $Code_x
        my $table := {
            '$' => '$',
            '@' => '$List_',
            '%' => '$Hash_',
            '&' => '$Code_',
        };
        
        if $.twigil eq '.' {
            return '$self->{' ~ $.name ~ '}' 
        };
        
        if $.name eq '/' {
            return $table{$.sigil} ~ 'MATCH' 
        };
        
        #if $.sigil eq '&' {
        #    return Main::mangle_name( $.sigil, $.twigil, $.name );
        #};
        
        return Main::mangle_name( $.sigil, $.twigil, $.name ); 
    };
#    method emit_perl5_container {
#        my $table := {
#            '$' => '$',
#            '@' => '$List_',
#            '%' => '$Hash_',
#            '&' => '$Code_',
#        };
#           ( $.twigil eq '.' )
#        ?? ( '$self->{' ~ $.name ~ '}' )
#        !!  (    ( $.name eq '/' )
#            ??   ( $table{$.sigil} ~ 'MATCH' )
#            !!   Main::mangle_name( $.sigil, $.twigil, $.name ) 
#            )
#    };
}

class Bind {
    has $.parameters;
    has $.arguments;
    method emit_perl5 {
        if $.parameters.isa( 'Lit::Array' ) {
            
            #  [$a, [$b, $c]] := [1, [2, 3]]
            
            my $a := $.parameters.array;
            #my $b := $.arguments.array;
            my $str := 'do { ';
            my $i := 0;
            for @$a -> $var { 
                my $bind := ::Bind( 
                    'parameters' => $var, 
                    # 'arguments' => ($b[$i]) );
                    'arguments'  => ::Index(
                        obj    => $.arguments,
                        index  => ::Val::Int( int => $i )
                    )
                );
                $str := $str ~ ' ' ~ $bind.emit_perl5 ~ '; ';
                $i := $i + 1;
            };
            return $str ~ $.parameters.emit_perl5 ~ ' }';
        };
        if $.parameters.isa( 'Lit::Hash' ) {

            #  {:$a, :$b} := { a => 1, b => [2, 3]}

            my $a := $.parameters.hash;
            my $b := $.arguments.hash;
            my $str := 'do { ';
            my $i := 0;
            my $arg;
            for @$a -> $var {

                $arg := ::Val::Undef();
                for @$b -> $var2 {
                    #say "COMPARE ", ($var2[0]).buf, ' eq ', ($var[0]).buf;
                    if ($var2[0]).buf eq ($var[0]).buf {
                        $arg := $var2[1];
                    }
                };

                my $bind := ::Bind( 'parameters' => $var[1], 'arguments' => $arg );
                $str := $str ~ ' ' ~ $bind.emit_perl5 ~ '; ';
                $i := $i + 1;
            };
            return $str ~ $.parameters.emit_perl5 ~ ' }';
        };

        if $.parameters.isa( 'Lit::Object' ) {

            #  ::Obj(:$a, :$b) := $obj

            my $class := $.parameters.class;
            my $a     := $.parameters.fields;
            my $b     := $.arguments;
            my $str   := 'do { ';
            my $i     := 0;
            my $arg;
            for @$a -> $var {
                my $bind := ::Bind( 
                    'parameters' => $var[1], 
                    'arguments'  => ::Call( invocant => $b, method => ($var[0]).buf, arguments => [ ], hyper => 0 )
                );
                $str := $str ~ ' ' ~ $bind.emit_perl5 ~ '; ';
                $i := $i + 1;
            };
            return $str ~ $.parameters.emit_perl5 ~ ' }';
        };
    
        $.parameters.emit_perl5 ~ ' = ' ~ $.arguments.emit_perl5;
    }
}

class Proto {
    has $.name;
    method emit_perl5 {
        ~$.name        
    }
}

class Call {
    has $.invocant;
    has $.hyper;
    has $.method;
    has @.arguments;
    #has $.hyper;
    method emit_perl5 {
        my $invocant := $.invocant.emit_perl5;
        if $invocant eq 'self' {
            $invocant := '$self';
        };
        if     ($.method eq 'perl')
            || ($.method eq 'yaml')
            || ($.method eq 'say' )
            || ($.method eq 'join')
            || ($.method eq 'chars')
            || ($.method eq 'isa')
        { 
            if ($.hyper) {
                return 
                    '[ map { Main::' ~ $.method ~ '( $_, ' ~ ', ' ~ (@.arguments.>>emit_perl5).join(', ') ~ ')' ~ ' } @{ ' ~ $invocant ~ ' } ]';
            }
            else {
                return
                    'Main::' ~ $.method ~ '(' ~ $invocant ~ ', ' ~ (@.arguments.>>emit_perl5).join(', ') ~ ')';
            }
        };

        my $meth := $.method;
        if  $meth eq 'postcircumfix:<( )>'  {
             $meth := '';  
        };
        
        my $call := '->' ~ $meth ~ '(' ~ (@.arguments.>>emit_perl5).join(', ') ~ ')';
        if ($.hyper) {
            '[ map { $_' ~ $call ~ ' } @{ ' ~ $invocant ~ ' } ]';
        }
        else {
            $invocant ~ $call;
        };

    }
}

class Apply {
    has $.code;
    has @.arguments;
    method emit_perl5 {
        
        return '(' ~ $.code.emit_perl5 ~ ')->(' ~ (@.arguments.>>emit_perl5).join(', ') ~ ')';

#        my $code := $.code;
#
#        if $code.isa( 'Str' ) { }
#        else {
#        };
#
#        if $code eq 'self'       { return '$self' };
#        
#          Main::mangle_name( '&', '', $.code )
#        ~ '->(' ~ (@.arguments.>>emit_perl5).join(', ') ~ ')';
    }
}

class Return {
    has $.result;
    method emit_perl5 {
        return
        #'do { print Main::perl(caller(),' ~ $.result.emit_perl5 ~ '); return(' ~ $.result.emit_perl5 ~ ') }';
        'return(' ~ $.result.emit_perl5 ~ ')';
    }
}

class If {
    has $.cond;
    has $.body;
    has $.otherwise;
    method emit_perl5 {
        'do { if (' ~ $.cond.emit_perl5 ~ ') { ' ~ $.body.emit_perl5 ~ ' } '
        ~ ( $.otherwise 
            ?? ' else { ' ~ $.otherwise.emit_perl5 ~ ' }' 
            !! '' 
          )
        ~ ' }';
    }
}

class For {
    has $.cond;
    has $.body;
    has @.topic;
    method emit_perl5 {
        my $cond := $.cond;
        if   $cond.isa( 'Var' ) 
          && $cond.sigil eq '@' 
        {
            $cond := ::Apply( code => 'prefix:<@>', arguments => [ $cond ] );
        };
        'do { for my ' ~ $.topic.emit_perl5 ~ ' ( ' ~ $cond.emit_perl5 ~ ' ) { ' ~ $.body.emit_perl5 ~ ' } }';
    }
}

class Decl {
    has $.decl;
    has $.type;
    has $.var;
    method emit_perl5 {
        my $decl := $.decl;
        my $name := $.var.name;
        if $decl eq 'has' {
            return 'sub ' ~ $name ~ ' { ' ~
            '@_ == 1 ' ~
                '? ( $_[0]->{' ~ $name ~ '} ) ' ~
                ': ( $_[0]->{' ~ $name ~ '} = $_[1] ) ' ~
            '}';
        };
        if $decl eq 'our' {
            my $s;
            # use vars --> because compile-time scope is too tricky to use 'our'
            $s := 'use vars \'' ~ $.var.emit_perl5 ~ '\'; ';  

            if ($.var).sigil eq '$' {
                return $s ~ $.var.emit_perl5
                    ~ ' = bless \\( do{ my $v = $GLOBAL::undef } ), \'Type_Scalar\' ';
            };
            if ($.var).sigil eq '%' {
                return $s ~ $.var.emit_perl5
                    ~ ' = bless { }, \'Type_Hash\' ';
            };
            if ($.var).sigil eq '@' {
                return $s ~ $.var.emit_perl5
                    ~ ' = bless [ ], \'Type_Array\' ';
            };
            return $s ~ $.var.emit_perl5 ~ ' ';
        };
        if ($.var).sigil eq '$' {
            return $.decl ~ ' ' ~ $.type ~ ' ' ~ $.var.emit_perl5
                ~ ' = bless \\( do{ my $v = $GLOBAL::undef } ), \'Type_Scalar\'';
        };
        if ($.var).sigil eq '%' {
            return $.decl ~ ' ' ~ $.type ~ ' ' ~ $.var.emit_perl5
                ~ ' = bless { }, \'Type_Hash\'';
        };
        if ($.var).sigil eq '@' {
            return $.decl ~ ' ' ~ $.type ~ ' ' ~ $.var.emit_perl5
                ~ ' = bless [ ], \'Type_Array\'';
        };
        return $.decl ~ ' ' ~ $.type ~ ' ' ~ $.var.emit_perl5;
    }
}

class Sig {
    has $.invocant;
    has $.positional;
    has $.named;
    method emit_perl5 {
        ' print \'Signature - TODO\'; die \'Signature - TODO\'; '
    };
    method invocant {
        $.invocant
    };
    method positional {
        $.positional
    }
}

class Method {
    has $.name;
    #has $.sig;
    has $.block;
    method emit_perl5 {
        # TODO - signature binding
        my $sig := $.block.sig;
        # say "Sig: ", $sig.perl;
        my $invocant := $sig.invocant; 
        # say $invocant.emit_perl5;

        my $pos := $sig.positional;
        my $str := 'my $List__ = \@_; ';   # no strict "vars"; ';

        # TODO - follow recursively
        my $pos := $sig.positional;
        for @$pos -> $field { 
            $str := $str ~ 'my ' ~ $field.emit_perl5 ~ '; ';
        };

        my $bind := ::Bind( 
            'parameters' => ::Lit::Array( array => $sig.positional ), 
            'arguments'  => ::Var( sigil => '@', twigil => '', name => '_' )
        );
        $str := $str ~ $bind.emit_perl5 ~ '; ';

#        my $pos := $sig.positional;
#        my $str := '';
#        my $i := 1;
#        for @$pos -> $field { 
#            $str := $str ~ 'my ' ~ $field.emit_perl5 ~ ' = $_[' ~ $i ~ ']; ';
#            $i := $i + 1;
#        };

        'sub ' ~ $.name ~ ' { ' ~ 
          'my ' ~ $invocant.emit_perl5 ~ ' = shift; ' ~
          $str ~
          $.block.emit_perl5 ~ 
        ' }'
    }
}

class Sub {
    has $.name;
    #has $.sig;
    has $.block;
    method emit_perl5 {
        # TODO - signature binding
        my $sig := $.block.sig;
        # say "Sig: ", $sig.perl;
        ## my $invocant := $sig.invocant; 
        # say $invocant.emit_perl5;
        my $pos := $sig.positional;
        my $str := 'my $List__ = \@_; ';  # no strict "vars"; ;

        # This is used by MOP.add_method
        # if $invocant {
        #    $str := $str ~ 'my ' ~ $invocant.emit_perl5 ~ ' = shift; ';
        # }

        # TODO - follow recursively
        my $pos := $sig.positional;
        if @$pos {
            for @$pos -> $field { 
                $str := $str ~ 'my ' ~ $field.emit_perl5 ~ '; ';
            };
    
            my $bind := ::Bind( 
                'parameters' => ::Lit::Array( array => $sig.positional ), 
                'arguments'  => ::Var( sigil => '@', twigil => '', name => '_' )
            );
            $str := $str ~ $bind.emit_perl5 ~ '; ';
        };
        
#        my $i := 0;
#        for @$pos -> $field { 
#            my $bind := ::Bind( 
#                'parameters' => $field, 
#                'arguments'  => ::Index(
#                        obj    => ::Var( sigil => '@', twigil => '', name => '_' ),
#                        index  => ::Val::Int( int => $i )
#                    ),
#                );
#            $str := $str ~ $bind.emit_perl5 ~ '; ';
#            $i := $i + 1;
#        };
        'sub ' ~ $.name ~ ' { ' ~ 
          ## 'my ' ~ $invocant.emit_perl5 ~ ' = $_[0]; ' ~
          $str ~
          $.block.emit_perl5 ~ 
        ' }'
    }
}

class Do {
    has $.block;
    method emit_perl5 {
        'do { ' ~ 
          $.block.emit_perl5 ~ 
        ' }'
    }
}

class Use {
    has $.mod;
    method emit_perl5 {
        'use ' ~ $.mod
    }
}

=begin

=head1 NAME 

KindaPerl6::Perl5::EmitPerl5 - Code generator for KindaPerl6-in-Perl5

=head1 DESCRIPTION

This module generates Perl5 code for the KindaPerl6 compiler.

=head1 AUTHORS

The Pugs Team E<lt>perl6-compiler@perl.orgE<gt>.

=head1 SEE ALSO

The Perl 6 homepage at L<http://dev.perl.org/perl6>.

The Pugs homepage at L<http://pugscode.org/>.

=head1 COPYRIGHT

Copyright 2007 by Flavio Soibelmann Glock and others.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=end
