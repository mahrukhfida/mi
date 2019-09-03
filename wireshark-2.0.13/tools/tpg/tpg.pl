#!/usr/bin/perl
#
# TPG TVB Parser Generator
#
# Given a bnf like grammar generate a parser for text based tvbs
#
# Wireshark - Network traffic analyzer
# By Gerald Combs <gerald@wireshark.org>
# Copyright 2004 Gerald Combs
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


use TPG;
use V2P;
use strict;

my $DEBUG = 0;

my $b = '';

while(<>) {
    $b .= $_;
}

my @T = @{tokenizer()};
my $linenum = 1;
my %CODE = ();
my $codenum = 0;


$b =~ s/\%\{(.*?)\%\}/add_code($1)/egms;

$b =~ s/#.*?\n/\n/gms;

my $parser = new TPG();
my $last_token = '';

$parser->YYData->{DATA}=\$linenum;

my $parser_info = $parser->YYParse(yylex => \&next_token, yyerror => \&error_sub);#,yydebug => 0x1f);

die "failed parsing" unless defined $parser_info;

if ($DEBUG > 3) {
    warn "\n=========================== parser_info ===========================\n";
    warn V2P::var2perl( $parser_info );
    warn "\n=========================== ======== ===========================\n" ;
}

my $proto_name =  ${$parser_info}{proto_name};
my $upper_name = $proto_name;
$upper_name =~ tr/a-z/A-Z/;
my $global_struct = "$proto_name\_tpg_data";

warn "parser_data_type: ${$parser_info}{pdata}\n" if $DEBUG;

my %exports = %{${$parser_info}{export}};

my $field_num = 0;

my $tt_type = ${$parser_info}{pdata};

$tt_type =~ s/\n#line.*?\n//ms;
$tt_type =~ s@\n/\*eocode\*/\n@@ms;

my $init_function_hfs = "\n/* initialize hfids */\n";
my $init_function_etts = "\n/* initialize etts */\n"; 
my $init_function_wanted_decl = "\n/* declare private wanted elements */\n";
my $init_function_wanted = "\n/* initialize wanted elements  */\n";
my $callback_definitions = "\n/* callback definitions */\n";
my $datastruct_ett = "\n/* etts */\n";
my $datastruct_hf = "\n/* hfis */\n";
my $datastruct_wanted = "\n/* wanted elems */\n";

my $hfarr = "/* field array */\n#define HF_$upper_name\_PARSER \\\n";
my $ett_arr = "#define ETT_$upper_name\_PARSER \\\n";

for my $fieldname (keys %{${$parser_info}{fields}}) {
    my $f = ${${$parser_info}{fields}}{$fieldname};
    
    my $vs = defined ${$f}{vs} ? 'VALS(' . ${$f}{vs}. ')' : "NULL" ;
           
    ${$f}{vname} = "$global_struct.hf_${$f}{name}" unless defined ${$f}{vname};
    ${$f}{base} = 'BASE_NONE' unless defined ${$f}{base};
    ${$f}{desc} = '""' unless defined ${$f}{desc};
    $datastruct_hf .= "\tint hf_${$f}{name};\n";
    $init_function_hfs .= "\t${$f}{vname} = -1;\n";
    $hfarr .= "{ &${$f}{vname}, { ${$f}{pname}, ${$f}{abbr}, ${$f}{type}, ${$f}{base}, $vs, 0x0, ${$f}{desc}, HFILL }},\\\n";
                                               
# warn "\nFIELD:$fieldname " . V2P::var2perl($f);

}

$hfarr =~ s/,\\\n$/\n/msi;


for my $rulename ( keys %{${$parser_info}{rules}} ) {
    my $r = ${${$parser_info}{rules}}{$rulename};

# warn "\nRULE BEFORE:$rulename " . V2P::var2perl($r);

    make_rule($r,0);

# warn "\nRULE AFTER:$rulename " . V2P::var2perl($r);

}

$ett_arr =~ s/,\\\n$//ms;

