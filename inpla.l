%{
#include <stdio.h>
#include <stdlib.h>
//http://kmaebashi.com/programmer/c_yota/calc_html/calc_l.html
//#undef YY_INPUT
//#define YY_INPUT(buf, result, max_size) (result = my_yyinput(buf, max_size))
//static int my_yyinput(char *buf, int max_size);

//#undef YY_INPUT
//#define YYINPUT(buf, result, max_size) result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); 



/************************************
 Strings
*************************************/
#define MAX_STRING_LENGTH 1024
static char ParseStringBuffer[MAX_STRING_LENGTH];
static int nextPtr_ParseStringBuffer = 0;
void Parse_StringBuffer_reInit() {
  nextPtr_ParseStringBuffer = 0;
}

void Parse_addString(char ch) {
  ParseStringBuffer[nextPtr_ParseStringBuffer] = ch;
  nextPtr_ParseStringBuffer++;
}

char *Parse_closeStringBuffer() {
  char *ret;
  ParseStringBuffer[nextPtr_ParseStringBuffer]='\0';
  ret = ParseStringBuffer;
  return ret;
}


// Linebreak CR LN CRLN
void op_br() {
  if (yyin==stdin) { 
    if (yylineno>1) printf("> "); 
    //else return DELIMITER;
  }
}



%}

%option nounput
%option yylineno
%x STRING_STATE COM_STATE
%%
<INITIAL>";" return (DELIMITER);
<INITIAL>"(" return (LP);
<INITIAL>")" return (RP);
<INITIAL>"{" return LC;
<INITIAL>"}" return RC;
<INITIAL>"," return (COMMA);
<INITIAL>"><" return (CROSS);
<INITIAL>"=>" return (TO);
<INITIAL>"~" return (MKAP);
<INITIAL>"-" return (SUB);
<INITIAL>"|" return(PIPE);
<INITIAL>"&" return(AMP);
<INITIAL>"=" return(LD);
<INITIAL>"==" return(EQ);
<INITIAL>"!=" return(NE);
<INITIAL>">" return(GT);
<INITIAL>">=" return(GE);
<INITIAL>"<" return(LT);
<INITIAL>"<=" return(LE);
<INITIAL>"+" return (ADD);
<INITIAL>"*" return (MUL);
<INITIAL>"/" return (DIV);
<INITIAL>"%" return (MOD);
<INITIAL>"_" return (ANY);
<INITIAL>"?" return (QUE);
<INITIAL>"int" return(INT);
<INITIAL>"let" return(LET);
<INITIAL>"in" return(IN);
<INITIAL>"end" return(END);
<INITIAL>"where" return(WHERE);
<INITIAL>"interface" return(INTERFACE);
<INITIAL>"prnat" return(PRNAT);
<INITIAL>"free" return(FREE);
<INITIAL>"exit" return(EXIT);
<INITIAL>"rand" return(RAND);
<INITIAL>"const" return(DEF);
<INITIAL>"use" return(USE);
<INITIAL>"*L" return(ANNOTATE_L);
<INITIAL>"*R" return(ANNOTATE_R);
<INITIAL>[a-z][a-zA-Z0-9_'\.]* { yylval.chval = strdup(yytext);
         return (NAME);}
<INITIAL>[_A-Z][a-zA-Z0-9_'\.]* { yylval.chval = strdup(yytext);
         return (AGENT);}
<INITIAL>[0-9]+ { yylval.intval = atoi(yytext);
         return (INT_LITERAL);}
<INITIAL>"//"[^\n]* ; //comment
<INITIAL>"/*" BEGIN(COM_STATE);
<COM_STATE>. ;
<COM_STATE>\n ;
<COM_STATE>"*/" BEGIN INITIAL; //comment

<INITIAL>\r\n {op_br();}
<INITIAL>\n {op_br();}
<INITIAL>\r {op_br();}
<INITIAL>[ \t]+ ;
<INITIAL><<EOF>> {return END_OF_FILE;}
<INITIAL>\" {
    Parse_StringBuffer_reInit();
    BEGIN STRING_STATE;
}

<INITIAL>. {return yytext[0];}




<STRING_STATE>\"        {
    yylval.chval = strdup(Parse_closeStringBuffer());
    BEGIN INITIAL;
    return STRING_LITERAL;
}
<STRING_STATE>\n        {
//    Parse_addString('\n');
yyerror("Unterminated string");
BEGIN(INITIAL);
return DELIMITER;
}
<STRING_STATE>\\\"      Parse_addString('"');
<STRING_STATE>\\n       Parse_addString('\n');
<STRING_STATE>\\t       Parse_addString('\t');
<STRING_STATE>\\\\      Parse_addString('\\');
<STRING_STATE>.         Parse_addString(yytext[0]);
%%

void pushFP(FILE *fp) {
  yypush_buffer_state(yy_create_buffer(fp, YY_BUF_SIZE));
}

int popFP() {
  yypop_buffer_state();
  if (! YY_CURRENT_BUFFER ) {
    yyterminate();
    return 0;
  }
  return 1;
}


/*
static int file_input(char *buf, int max_size)
{
    int	ch;
    int	len;
    FILE *fp = yyin;


    if (feof(fp))
	return 0;

    for (len = 0; len < max_size; len++) {
	ch = getc(fp);
	buf[len] = ch;
	len++;
    }
    return len;
}
*/

/*
static int my_yyinput(char *buf, int max_size)
{
    int	result;
    int c = getchar();

    //http://www.cas.mcmaster.ca/~kahl/SE3E03/2006/flex/flex_13.html
    result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); 
    return result;
//    result = file_input(buf, max_size);




//    switch (clc_current_interpreter->input_mode) {
//      case CLC_TTY_INPUT_MODE:
//	result = tty_input(buf, max_size);
//	break;
//      case CLC_FILE_INPUT_MODE:
//	result = file_input(buf, max_size);
//	break;
//      default:
//	DBG_assert(0, ("bad default(%d).\n",
//		       clc_current_interpreter->input_mode));
//    }

    return result;
}
*/
