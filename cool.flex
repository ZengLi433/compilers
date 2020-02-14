/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <map>
#include <string>
#include <algorithm>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
#define CHECK_OVERFLOW  {                                   \
    if (string_buf_ptr - string_buf == MAX_STR_CONST) {     \
        cool_yylval.error_msg = "String constant too long"; \
        return ERROR;                                       \
    }                                                       \
}
std::map<std::string, int> tokenMap = {
    {"CLASS", CLASS},
    {"ELSE", ELSE},
    {"FI", FI},
    {"IF", IF},
    {"IN", IN},
    {"INHERITS", INHERITS},
    {"LET", LET},
    {"LOOP", LOOP},
    {"POOL", POOL},
    {"THEN", THEN},
    {"WHILE", WHILE},
    {"CASE", CASE},
    {"ESAC", ESAC},
    {"OF", OF},
    {"DARROW", DARROW},
    {"NEW", NEW},
    {"ISVOID", ISVOID},
    {"STR_CONST", STR_CONST},
    {"INT_CONST", INT_CONST},
    {"BOOL_CONST", BOOL_CONST},
    {"TYPEID", TYPEID},
    {"OBJECTID", OBJECTID},
    {"ASSIGN", ASSIGN},
    {"NOT", NOT},
    {"LE", LE},
    {"ERROR", ERROR},
    {"LET_STMT", LET_STMT},
};

int commentNestingLevel = 0;

%}

%x COMMENT
%x STRING

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-

INT_CONST       [0-9]+

/* Keywords */
CLASS           (?i:class)
ELSE            (?i:else)
FI              (?i:fi)
IF              (?i:if)
IN              (?i:in)
INHERITS        (?i:inherits)
ISVOID          (?i:isvoid)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
NEW             (?i:new)
OF              (?i:of)
NOT             (?i:not)
BOOL_CONST      (t(?i:rue))|(f(?i:alse))
KEYWORD         ({CLASS}|{IF}|{FI}|{THEN}|{IN}|{INHERITS}|{ISVOID}|{LET}|{LOOP}|{POOL}|{WHILE}|{CASE}|{ESAC}|{NEW}|{OF}|{NOT}|{ELSE})
TYPEID          ([A-Z][[:alnum:]_]*)
OBJECTID        ([a-z][[:alnum:]_]*)

%%

 /*
  *  Nested comments
  */

<*>(\n) {
    curr_lineno ++;
}

<INITIAL,COMMENT>\(\* {
    BEGIN(COMMENT);
    commentNestingLevel++;
}

<COMMENT>{
    . {
        /* Eat up everything in a comment */
    }

    \*\) {
        commentNestingLevel--;
        if (commentNestingLevel == 0) {
            BEGIN(INITIAL);
        }
    }

    <<EOF>> {
        cool_yylval.error_msg = "EOF in comment";
        BEGIN(INITIAL);
        return ERROR;
    }
}

\*\) {
    cool_yylval.error_msg = "Unmatched *)";
    return ERROR;
}

\-\-.*$ {
    /* Eat up comments between -- and $ */
    // TODO handle EOF
}

 /* Single character rules
  */
[\.@~\*/\+\-<=,\:;\(\)\{\}] {
    return int(*yytext);
}

 /*
  *  Strings
  */
\" {
    string_buf_ptr = string_buf;
    BEGIN(STRING);
}

<STRING>{
    \" {
        /* Closing quote */
        cool_yylval.symbol = inttable.add_string(string_buf);
        BEGIN(INITIAL);
        return STR_CONST;
    }

    \n {
        curr_lineno++;
        cool_yylval.error_msg = "Unterminated string constant";
        BEGIN(INITIAL);
        return ERROR;
    }

    \\n  {
        CHECK_OVERFLOW;
        *string_buf_ptr++ = '\n';
    }

    \\t  {
        CHECK_OVERFLOW;
        *string_buf_ptr++ = '\t';
    }

    \\b  {
        CHECK_OVERFLOW;
        *string_buf_ptr++ = '\b';
    }

    \\f  {
        CHECK_OVERFLOW;
        *string_buf_ptr++ = '\f';
    }

    \\\n  {
        /* Escaped newline */
        curr_lineno++;
        CHECK_OVERFLOW;
        *string_buf_ptr++ = yytext[1];
    }

    \\. {
        CHECK_OVERFLOW;
        *string_buf_ptr++ = yytext[1];
    }

    [^\\\n\"]+ {
        /* Matches a set of chars that don't
           have \, \n, or "
         */
        char *yptr = yytext;

        CHECK_OVERFLOW;

        while ( *yptr )
            *string_buf_ptr++ = *yptr++;
    }

    <<EOF>> {
        cool_yylval.error_msg = "EOF in string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
}

 /*
  *  The multiple-character operators.
  */
{DARROW} {
    return (DARROW);
}

{ASSIGN} {
    return (ASSIGN);
}

{INT_CONST} {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}

{BOOL_CONST} {
    cool_yylval.boolean = 1;
    return BOOL_CONST;;
}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{KEYWORD} {
    std::string s(yytext);
    transform(s.begin(), s.end(), s.begin(), ::toupper);
    return tokenMap[s];
}

{TYPEID} {
    cool_yylval.symbol = inttable.add_string(yytext);
    return (TYPEID);
}

{OBJECTID} {
    cool_yylval.symbol = inttable.add_string(yytext);
    return (OBJECTID);
}

[[:space:]] {
    /* Eat up all whitespace */
}

. {
    cool_yylval.error_msg = yytext;
    return ERROR;
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */


%%