for my $rulename (sort keys %{${$parser_info}{rules}} ) {
    my $r = ${${$parser_info}{rules}}{$rulename};
    
    
    $callback_definitions .= "\n\n/* callback definitions for rule $rulename */\n";
    $callback_definitions .= ${$r}{before_cb_code} . "\n";
    $callback_definitions .= ${$r}{after_cb_def} . "\n";
    $init_function_wanted .= ${$r}{definition_code} . "\n\n";
}




my $h_file = <<"__H_HEAD";
/*
 $proto_name-parser.h
 automagically generated by $0 from $ARGV
 DO NOT MODIFY.
 */

#ifndef _H_$upper_name\_PARSER
#define _H_$upper_name\_PARSER
#include <epan/tpg.h>


/* begin %header_head */
${$parser_info}{header_head}
/* end %header_head */

extern void tpg_${proto_name}_init(void);

struct _${proto_name}_tpg_data_t {
$datastruct_ett
$datastruct_hf
$datastruct_wanted
};


extern struct _${global_struct}_t  $global_struct;

$hfarr


$ett_arr


#endif
__H_HEAD


my $c_file = <<"__C_FILE";
/*
 $proto_name-parser.c
 automagically generated by $0 from $ARGV
 DO NOT MODIFY.
 */

#include "config.h"

#include "$proto_name-parser.h" 

/* begin %head */
${$parser_info}{head}
/* end %head */

/* hfids container */

struct _${proto_name}_tpg_data_t  $global_struct;


$callback_definitions
/* end callback definitions */

void tpg_$proto_name\_init(void) {
    $init_function_wanted_decl
    $init_function_hfs
    $init_function_etts 
    $init_function_wanted
}

/* begin %tail */
${$parser_info}{tail}
/* end %tail */

__C_FILE

my $c_buf = '';
my $c_line = 3;
while($c_file =~ s/^([^\n]*)\n//ms) {
    my $line = $1;

    $c_line += 2 if $line =~ s@/\*eocode\*/@\n#line $c_line \"$proto_name-parser.c\"\n@;
    $c_buf .= $line . "\n";
    $c_line++;
}

my $h_buf = '';
my $h_line = 3;
while($h_file =~ s/^([^\n]*)\n//ms) {
      my $line = $1;
      
      $h_line += 2 if $line =~ s@/\*eocode\*/@\n#line $h_line \"$proto_name-parser.h\"\n@;
      $h_buf .= $line . "\n";
      $h_line++;
}


open C, "> $proto_name-parser.c";
open H, "> $proto_name-parser.h";
print C $c_buf;
print H $h_buf;
close C;
close H;

exit;

sub make_rule {
    my $r = shift;
    my $dd = shift;
    
    my $rule_id = "0";    
    my $code = \${$r}{definition_code};
    my $indent;
    

    
    for (0..$dd) {
        $indent .= "\t";
    }
    
    my $indent_more = $indent . "\t";
    
    my $min;
    my $max;

    if (exists ${$r}{min}) {
        $min = ${$r}{min};
    } else {
        $min = ${$r}{min} = 1;
    }

    if (exists ${$r}{max}) {
        $max = ${$r}{max};
    } else {
        $max = ${$r}{max} = 1;
    }
    
    if ($dd == 0) {
        my %VARS = ();
    
        if ( exists $exports{${$r}{name}}) {
            ${$code} = "\t$global_struct.";
            $datastruct_wanted .= "\ttvbparse_wanted_t* wanted_$proto_name\_${$r}{name};\n"
        } else {
            ${$code} = "\t";
            $init_function_wanted_decl .=  "\tstatic tvbparse_wanted_t* wanted_$proto_name\_${$r}{name};\n"
        }
        
        ${$code} .= "wanted_$proto_name\_${$r}{name} = ";
        
        $VARS{"TT_DATA"} = "TPG_DATA(tpg,$tt_type)" if defined $tt_type;
            
            make_vars(\%VARS,$r,"elem");
        
#        warn "VARS::${$r}{name} " . V2P::var2perl(\%VARS);
                
        
        my $tree_code_head = "";
        my $tree_code_body = "";
        my $tree_code_after = "";
        
        make_tree_code($r,\$tree_code_head,\$tree_code_body,\$tree_code_after,"elem");
        
        if (length $tree_code_body ) {
            my $cb_name = ${$r}{before_cb_name} = "${$r}{name}\_before_cb";
            ${$r}{before_cb_code} = "static void $cb_name(void* tpg _U_, const void* wd _U_, struct _tvbparse_elem_t* elem _U_) {\n\tproto_item* pi;\n$tree_code_head\n$tree_code_body\n}";
            ${$r}{code} .= $tree_code_after;
        }
        
        my $tree_code = \${$r}{tree_code};
                

        if (${$r}{code}) {
            my $after = ${$r}{code};
            
            ${$r}{after_cb_name} = "${$r}{name}_after\_cb";
            
            ${$r}{after_cb_def} = "static void ${$r}{after_cb_name}(void* tpg _U_, const void* wd _U_, struct _tvbparse_elem_t* elem _U_) {\n";
            
            for (keys %VARS) {
                $after =~ s/($_)([A-Z]?)/$VARS{$1}$2/msg;
            }
                        
            ${$r}{after_cb_def} .= $after . "\n}\n";
        }
        
    }
    
    my $after_fn = ${$r}{after_cb_name} ? ${$r}{after_cb_name} : "NULL";
    my $before_fn = ${$r}{before_cb_name} ? ${$r}{before_cb_name} : "NULL";

    my $wd_data = "NULL";

    if (exists ${$r}{field}) {
        my $field = ${${$parser_info}{fields}}{${$r}{field}};
        die "field ${$r}{field} does not exists\n" . V2P::var2perl(${$parser_info}{fields}) unless defined $field;
        
        my $ett = exists ${$r}{ett} ? ${$r}{ett} : "NULL";
        
        my $wd_data = 'tpg_wd(${$field}{vname},$ett,NULL)';
        
    }
    
    my $control = ${$r}{control};
    
    if (${$r}{type} eq 'chars' || ${$r}{type} eq 'not_chars') {
        if (! ($min == 1 && $max == 1) ) {
            ${$code} .= $indent . "tvbparse_${$r}{type}($rule_id,$min,$max,$control,$wd_data,$before_fn,$after_fn)"
        } else {
            my $rn = ${$r}{type};
            $rn =~ s/.$//;
                ${$code} .= $indent . "tvbparse_$rn($rule_id,$control,$wd_data,$before_fn,$after_fn)"
        }
    } else {
        if (! ($min == 1 && $max == 1))  {
            ${$code} .= $indent . "tvbparse_some(0,$min,$max,NULL,NULL,NULL,\n";
        }
            
        if (${$r}{type} eq 'string') {
            
            ${$code} .= $indent . "tvbparse_string($rule_id,$control,$wd_data,$before_fn,$after_fn)";
            
        } elsif (${$r}{type} eq 'caseless') {
            
            ${$code} .= $indent . "tvbparse_casestring($rule_id,$control,$wd_data,$before_fn,$after_fn)";
            
        } elsif (${$r}{type} eq 'named') {
            if(exists $exports{$control}) {
                ${$code} .= $indent . "tvbparse_handle(&$global_struct.wanted_$proto_name\_$control)";
            } else {
                ${$code} .= $indent . "tvbparse_handle(&wanted_$proto_name\_$control)";                
            }
        } elsif (${$r}{type} eq 'seq') {
            
            ${$code} .= $indent . "tvbparse_set_seq($rule_id,$wd_data,$before_fn,$after_fn,\n";
            
            for ( @{${$r}{subrules}}) {
                $dd++;
                ${$code} .= $indent_more . make_rule($_,$dd) . ",\n";
                $dd--;
            }
            
            ${$code} .= $indent . " NULL)"
                
        } elsif (${$r}{type} eq 'choice') {
            
            ${$code} .= $indent . "tvbparse_set_oneof($rule_id,$wd_data,$before_fn,$after_fn,\n";
            
            for (@{${$r}{subrules}}) {
                $dd++;
                ${$code} .= $indent_more . make_rule($_,$dd) . ",\n";
                $dd--;
            }
            
            ${$code} .= $indent . " NULL)"
                
        } elsif (${$r}{type} eq 'until') {
            
            ${$r}{inc_mode} =  'TP_UNTIL_SPEND' unless defined ${$r}{inc_mode};
            
            ${$code} .= $indent ."tvbparse_until(0,$wd_data,$before_fn,$after_fn,\n";
            $dd++;
            ${$code} .= $indent_more . make_rule(${$r}{subrule},$dd) . ", ${$r}{inc_mode})";
            $dd--;
        }
        
        if (! ($min == 1 && $max == 1) ) {
            ${$code} .= ")";
        }    
    }

    if ($dd == 0) {
        ${$code} .= ";\n";
#        warn "RULE::${$r}{name} " . V2P::var2perl($r);
    }

    ${$code};
}


sub make_vars {
    my $v = shift;
    my $r = shift;
    my $base = shift;

    if (exists ${$r}{var}) {
        ${$v}{${$r}{var}} = $base;
    }

    if (! ( ${$r}{type} =~ /chars$/ ) && ! (${$r}{min} == 1 && ${$r}{max} == 1) ) {
        $base .= "->sub";
    }
    
    if (exists ${$r}{subrule} ) {
        make_vars($v,${$r}{subrule},"$base->sub");
    }
    
    
    if (exists ${$r}{subrules} ) {
        my $sub_base = "$base->sub";
        for my $rule (@{${$r}{subrules}}) {
            make_vars($v,$rule,$sub_base);
            $sub_base .= "->next";
        }
    }
}

sub make_tree_code {
    my $r = shift;
    my $head = shift;
    my $body = shift;
    my $after = shift;
    my $elem = shift;    
    
    if (exists ${$r}{field}) {
        my $fieldname = ${$r}{field};
        my $f = ${${$parser_info}{fields}}{$fieldname};

        my $root_var = '';
        
        if (exists ${$r}{tree}) {
            $root_var = "root_$fieldname";
            ${$head} .= "\tproto_item* $root_var;\n\n";
            ${$body} .= "\t$root_var = ";
            $ett_arr .= "\t&$global_struct.ett_$fieldname,\\\n";
            $datastruct_ett .= "\tguint ett_$fieldname; \n";
            $init_function_etts .= "\t$global_struct.ett_$fieldname = -1;\n";
            ${$r}{ett} = "$global_struct.ett_$fieldname";
        } else {
            ${$body} .= "\t";
        }

        
        if (${$f}{type} eq 'FT_STRING') {
            ${$body} .= "\tpi = TPG_ADD_STRING(tpg,${$f}{vname},$elem);\n";
        } elsif (${$f}{type} =~ /^FT_UINT/) {
            my $fieldvar = "tpg_uint_$fieldname";
            ${$head} .= "\tguint $fieldvar = TPG_UINT($elem);\n";
            ${$body} .= "\tpi = TPG_ADD_UINT(tpg,${$f}{vname},$elem,$fieldvar);\n";
        } elsif (${$f}{type} =~ /^FT_INT/) {
            my $fieldvar = "tpg_int_$fieldname";
            ${$head} .= "\tgint $fieldvar = TPG_INT($elem);\n";
            ${$body} .= "\tpi = TPG_ADD_INT(tpg,${$f}{vname},$elem,$fieldvar);\n";
        } elsif (${$f}{type} eq 'FT_IPV4') {
            my $fieldvar = "tpg_ipv4_$fieldname";
            ${$head} .= "\tguint32 $fieldvar = TPG_IPV4($elem);\n";
            ${$body} .= "\tpi = TPG_ADD_IPV4(tpg,${$f}{vname},$elem,$fieldvar);\n";
        } elsif (${$f}{type} eq 'FT_IPV6') {
            my $fieldvar = "tpg_ipv6_$fieldname";
            ${$head} .= "\tguint8* $fieldvar = TPG_IPV6($elem);\n";
            ${$body} .= "\tpi = TPG_ADD_IPV6(tpg,${$f}{vname},$elem,$fieldvar);\n";
        } else {
            ${$body} .= "\tpi = TPG_ADD_TEXT(tpg,$elem);\n";
        }
        
        if (exists ${$r}{plain_text}) {
            ${$body} .= "\tTPG_SET_TEXT(pi,$elem);\n"
        }
        
        if (exists ${$r}{tree}) {
            ${$body} .=  "\tTPG_PUSH(tpg,$root_var,${$r}{ett});\n";
        }
    }
    
    
    if (! ( ${$r}{type} =~ /chars$/ ) && ! (${$r}{min} == 1 && ${$r}{max} == 1) ) {
        $elem .= "->sub";
    }
    
        
    if (exists ${$r}{subrule} ) {
        make_tree_code(${$r}{subrule},$head,$body,$after,"$elem->sub");
    }
    
    if (exists ${$r}{subrules} ) {
        my $sub_base = "$elem->sub";            
        for my $rule (@{${$r}{subrules}}) {
            make_tree_code($rule,$head,$body,$after,$sub_base);
            $sub_base .= "->next";
        }
    }

    if (exists ${$r}{field}) {
        if (exists ${$r}{tree}) {
            ${$after} .=  "\n\t/* tree after code */\n\tTPG_POP(tpg);\n";
        }
        
    }
}
sub tokenizer {
    [
        [ '(FT_(UINT(8|16|24|32)|STRING|INT(8|16|24|32)|IPV[46]|ETH|BOOLEAN|DOUBLE|FLOAT|(ABSOLUTE|RELATIVE)_TIME|BYTES))' , sub { [ 'FT', $_[0] ] } ],
        [ '(BASE_(NONE|DEC|HEX))', sub { [ 'BASE', $_[0] ] }],
        [ '([a-z]+\\.[a-z0-9_\\.]*[a-z])', sub { [ 'DOTEDNAME', $_[0] ] }], 
        [ '([a-z][a-z0-9_]*)', sub { [ 'LOWERCASE', $_[0] ] }], 
        [ '([A-Z][A-Z0-9_]*)', sub { [ 'UPPERCASE', $_[0] ] }],
        [ '([0-9]+|0x[0-9a-fA-F]+)', sub { [ 'NUMBER', $_[0] ] }],
        [ '(\%\%[0-9]+\%\%)', \&c_code ],
        [ "'((\\\\'|[^'])*)'", sub { [ 'SQUOTED', $_[0] ] }], 
        [ '\[\^((\\\\\\]|[^\\]])*)\]', sub { [ 'NOTCHARS', $_[0] ] }], 
        [ '\[((\\\\\\]|[^\\]])*)\]', sub { [ 'CHARS', $_[0] ] }], 
        [ '"((\\\\"|[^"])*)"', sub { [ 'DQUOTED', $_[0] ] }], 
        [ '(\%[a-z_]+|\%[A-Z][A-Z-]*|\&|\=|\.\.\.|\.|\:|\;|\(|\)|\{|\}|\+|\*|\?|\<|\>|\|)', sub { [  $_[0], $_[0] ] }], 
    ]
}

sub next_token {
    
    if ($b =~ s/^([\r\n\s]+)// )  {
        my $l = $1;
        while ( $l =~ s/\n//ms ) {
                $linenum++;
        }
    }

    return (undef,'') unless length $b;

    for (@T) {
        my ($re,$ac) = @{$_};
        
        if( $b =~ s/^$re//ms) {
            $a = &{$ac}($1);
            $last_token = ${$a}[1];
#warn "=($linenum)=> ${$a}[0]   ${$a}[1]\n";
            return (${$a}[0],${$a}[1]);
        }
    }

    die "unrecognized token at line $linenum after '$last_token'";
}

sub error_sub {
    my @a = $_[0]->YYExpect;
    my $t = $_[0]->YYCurtok;
    
    die "error at $linenum after '$last_token' expecting (@a)";
}


sub add_code {
    my $k = "%%$codenum%%";
    $CODE{$k} = $_[0];
    $codenum++;
    return $k;
}

sub c_code {
    my $k = $_[0];
    my $t = $CODE{$k};
    my $start = $linenum;
    $linenum++ while ( $t =~ s/\n// );
    return [ 'CODE', "\n#line $start \"$ARGV\"\n$CODE{$k}\n/*eocode*/\n"];
}


__END__

do {
    ($type,$value) = @{next_token()};
    last if not defined $type;
} while(1);

