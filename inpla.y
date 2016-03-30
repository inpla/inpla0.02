%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sched.h>

#include "ast.h"


#include "timer.h" //#include <time.h>

#define COUNT_INTERACTION // interaction 数と実行時間のカウント用

int MaxThreadNum=1;

#ifdef THREAD
#include <pthread.h>
extern int pthread_setconcurrency(int concurrency); 

int ActiveThreadNum=0;


inline void lock(volatile int *aexclusion) {
  while (__sync_lock_test_and_set(aexclusion, 1))
    while (*aexclusion)
      ;
}
inline void unlock(volatile int *aexclusion) {
  __sync_lock_release(aexclusion); 
}

#endif

//#define YYDEBUG 1

#define VERSION "0.02"
#define BUILT_DATE  "16 Feb. 2016"

extern FILE *yyin;


typedef unsigned int IDTYPE;

/* id の 32bit目が 1 なら「使用可能」を意味する */
#define FLAG_AVAIL 0x01 << 31 
#define IS_FLAG_AVAIL(a) ((a) & FLAG_AVAIL)
#define SET_FLAG_AVAIL(a) ((a) = ((a) | FLAG_AVAIL))
#define TOGGLE_FLAG_AVAIL(a) ((a) = ((a) ^ FLAG_AVAIL))

typedef unsigned long VALUE;


typedef struct {
  IDTYPE id;
} Basic;


#define MAX_AGENT_PORT 5

#ifndef THREAD
typedef struct {
  Basic basic;
  VALUE port;
} Name;

typedef struct {
  Basic basic;
  VALUE port[MAX_AGENT_PORT];
} Agent;

#else
typedef struct {
  Basic basic;
  volatile VALUE port;
} Name;

typedef struct {
  Basic basic;
  volatile VALUE port[MAX_AGENT_PORT];
} Agent;
#endif

/*
#define VAL_HEAP_SIZE 10
typedef struct Val {
  Basic basic;
  union {
    int intval;
  } u;
} Val;
*/

#define FIXNUM_FLAG 0x01
#define INT2FIX(i) ((VALUE)(((long)(i) << 1) | FIXNUM_FLAG))
#define FIX2INT(i) ((int)(i) >> 1)
#define IS_FIXNUM(i) ((VALUE)(i) & FIXNUM_FLAG)


#define RAGENT(a) ((Agent *)(a))
#define RBASIC(a) ((Basic *)(a))
#define RNAME(a) ((Name *)(a))
//#define RVAL(a) ((Val *)(a))


typedef struct AP_tag {
  VALUE l, r;
} AP;

typedef struct APList_tag{  
  AP ap;
  struct APList_tag *next;
} APList;






void MakeRule(Ast *ast);
void EraseNameFromNameTable(char *key);
 
int hasname_in_allHash(VALUE keyname);
void puts_allHash();

void freeAgentRec(VALUE ptr);
void freeName(VALUE ptr);
void freeAgent(VALUE ptr);
unsigned int getAgentID(char *key);
void puts_name_port0(VALUE ptr);
void flush_name_port0(VALUE ptr);
void puts_name_port0_nat(VALUE ptr);
void puts_term(VALUE ptr);
void puts_aplist(APList *at);
void PushAPStack(VALUE l, VALUE r);

VALUE getNameHeap(char *key);

int exec(Ast *st);
int destroy(void);
int AstHeap_MakeAgent(int arity, char *name, int *port);
int AstHeap_MakeTerm(char *name);
int AstHeap_MakeName(char *name);

#define NULLP -1

// 1..1023: AGENT, 1024: NAME, 1025...2047: GNAME
#define ID_INT 0

// builtin を加えたら SymTable に登録することを忘れないように！
#define ID_TUPLE0 1
#define ID_TUPLE1 2
#define ID_TUPLE2 3
#define ID_TUPLE3 4
#define ID_TUPLE4 5
#define ID_TUPLE5 6
#define GET_TUPLEID(arity) (ID_TUPLE0+arity)
#define IS_TUPLEID(id) ((id >= ID_TUPLE0) && (id <= ID_TUPLE5))
#define GET_TUPLEARITY(id) (id - ID_TUPLE0)

#define ID_NIL 7
#define ID_CONS 8
#define IS_LISTID(id) ((id == ID_NIL) && (id == ID_CONS))


#define START_ID_OF_AGENT 10
//#define NUM_AGENTS 1024
#define NUM_AGENTS 256
#define ID_NAME NUM_AGENTS

#define IS_NAMEID(a) (a >= ID_NAME)



extern int yylex();
int yyerror();
#define YY_NO_INPUT
extern int yylineno;

#define MY_YYLINENO    // For error message when nested source files are used.
#ifdef MY_YYLINENO
 typedef struct InfoLinenoType_tag {
   char *fname;
   int yylineno;
   struct InfoLinenoType_tag *next;
 } InfoLinenoType;
static InfoLinenoType *InfoLineno;

#define initInfoLineno() InfoLineno = NULL;

void InfoLineno_Push(char *fname, int lineno) {
  InfoLinenoType *aInfo;
  aInfo = (InfoLinenoType *)malloc(sizeof(InfoLinenoType));
  if (aInfo == NULL) {
    printf("[InfoLineno]Malloc error\n");
    exit(-1);
  }
  aInfo->next = InfoLineno;
  aInfo->yylineno = lineno+1;
  aInfo->fname = strdup(fname);

  InfoLineno = aInfo;
}

void InfoLineno_Free() {
  InfoLinenoType *aInfo;
  free(InfoLineno->fname);
  aInfo = InfoLineno;
  InfoLineno = InfoLineno->next;
  free(aInfo);
}

void InfoLineno_AllDestroy() {
  //  InfoLinenoType *aInfo;
  while (InfoLineno != NULL) {
    InfoLineno_Free();
  }
}

#endif


extern void pushFP(FILE *fp);
extern int popFP();


static char *Errormsg = NULL;  // yyerror でメッセージが出ないように、ここに格納する


//#define YYDEBUG			1
//#define YYERROR_VERBOSE		1
//int yydebug = 1;

/*
extern void eat_to_newline(void);
void eat_to_newline(void)
{
    int c;
    while ((c = getchar()) != EOF && c != '\n')
        ;
}
*/

%}
%union{
  int intval;
  char *chval;
  Ast *ast;
}

%token <chval> NAME AGENT
%token <intval> INT_LITERAL
%token <chval> STRING_LITERAL
%token LP RP LC RC COMMA CROSS DELIMITER QUE
%token TO MKAP

%token ANNOTATE_L ANNOTATE_R

%token PIPE AMP LD EQ NE GT GE LT LE
%token ADD SUB MUL DIV MOD INT LET IN END ANY WHERE RAND DEF
%token INTERFACE PRNAT FREE EXIT
%token END_OF_FILE USE

%type <ast> body astterm astterm_item nameterm agentterm astparam astparams 
rule 
ap aplist valterm
stm stmlist_nondelimiter
stmlist 
expr additive_expr equational_expr relational_expr unary_expr
multiplicative_expr primary_expr agent_tuple agent_list agent_cons
bodyguard bodyguards bodyguards_withAny 
 //body 


 //%right LD
 //%right EQ
 //%left NE GE GT LT
 //%left ADD SUB
 //%left MULT DIV

%%
s     
: error DELIMITER { 
  yyclearin;
  yyerrok; 
  puts(Errormsg);
  free(Errormsg);
  ast_heapReInit();
  if (yyin == stdin) yylineno=0;
  //  YYACCEPT;
  YYABORT;
}
| DELIMITER { 
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
}
| body DELIMITER
{
  exec($1); // $1 is a list such as [stmlist, aplist]
  ast_heapReInit(); 
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
}
| rule DELIMITER { 
  MakeRule($1); 
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
}
| command {
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
}
;



// body は [stmlist, aplist] というリスト
body
: aplist { $$ = ast_makeList2(NULL, $1); }
| aplist WHERE stmlist_nondelimiter { $$ = ast_makeList2($3, $1);}
| aplist WHERE  { $$ = ast_makeList2(NULL, $1);}
| LET stmlist IN aplist END { $$ = ast_makeList2($2, $4);}
| LET stmlist DELIMITER IN aplist END { $$ = ast_makeList2($2, $5);}
| LET  IN aplist END { $$ = ast_makeList2(NULL, $3);}
| LC stmlist RC  aplist { $$ = ast_makeList2($2, $4);}
| LC stmlist DELIMITER RC aplist { $$ = ast_makeList2($2, $5);}
;

// rule は (AST_RULE (AST_AP agentL agentR) 
// [[guard1, stmlist1, aplist1],[guard2, stmlist2, aplist2],...])
rule
: astterm CROSS astterm TO body
{ $$ = ast_makeAST(AST_RULE, ast_makeAST(AST_AP,$1,$3), 
		   ast_makeList1(ast_makeCons(NULL, $5))); }

| astterm CROSS astterm TO 
{ $$ = ast_makeAST(AST_RULE, ast_makeAST(AST_AP, $1,$3),
		   ast_makeList1(ast_makeList3(NULL ,NULL, NULL))); } 

| astterm CROSS astterm bodyguards_withAny
{ $$ = ast_makeAST(AST_RULE, ast_makeAST(AST_AP, $1,$3), $4); }
;

command:
| FREE NAME DELIMITER
{ 
  flush_name_port0(getNameHeap($2)); 
}
| NAME DELIMITER
{ 
  puts_name_port0(getNameHeap($1)); puts(""); 
}
| PRNAT NAME DELIMITER
{ 
  puts_name_port0_nat(getNameHeap($2)); 
}
| INTERFACE DELIMITER
{ 
  puts_allHash(); 
}
| EXIT DELIMITER {destroy(); exit(0);}
| USE STRING_LITERAL DELIMITER {
  // http://flex.sourceforge.net/manual/Multiple-Input-Buffers.html
  yyin = fopen($2, "r");
  if (!yyin) {
    printf("Error: The file '%s' does not exist.\n", $2);
    free($2);
    yyin = stdin;

  } else {
#ifdef MY_YYLINENO
    InfoLineno_Push($2, yylineno+1);
    yylineno = 0;
#endif  

    pushFP(yyin);
  }
}
| error END_OF_FILE {}
| END_OF_FILE {
  if (!popFP()) {
    destroy(); exit(-1);
  }
#ifdef MY_YYLINENO
  yylineno = InfoLineno->yylineno;
  InfoLineno_Free();
  destroy();
#endif  


}
| DEF AGENT LD INT_LITERAL DELIMITER {
  ast_recordConst($2,$4);
 }
;

bodyguard
: PIPE expr TO body { $$ = ast_makeCons($2, $4); }
;

bodyguards
: bodyguard { $$ = ast_makeList1($1); }
| bodyguards bodyguard { $$ = ast_addLast($1, $2); }
;


bodyguards_withAny
: bodyguards PIPE ANY TO body { $$ = ast_addLast($1, ast_makeCons(NULL, $5)); }
;


// AST -----------------
astterm
: LP ANNOTATE_L RP astterm_item
{ $$=ast_makeAST(AST_ANNOTATION_L, $4, NULL); }
| LP ANNOTATE_R RP astterm_item
{ $$=ast_makeAST(AST_ANNOTATION_R, $4, NULL); }
| astterm_item
;


astterm_item
      : agentterm
      | agent_tuple
      | agent_list
      | nameterm
      | valterm
      | agent_cons
;

agent_cons
: '[' astterm PIPE astterm ']' 
{$$ = ast_makeAST(AST_OPCONS, NULL, ast_makeList2($2, $4)); }
;

agent_list
: '[' ']' { $$ = ast_makeAST(AST_NIL, NULL, NULL); }
| '[' astparams ']' { $$ = ast_paramToCons($2); }
;

agent_tuple
: astparam { $$ = ast_makeTuple($1);}
;

nameterm
: NAME {$$=ast_makeAST(AST_NAME, ast_makeSymbol($1), NULL);}

agentterm
: AGENT astparam
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), $2); }
| AGENT
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL); }
;

astparam  :
LP RP { $$ = NULL; }
| LP astparams RP { $$ = $2; }
;

astparams
: astterm { $$ = ast_makeList1($1); }
| astparams COMMA astterm { $$ = ast_addLast($1, $3); }
;

ap
: astterm MKAP astterm { $$ = ast_makeAST(AST_AP, $1, $3); }
;

aplist
: ap { $$ = ast_makeList1($1); }
| aplist COMMA ap { $$ = ast_addLast($1, $3); }
;

stm
: nameterm LD expr { $$ = ast_makeAST(AST_LD, $1, $3); }
 
stmlist
: stm { $$ = ast_makeList1($1); }
| stmlist DELIMITER stm { $$ = ast_addLast($1, $3); }

stmlist_nondelimiter
: stm { $$ = ast_makeList1($1); }
| stmlist_nondelimiter stm { $$ = ast_addLast($1, $2); }


expr
: equational_expr
;

equational_expr
: relational_expr
| equational_expr EQ relational_expr { $$ = ast_makeAST(AST_EQ, $1, $3); }
| equational_expr NE relational_expr { $$ = ast_makeAST(AST_NE, $1, $3); }

relational_expr
: additive_expr
| relational_expr LT additive_expr { $$ = ast_makeAST(AST_LT, $1, $3); }
| relational_expr LE additive_expr { $$ = ast_makeAST(AST_LE, $1, $3); }
| relational_expr GT additive_expr { $$ = ast_makeAST(AST_LT, $3, $1); }
| relational_expr GE additive_expr { $$ = ast_makeAST(AST_LE, $3, $1); }
;

additive_expr
: multiplicative_expr
| additive_expr ADD multiplicative_expr { $$ = ast_makeAST(AST_PLUS, $1, $3); }
| additive_expr SUB multiplicative_expr { $$ = ast_makeAST(AST_SUB, $1, $3); }
;

multiplicative_expr
: unary_expr
| multiplicative_expr MUL primary_expr { $$ = ast_makeAST(AST_MUL, $1, $3); }
| multiplicative_expr DIV primary_expr { $$ = ast_makeAST(AST_DIV, $1, $3); }
| multiplicative_expr MOD primary_expr { $$ = ast_makeAST(AST_MOD, $1, $3); }


unary_expr
: primary_expr
| SUB primary_expr { $$ = ast_makeAST(AST_UNM, $2, NULL); }
| RAND LP primary_expr RP { $$ = ast_makeAST(AST_RAND, $3, NULL); }
;

primary_expr
: nameterm { $$ = $1;}
| INT_LITERAL { $$ = ast_makeInt($1); }
| LP expr RP { $$ = $2; }
;

valterm
: INT NAME { $$ = ast_makeAST(AST_INTNAME, ast_makeSymbol($2), NULL); }
| INT_LITERAL { $$ = ast_makeInt($1); }
| SUB INT_LITERAL { $$ = ast_makeInt(-1*($2)); }
;
%%



int yyerror(char *s) {
  extern char *yytext;
  char msg[256];
  //printf("%s\nSorry, this version does not support error recovery.\n",s);
  //  printf("%s\n",s);

#ifdef MY_YYLINENO
  if (InfoLineno != NULL) {
    sprintf(msg, "%s:%d: %s near token '%s'.\n", 
	  InfoLineno->fname, yylineno+1, s, yytext);
  } else {
    sprintf(msg, "%d: %s near token '%s'.\n", 
	  yylineno, s, yytext);
  }
#else
  sprintf(msg, "%d: %s near token '%s'.\n", yylineno, s, yytext);
#endif

  Errormsg = strdup(msg);  
  //  printf("%d: %s near token '%s'\n", yylineno, s, yytext);

  if (yyin != stdin) {
    //    puts(Errormsg);
    destroy(); 
    //    exit(0);
  }

  return 0;
}




/**************************************
 TABLE for SYMBOLS
**************************************/
typedef struct {
  char *name;
  int arity;
} SymTableT;

#define SYMTABLE_SIZE  NUM_AGENTS*2 // AGENT + NAME
static SymTableT SymTable[SYMTABLE_SIZE];

static int NextAgentId, NextGnameId;
void SymTable_Init() {
  int i;
  NextAgentId = START_ID_OF_AGENT;
  NextGnameId = ID_NAME;
  /* 0 is name, 1 is meta_name(wire), ..,
     START_ID_OF_AGENT is a predefined, 
     START_ID_OF_AGENT+1, ... are IDs for user defined agents */


  for (i=0; i<SYMTABLE_SIZE; i++) {
    SymTable[i].arity = -1;
    SymTable[i].name = NULL;
  }

  // built-in agent
  SymTable[ID_TUPLE0].arity = 0;
  SymTable[ID_TUPLE1].arity = 1;
  SymTable[ID_TUPLE2].arity = 2;
  SymTable[ID_TUPLE3].arity = 3;
  SymTable[ID_TUPLE4].arity = 4;
  SymTable[ID_TUPLE5].arity = 5;
  SymTable[ID_NIL].arity = 0;
  SymTable[ID_CONS].arity = 2;

  SymTable[ID_TUPLE0].name = "()";
  SymTable[ID_TUPLE1].name = "(_)";
  SymTable[ID_TUPLE2].name = "(_,_)";
  SymTable[ID_TUPLE3].name = "(_,_,_)";
  SymTable[ID_TUPLE4].name = "(_,_,_,_)";
  SymTable[ID_TUPLE5].name = "(_,_,_,_,_)";
  SymTable[ID_NIL].name = "[]";
  SymTable[ID_CONS].name = "[_|_]";




}

void setNameToSymTable( int id, char *symname)
{
  if (id > SYMTABLE_SIZE) {
    printf("Error: The given id %d was beyond of the size of SymTable (%d)\n",
	   id, SYMTABLE_SIZE);
    exit(-1);
  }
  SymTable[id].name = symname;
}


void setArityToSymTable( int id, int arity)
{
  if ((SymTable[id].arity == -1) || (SymTable[id].arity == arity)) {
    SymTable[id].arity = arity;
  } else {
    printf("Warning: The arity of the agent '%s' was re-defined as %d (the former was %d).\n",  
	   SymTable[id].name, arity, SymTable[id].arity);
    SymTable[id].arity = arity;
  } 
}


char *getNameFromSymTable( int id )
{
  return SymTable[id].name;
}

int getArityFromSymTable( int id )
{
  return SymTable[id].arity;
}

int getNewAgentId() {
  NextAgentId++;
  if (NextAgentId > ID_NAME) {
    printf("ERROR: The number of agents exceeded the size of agents in SYMTABLE (%d)\n",
	 ID_NAME);
    exit(-1);
  }
  return(NextAgentId);
}

int getNewGnameID() {
  NextGnameId++;
  if (NextAgentId > SYMTABLE_SIZE) {
    printf("ERROR: The number of agents exceeded the size of names in SYMTABLE (%d)\n",
	 ID_NAME);
    exit(-1);
  }
  return(NextGnameId);
}



/**********************************
  Heap
*********************************/

typedef struct Heap_tag {
  VALUE *heap;
  int lastAlloc;
  unsigned int size;
} Heap;  


/**********************************
  VIRTUAL MACHINE 
*********************************/
#define VM_LOCALVAR_SIZE 300 - (MAX_AGENT_PORT*2 + 2)
                              /* ap列、または、一つのrule に出現するシンボルに
				 対して agentReg を割り当てるため、
				 大きく取っておいた方が良い。*/

#define OFFSET_META_L(a) VM_LOCALVAR_SIZE+a
#define OFFSET_META_R(a) VM_LOCALVAR_SIZE+MAX_AGENT_PORT+a
#define OFFSET_ANNOTATE_L VM_LOCALVAR_SIZE+MAX_AGENT_PORT*2
#define OFFSET_ANNOTATE_R VM_LOCALVAR_SIZE+MAX_AGENT_PORT*2+1


typedef struct {
  // AgentHeap, nameHeap, valHeap
  //  Heap agentHeap, nameHeap, valHeap;
  Heap agentHeap, nameHeap;

  // APStack
  AP *apStack;
  int nextPtr_apStack;
  unsigned int apStack_size;


  // code execution
  VALUE agentReg[VM_LOCALVAR_SIZE+(MAX_AGENT_PORT*2 + 2)];

#ifdef COUNT_INTERACTION
  unsigned int NumberOfInteraction;
  //  unsigned int id;
#endif

} VirtualMachine;

#ifndef THREAD
static VirtualMachine VM;
#endif



/*************************************
 AGENT Heap
**************************************/

//#define MALLOC



void VM_InitBuffer(VirtualMachine *vm, int size) {

#ifndef MALLOC
  int i;

  vm->agentHeap.lastAlloc = size-1;
  vm->agentHeap.heap = (VALUE *)malloc(sizeof(Agent)*size);
  vm->agentHeap.size = size;
  if (vm->agentHeap.heap == (VALUE *)NULL) {
      printf("[Heap]Malloc error\n");
      exit(-1);
  }
  for (i=0; i<size; i++) {
    SET_FLAG_AVAIL(((Agent *)(vm->agentHeap.heap))[i].basic.id);
  }


  //vm->nameHeap.lastAlloc = size-1;
  vm->nameHeap.lastAlloc = 0;
  vm->nameHeap.heap = (VALUE *)malloc(sizeof(Name)*size);
  vm->nameHeap.size = size;
  if (vm->nameHeap.heap == (VALUE *)NULL) {
      printf("[Heap]Malloc error\n");
      exit(-1);
  }
  for (i=0; i<size; i++) {
    ((Name *)(vm->nameHeap.heap))[i].basic.id = ID_NAME;
    SET_FLAG_AVAIL(((Name *)(vm->nameHeap.heap))[i].basic.id);
    //    ((Name *)(vm->nameHeap.heap))[i].name = NULL;
  }


  /*
  vm->valHeap.lastAlloc = VAL_HEAP_SIZE-1;
  vm->valHeap.heap = (VALUE *)malloc(sizeof(Agent)*VAL_HEAP_SIZE);
  vm->valHeap.size = VAL_HEAP_SIZE;
  if (vm->valHeap.heap == (VALUE *)NULL) {
      printf("[Val]Malloc error\n");
      exit(-1);
  }
  for (i=0; i<VAL_HEAP_SIZE; i++) {
    SET_FLAG_AVAIL(((Val *)(vm->valHeap.heap))[i].basic.id);
  }
  */

#endif
}  




VALUE myallocAgent(Heap *hp) {

#ifdef MALLOC
  Agent *ptr;
  ptr = malloc(sizeof(Agent));
  return ptr;
#else

  int i,idx;

  idx = hp->lastAlloc;

  for (i=0; i < hp->size; i++) {
    if (!IS_FLAG_AVAIL(((Agent *)hp->heap)[idx].basic.id)) {
      idx++;
      if (idx >= hp->size) {
	idx -= hp->size;
      }
      continue;
    }
    TOGGLE_FLAG_AVAIL(((Agent *)hp->heap)[idx].basic.id);
    hp->lastAlloc = idx;
    return (VALUE)&(((Agent *)hp->heap)[idx]);
  }

  printf("\nCritical ERROR: All %d term cells have been consumed.\n", hp->size);
  printf("You should have more term cells with -c option.\n");
  exit(-1);

#endif
  
}


VALUE myallocName(Heap *hp) {

#ifdef MALLOC
  Agent *ptr;
  ptr = malloc(sizeof(Name));
  return ptr;
#else

  int i,idx;

#ifndef THREAD
  idx = hp->lastAlloc-1;
  (idx<0) ?(idx=0) : 0;
#else
  idx = hp->lastAlloc;
#endif


  for (i=0; i < hp->size; i++) {
    if (!IS_FLAG_AVAIL(((Name *)hp->heap)[idx].basic.id)) {
      idx++;
      if (idx >= hp->size) {
	idx -= hp->size;
      }
      continue;
    }
    TOGGLE_FLAG_AVAIL(((Name *)hp->heap)[idx].basic.id);
    hp->lastAlloc = idx;
    return (VALUE)&(((Name *)hp->heap)[idx]);
  }

  printf("\nCritical ERROR: All %d name cells have been consumed.\n", hp->size);
  printf("You should have more term cells with -c option.\n");
  exit(-1);

#endif
  
}


unsigned long getNumOfAvailNameHeap(Heap *hp) {
  int i;
  unsigned long total=0;
  for (i=0; i < hp->size; i++) {
    if (IS_FLAG_AVAIL( ((Name *)hp->heap)[i].basic.id)) {
      total++;
    }
  }
  return total;
}
unsigned long getNumOfAvailAgentHeap(Heap *hp) {
  int i;
  unsigned long total=0;
  for (i=0; i < hp->size; i++) {
    if (IS_FLAG_AVAIL( ((Agent *)hp->heap)[i].basic.id)) {
      total++;
    }
  }
  return total;
}




/*
VALUE myallocVal(Heap *hp) {

#ifdef MALLOC
  Agent *ptr;
  ptr = malloc(sizeof(Agent));
  return ptr;
#else

  int i,idx;

  idx = hp->lastAlloc;

  for (i=0; i < hp->size; i++) {
    if (!IS_FLAG_AVAIL(((Val *)hp->heap)[idx].basic.id)) {
      idx++;
      if (idx >= hp->size) {
	idx -= hp->size;
      }
      continue;
    }
    TOGGLE_FLAG_AVAIL(((Val *)hp->heap)[idx].basic.id);
    hp->lastAlloc = idx;
    return (VALUE)&(((Val *)hp->heap)[idx]);
  }

  printf("\nCritical ERROR: All %d term cells have been consumed.\n", hp->size);
  printf("You should have more term cells with -c option.\n");
  exit(-1);

#endif
  
}
*/



void myfree(VALUE ptr) {

#ifdef MALLOC

  if (ptr == NULL) return;
  free(ptr);
  ptr = NULL;
#else

  TOGGLE_FLAG_AVAIL(RBASIC(ptr)->id);
#endif

}


VALUE makeAgent(VirtualMachine *vm, int id) {
  VALUE ptr;
  ptr = myallocAgent(&vm->agentHeap);
  
  RAGENT(ptr)->basic.id = id;
  return ptr;
}



VALUE makeName(VirtualMachine *vm) {
  VALUE ptr;
  
  ptr = myallocName(&vm->nameHeap);
  //  RAGENT(ptr)->basic.id = ID_NAME;
  RNAME(ptr)->port = (VALUE)NULL;

  return ptr;
}


/*
VALUE makeVal_int(VirtualMachine *vm, int num) {
  VALUE ptr;
  ptr = myallocVal(&vm->agentHeap);
  
  RBASIC(ptr)->id = ID_INT;
  RVAL(ptr)->u.intval = num;
  return ptr;
}
*/


/**********************************
  Counter for Interaction times
*********************************/
#ifdef COUNT_INTERACTION
int VM_GetInteractionNum(VirtualMachine *vm) {
  return(vm->NumberOfInteraction);
}

void VM_ClearInteractionNum(VirtualMachine *vm) {
  vm->NumberOfInteraction = 0;
}
#endif




/**************************************
 Seqence of s
**************************************/

void puts_aplist(APList *at) {
  while (at != NULL) {
    puts_term(at->ap.l);
    printf("~");
    puts_term(at->ap.r);
    printf(",");
    at=at->next;
  }
}





//-----------------------------------------
// Pretty printing for terms
//-----------------------------------------

static VALUE ShowNameHeap=(VALUE)NULL; // showname で表示するときの cyclic 防止
// showname 時に、呼び出し変数の heap num を入れておく。
// showname 呼び出し以外は NULLPに。

void puts_name(VALUE ptr) {

  if ((ptr == (VALUE)NULL)||(RBASIC(ptr)->id == NULLP)) {
    printf("[NULL]");
    return;
  }

  if (RBASIC(ptr)->id == ID_NAME) {
      printf("<var%lu>", (unsigned long)(ptr));
  } else if (IS_NAMEID(RBASIC(ptr)->id)) {
      printf("%s", getNameFromSymTable(RBASIC(ptr)->id));
  } else {
    puts_term(ptr);
  }
}
  

#define PRETTY_VAR
#ifdef PRETTY_VAR
typedef struct PrettyList_tag {
  VALUE id;
  char *name;
  struct PrettyList_tag *next; 
} PrettyList;

typedef struct {
  PrettyList *list;
  int alphabet;
  int index;
  char namebuf[10];
} PrettyStruct;

PrettyStruct Pretty;

#define MAX_PRETTY_ALPHABET 26
void Pretty_init(void) {
  Pretty.alphabet = -1;
  Pretty.list = NULL;
  Pretty.index = 1;
}

PrettyList *PrettyList_new(void) {
  PrettyList *alist;
  alist = malloc(sizeof(PrettyList));
  if (alist == NULL) {
    printf("[PrettyList] Malloc error\n");
    exit(-1);
  }
  return alist;
}

char *Pretty_newName(void) {
  Pretty.alphabet++;
  if (Pretty.alphabet >= MAX_PRETTY_ALPHABET) {
    Pretty.alphabet = 0;
    Pretty.index++;
  }
  sprintf(Pretty.namebuf, "%c%d", 'a'+Pretty.alphabet, Pretty.index);
  return(Pretty.namebuf);
}

PrettyList *PrettyList_recordName(VALUE a) {
  PrettyList *alist;
  alist = PrettyList_new();
  alist->id = a;
  alist->name = strdup(Pretty_newName());
  alist->next = Pretty.list;
  Pretty.list = alist;
  return (alist);
}

char *Pretty_Name(VALUE a) {
  PrettyList *alist;
  if (Pretty.list == NULL) {
    alist = PrettyList_recordName(a);
    Pretty.list = alist;
    return (alist->name);
  } else {
    PrettyList *at = Pretty.list;
    while (at != NULL) {
      if (at->id == a) {
	return (at->name);
      }
      at = at->next;
    }

    alist = PrettyList_recordName(a);
    Pretty.list = alist;
    return (alist->name);    
  }
}
#endif



static int PutIndirection = 0;
void puts_term(VALUE ptr) {
  if (IS_FIXNUM(ptr)) {
    printf("%d", FIX2INT(ptr));
    return;
  } else if ((RBASIC(ptr) == NULL)||(RBASIC(ptr)->id == NULLP)) {
    printf("[NULL]");
    return;
  }

  if (IS_NAMEID(RBASIC(ptr)->id)) {
    if (RNAME(ptr)->port == (VALUE)NULL) {
      if (RBASIC(ptr)->id == ID_NAME) {
#ifndef PRETTY_VAR
	printf("<var%lu>", (unsigned long)(ptr));
#else
	printf("%s", Pretty_Name(ptr));
#endif
      } else {
	//printf("%s", RNAME(ptr)->name);
	printf("%s", getNameFromSymTable(RBASIC(ptr)->id));
      }
    } else {
      if (ptr == ShowNameHeap) {
	printf("<Warning:%s is cyclic>", getNameFromSymTable(RBASIC(ptr)->id));
	return;
      } else {
	if (PutIndirection) {
	  if (getNameFromSymTable(RBASIC(ptr)->id) == NULL) {
	  } else {
	    printf("%s->", getNameFromSymTable(RBASIC(ptr)->id));
	  }
	}
	puts_term(RNAME(ptr)->port);
      }
    }
  } else if (RBASIC(ptr)->id == NULLP) {
    printf("<NULL>");

    /*
  } else if (RBASIC(ptr)->id == ID_INT) {
    printf("%d", RVAL(ptr)->u.intval);
    */

  } else if (IS_TUPLEID(RBASIC(ptr)->id)) {
    int i, arity;
    arity = GET_TUPLEARITY(RBASIC(ptr)->id);
    printf("(");
    for (i=0; i<arity; i++) {
      puts_term(RAGENT(ptr)->port[i]);
      if (i != arity - 1) {
	printf(",");
      }
    }
    printf(")");

  } else if (RBASIC(ptr)->id == ID_NIL) {
    printf("[]");

  } else if (RBASIC(ptr)->id == ID_CONS) {
    printf("[");

    while (ptr != (VALUE)NULL) {
      puts_term(RAGENT(ptr)->port[0]);
      ptr = RAGENT(ptr)->port[1];
      while (IS_NAMEID(RBASIC(ptr)->id)) {
	ptr = RNAME(ptr)->port;
      }	
      if (RBASIC(ptr)->id == ID_NIL) {
	printf("]");
	break;
      }
      printf(",");
    }

  } else {
    // Agent
    int i, arity;

    arity = getArityFromSymTable(RAGENT(ptr)->basic.id);
    printf("%s", getNameFromSymTable(RAGENT(ptr)->basic.id));
    if (arity != 0) {
      printf("(");
    }
    for (i=0; i<arity; i++) {
      puts_term(RAGENT(ptr)->port[i]);
      if (i != arity - 1) {
	printf(",");
      }
    }
    if (arity != 0) {
      printf(")");
    }
  }
}


void puts_name_port0(VALUE ptr) {
  
  if (ptr == (VALUE)NULL) {
    //printf("<NUll num=NULLP>");
    printf("<NON-DEFINED>");
  } else if (RBASIC(ptr)->id == NULLP) {
    //printf("<NULL Heap.id=NULLP>");
    printf("<NON-DEFINED>");
  } else if (IS_NAMEID(RBASIC(ptr)->id)) {
    if (RNAME(ptr)->port == (VALUE)NULL) {
      printf("<EMPTY>");
    } else {
      ShowNameHeap=ptr;
      puts_term(RNAME(ptr)->port);
      ShowNameHeap=(VALUE)NULL;      
    }
  } else {
    puts("ERROR: it is not a name.");
  }
  
}


void flush_name_port0(VALUE ptr) {
  if (ptr != (VALUE)NULL) {
    if (hasname_in_allHash(ptr)) {
      return;
    }

    if (RNAME(ptr)->port == (VALUE)NULL) {
      freeName(ptr);
    } else {
      ShowNameHeap=ptr;
      freeAgentRec(RNAME(ptr)->port);
      freeName(ptr);
      ShowNameHeap=(VALUE)NULL;
    }      
  }

#ifdef CELL_USE_VERBOSE
  printf("(%lu agents and %lu names cells are used.)\n", 
	 VM.agentHeap.size - getNumOfAvailAgentHeap(&VM.agentHeap),
	 VM.nameHeap.size - getNumOfAvailNameHeap(&VM.nameHeap));
#endif

}

void puts_name_port0_nat(VALUE a1) {
  int result=0;
  int idS, idZ;
  idS = getAgentID("S");
  idZ = getAgentID("Z");
  
  if (a1 == (VALUE)NULL) {
    printf("<NUll>");
  } else if (RBASIC(a1)->id == NULLP) {
    printf("<NULL>");
  } else if (!IS_NAMEID(RBASIC(a1)->id)) {
    printf("<NON-NAME>");
  } else {
    if (RNAME(a1)->port == (VALUE)NULL) {
      printf("<EMPTY>");
    } else {
      
      a1=RNAME(a1)->port;
      while (RBASIC(a1)->id != idZ) {
	if (RBASIC(a1)->id == idS) {
	  result++;
	  a1=RAGENT(a1)->port[0];
	} else if (IS_NAMEID(RBASIC(a1)->id)) {
	  a1=RNAME(a1)->port;
	} else {
	  puts("ERROR: puts_name_port0_nat");
	  exit(-1);
	}
      }
      printf("%d\n", result);
    }
  }  
  
}

void freeAgent(VALUE ptr) {
  
  if (ptr == (VALUE)NULL) return;

  myfree(ptr);
}

void freeName(VALUE ptr) {
  if (ptr == (VALUE)NULL) {puts("NULL in freeName"); return;}

  if (RBASIC(ptr)->id == ID_NAME) {
    myfree(ptr);
  } else {    
    // Gname
    EraseNameFromNameTable(getNameFromSymTable(RBASIC(ptr)->id));
    RBASIC(ptr)->id = ID_NAME;
    myfree(ptr);
  }

    /*
    if (ptr->id != ID_NAME) {
      puts("Error: It is not a name");
      puts_term(ptr);
      exit(-1);
    }
    */


}


void freeAgentRec(VALUE ptr) {

 loop:  
  if ((IS_FIXNUM(ptr)) || (ptr == (VALUE)NULL) || (RBASIC(ptr)->id == NULLP)) {
    return;
  } else if (IS_NAMEID(RBASIC(ptr)->id)) {
    if (ptr == ShowNameHeap) return;

    if (RNAME(ptr)->port != (VALUE)NULL) {
      VALUE port = RNAME(ptr)->port;
      freeName(ptr);
      ptr = port; goto loop;
    } else {
      freeName(ptr);
    }
  } else {
    if (RBASIC(ptr)->id == ID_CONS) {
      if (IS_FIXNUM(RAGENT(ptr)->port[0])) {
	VALUE port1 = RAGENT(ptr)->port[0];
	freeAgent(ptr);
	ptr = port1; goto loop;
      }
    }


    int arity;
    arity = getArityFromSymTable(RAGENT(ptr)->basic.id);
    if (arity == 1) {
      VALUE port1 = RAGENT(ptr)->port[0];
      freeAgent(ptr);
      ptr = port1; goto loop;
    } else {
      freeAgent(ptr);
      //      printf(" .");
      int i;
      for(i=0; i<arity; i++) {
	freeAgentRec(RAGENT(ptr)->port[i]);
      }
    }
  }
}



/**************************************
 HASH TABLE for NAME 
**************************************/
typedef struct NameList {
  char *name;
  int id;
  VALUE heap;
  struct NameList *next;
} NameList;

NameList *newNameList() {
  NameList *alist;
  alist = malloc(sizeof(NameList));
  if (alist == NULL) {
    printf("Malloc error\n");
    exit(-1);
  }
  return alist;
}

#define NAME_HASHSIZE  127
static NameList *NameHashTable[NAME_HASHSIZE];  /* ハッシュテーブル本体 */

void InitNameHashTable() {
  int i;
  for (i=0; i<NAME_HASHSIZE; i++) {
    NameHashTable[i] = NULL;
  }
}

int getHash( char *key ) 
{
  int len;
  int ret;
  
  /* 0文字目、最後の文字、真中の文字の数値を加算し */
  len = strlen( key );
  ret  = key[0];
  ret += key[len-1];
  ret += key[(len-1)/2];
  /* ハッシュテーブルのサイズ（山の数）で modulo する。*/
  return ret % NAME_HASHSIZE;
}


VALUE opMakeName(VirtualMachine *vm, char *key) {
  int hash;
  NameList *add;
  hash = getHash( key );
    
  if( NameHashTable[hash] == NULL ) {  /* もしハッシュテーブルが空ならば */
    add = newNameList();             /* データノードを作成し */
    add->name = key;

    //    add->id = ID_NAME;
    add->id = getNewGnameID();
    setNameToSymTable(add->id, key);
    add->heap = makeName(vm);
    RBASIC(add->heap)->id = add->id;

    add->next = NULL;
    NameHashTable[hash] = add;        /* 単にセット */

    return(add->heap);
  } else {  /* 線形探査が必要 */

    NameList *at = NameHashTable[hash];  /* 先頭をセット */
    while( at != NULL ) {
      if( strcmp( at->name, key ) == 0 ) {  /* すでにあれば... */
	
	//	if ((at->id == NULLP) || (at->heap == (VALUE)NULL)) {
	if (at->id == NULLP) {


	  // これは必要？
	  /*
	  if ((at->heap != (VALUE)NULL) && 
	      (RNAME((at->heap))->port != (VALUE)NULL)) {
	    printf("Error: %s already exists.\n", key);
	    exit(-1);
	  }
	  */

	  /* 新しい変数 */
	  //	  at->id=ID_NAME;
	  at->id = getNewGnameID();
	  setNameToSymTable(at->id, key);
	  at->heap = makeName(vm);
	  RBASIC(at->heap)->id = at->id;
	  //	  RAGENT(at->heap)->basic.id = ID_NAME;

	  return at->heap;

	  /*
	} else if (RBASIC(at->heap)->id == NULLP) {
	  //	  at->id=ID_NAME;
	  add->id = getNewGnameID();
	  setNameToSymTable(add->id, key);
	  at->heap=makeName(vm);
	  RNAME(add->heap)->id = add->id;
	  RNAME(add->heap)->name = (char *)strdup( key );
	  //Heap[at->heap].name = (char *)strdup( key );
	  //	  RAGENT(at->heap)->id = ID_NAME;
	  */

	} else {
	  /* NULLP でなければ、既に存在している変数 */
	  at->id = NULLP;  /* この ID は hash テーブルの識別用 */
	  /* 一度参照されるごとに、NULLP へと戻るようになる */
	  /* 実態である at->heap は NULL にはならないようにして、
	     名前の検索で、実態が参照できるようにしている */
	  return at->heap;
	}
      }
      at = at->next;  /* 次のチェーンを辿る */
    }
    /* key がなかった → 先頭に追加 */
    add = newNameList();  /* malloc ＋エラー処理 */
    add->name = key;  
    //    add->id = ID_NAME;
    add->id = getNewGnameID();
    setNameToSymTable(add->id, key);
    add->heap = makeName(vm);
    RBASIC(add->heap)->id = add->id;
    add->next = NameHashTable[hash];  /* 以前の先頭を自分の次にする */
    NameHashTable[hash] = add;        /* 先頭に追加 */
    //    printf("DEBUG: %s is created at Heap[%d]\n", key, add->heap);
    
    return (add->heap);
  }
}



void EraseNameFromNameTable(char *key) {
  int hash;
  //int heap;
  //NameList *add;
  
  if (key == NULL) return;
  hash = getHash( key );
  
  if( NameHashTable[hash] == NULL ) {  /* もしハッシュテーブルが空ならば */
    return;
  } else {  /* 線形探査が必要 */
    NameList *at = NameHashTable[hash];  /* 先頭をセット */
    while( at != NULL ) {
      if( strcmp( at->name, key ) == 0 ) {  /* すでにあれば... */
	
	at->heap = (VALUE)NULL;
	at->id = NULLP;
	//printf("%s's heap is changed into NULLP\n", key);
	return;
      }
      at = at->next;  /* 次のチェーンを辿る */
    }
    /* key がなかった → 先頭に追加 */
    return;
  }
}



VALUE getNameHeap(char *key) {
  int hash;
  //int heap;
  //NameList *add;
  hash = getHash( key );
  
  if( NameHashTable[hash] == NULL ) {  /* もしハッシュテーブルが空ならば */
    return((VALUE)NULL);
  } else {  /* 線形探査が必要 */
    NameList *at = NameHashTable[hash];  /* 先頭をセット */
    while( at != NULL ) {
      if( strcmp( at->name, key ) == 0 ) {  /* すでにあれば... */
	if (at->heap != (VALUE)NULL) {
	  /* NULLP でなければ、既に存在している変数 */
	  return at->heap;
	} else {
	  return (VALUE)NULL;
	}
      }
      at = at->next;  /* 次のチェーンを辿る */
    }
    /* key がなかった */
    return (VALUE)NULL;
  }
}


IDTYPE getAgentID(char *key) {
  int hash;
  //int heap;
  NameList *add;


  hash = getHash( key );
  
  if( NameHashTable[hash] == NULL ) {  /* もしハッシュテーブルが空ならば */
    add = newNameList();             /* データノードを作成し */
    add->name = key;
    add->id = getNewAgentId();
    setNameToSymTable(add->id, add->name);
    add->heap = (VALUE)NULL;
    add->next = NULL;
    NameHashTable[hash] = add;        /* 単にセット */
    return(add->id);
  } else {  /* 線形探査が必要 */
    NameList *at = NameHashTable[hash];  /* 先頭をセット */
    while( at != NULL ) {
      if( strcmp( at->name, key ) == 0 ) {  /* すでにあれば... */
	return(at->id);
      }
      at = at->next;  /* 次のチェーンを辿る */
    }
    /* key がなかった → 先頭に追加 */
    add = newNameList();  /* malloc ＋エラー処理 */
    add->name = key;  
    add->id = getNewAgentId();
    setNameToSymTable(add->id, add->name);
    add->heap = (VALUE)NULL;
    add->next = NameHashTable[hash];  /* 以前の先頭を自分の次にする */
    NameHashTable[hash] = add;        /* 先頭に追加 */
    return(add->id);
  }
}


// Whether a given 'term' has a name node 'keyname'.
int has_keyname(VALUE keyname, VALUE term) {
  int i;

  if ((term == (VALUE)NULL) || (IS_FIXNUM(term))) return 0;

  if (IS_NAMEID(RBASIC(term)->id)) {
    if (term == keyname) {
      return 1;
    } else {
      if (RNAME(term)->port == (VALUE)NULL) {
	return 0;
      } else {
	return has_keyname(keyname, RNAME(term)->port);
      }
    }
      
  } else {
    // general term
    int arity;
    arity = getArityFromSymTable(RAGENT(term)->basic.id);
    for (i=0; i < arity; i++) {
      if (has_keyname(keyname, RAGENT(term)->port[i]) ) {
	return 1;
      }
    }
    return 0;
  }
}


int hasname_in_allHash(VALUE keyname) {
  int i, result=0;
  NameList *at;

  for (i=0; i<NAME_HASHSIZE; i++) {
    at = NameHashTable[i];
    while (at != NULL) {
      if (at->heap != (VALUE)NULL) {
	if (at->heap != keyname)  {
	  if (has_keyname(keyname, at->heap)) {
	    result=1;
	    printf("Error: '%s' is indirected by '%s'.\n", 
		   getNameFromSymTable(RBASIC(keyname)->id),
		   getNameFromSymTable(RBASIC(at->heap)->id));
	    /*
	    PutIndirection=1;
	    puts_name(at->heap);
	    puts("");
	    PutIndirection=0;
	    */
	  }
	}
      }
      at = at->next;
    }
  }
  return result;
}


void puts_allHash() {
  int i;
  NameList *at;

  for (i=0; i<NAME_HASHSIZE; i++) {
    at = NameHashTable[i];
    while (at != NULL) {
      if (at->heap != (VALUE)NULL) {
	if (IS_NAMEID(RBASIC(at->heap)->id))  {
	  printf("%s ",getNameFromSymTable(RBASIC(at->heap)->id));
	  //	  hasname_in_allHash(at->heap);
	}
      }
      at = at->next;
    }
  }
  puts("");
}



/*************************************
 Exec STACK
**************************************/

#ifdef THREAD
static pthread_cond_t APStack_not_empty = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t Sleep_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t AllSleep_lock = PTHREAD_MUTEX_INITIALIZER;
#endif



// GlobalAPStack for execution with threads
#ifdef THREAD
typedef struct {
  AP *stack;
  int nextPtr;
  int size;
  volatile int lock;  // for lightweight spin lock
} APStack;
static APStack GlobalAPS;
#endif


#ifdef THREAD
void GlobalAPStack_Init(int size) {
 GlobalAPS.nextPtr = -1;
 GlobalAPS.stack = malloc(sizeof(AP)*size);
 GlobalAPS.size = size;
  if (GlobalAPS.stack == NULL) {
    printf("Malloc error\n");
    exit(-1);
  }
  // for cas_lock
 GlobalAPS.lock = 0;
}
#endif

void VM_APStackInit(VirtualMachine *vm, int size) {
  vm->nextPtr_apStack = -1;  
  vm->apStack = malloc(sizeof(AP)*size);
  vm->apStack_size = size;
  if (vm->apStack == NULL) {
    printf("Malloc error\n");
    exit(-1);
  }
}


void VM_PushAPStack(VirtualMachine *vm, VALUE l, VALUE r) {

  vm->nextPtr_apStack++;

  if (vm->nextPtr_apStack >= vm->apStack_size) {
    printf("Critical ERROR: Overflow of the ap stack.\n");
    printf("You should have larger size by '-x option'.\n");
    printf("Please see help by using -h option.\n");
    exit(-1);
  }
  vm->apStack[vm->nextPtr_apStack].l = l;
  vm->apStack[vm->nextPtr_apStack].r = r;

#ifdef DEBUG
  //DEBUG
  printf(" PUSH:");
  puts_term(l);
  puts("");
  puts("      ><");
  printf("      ");puts_term(r);
  puts("");
#endif


  //  printf("VM%d:pushed\n", vm->id);
}

int VM_PopAPStack(VirtualMachine *vm, VALUE *l, VALUE *r) {
  if (vm->nextPtr_apStack >= 0) {
    *l = vm->apStack[vm->nextPtr_apStack].l;
    *r = vm->apStack[vm->nextPtr_apStack].r;
    vm->nextPtr_apStack--;
    return 1;
  }
  return 0;
}


#ifdef THREAD
void PushAPStack(VALUE l, VALUE r) {



  lock(&GlobalAPS.lock);

  GlobalAPS.nextPtr++;
  if (GlobalAPS.nextPtr >= GlobalAPS.size) {
    printf("Critical ERROR: Overflow of the execution (coequation) stack.\n");
    printf("You should have larger size.\n");
    printf("Please see help by using -h option.\n");
    exit(-1);
  }
  GlobalAPS.stack[GlobalAPS.nextPtr].l = l;
  GlobalAPS.stack[GlobalAPS.nextPtr].r = r;

  unlock(&GlobalAPS.lock);

  if (ActiveThreadNum < MaxThreadNum) {
    pthread_mutex_lock(&Sleep_lock);
    pthread_cond_signal(&APStack_not_empty);
    pthread_mutex_unlock(&Sleep_lock);
  }

}
#endif


int PopAPStack(VirtualMachine *vm, VALUE *l, VALUE *r) {

  if (vm->nextPtr_apStack >= 0) {
    *l = vm->apStack[vm->nextPtr_apStack].l;
    *r = vm->apStack[vm->nextPtr_apStack].r;
    vm->nextPtr_apStack--;

    /*
#ifdef DEBUG
    puts("");
    puts("====================================");
    puts("POP");
    puts("====================================");
    puts_term(*l);
    puts("");
    puts("><");
    puts_term(*r);
    puts("");
    puts("====================================");
#endif
    */

    return 1;
  }
#ifndef THREAD
  return 0;
#else

  lock(&GlobalAPS.lock);

  if (GlobalAPS.nextPtr  < 0) {
    // GlobalAPStack is empty
    unlock(&GlobalAPS.lock);
    return 0;
  }

  *l = GlobalAPS.stack[GlobalAPS.nextPtr].l;
  *r = GlobalAPS.stack[GlobalAPS.nextPtr].r;
  GlobalAPS.nextPtr--;

  unlock(&GlobalAPS.lock);

  return 1;
#endif
}


#ifdef DEBUG
void VM_APStack_allputs(VirtualMachine *vm) {
  int i;
  if (vm->nextPtr_apStack == -1) return;
  for (i=0; i<=vm->nextPtr_apStack+1; i++) {
    printf("%02d: ", i); puts_term(vm->apStack[i].l);
    puts("");
    printf("    ");
    puts_term(vm->apStack[i].r);
    puts("");
  }
}
#endif


/* --------------------
// Linearity check

#ifdef DEBUG
int VM_APStack_name_occur(VALUE a, VALUE t) {
  if (IS_NAMEID(RBASIC(t)->id)) {
    if (a == t) {
      //      puts_term(a); printf(" occurs in "); puts_term(t);puts("");
      return 1;
    }
    return 0;
  } else {
    // Agent
    int i, arity;

    arity = getArityFromSymTable(RAGENT(t)->basic.id);
    for (i=0; i<arity; i++) {
      if (VM_APStack_name_occur(a, RAGENT(t)->port[i])) {
	//	puts_term(a); printf(" occurs in the term "); puts_term(t);puts("");
	return 1;
      }
    }
    return 0;
  }
}

int VM_APStack_has_name(VALUE l, VALUE r) {

  if (IS_FIXNUM(l)) {
    return 1;
  } else if ((RBASIC(l) == NULL)||(RBASIC(l)->id == NULLP)) {
    puts("has_name ERROR");
    exit(-1);
  }
  if (IS_NAMEID(RBASIC(l)->id)) {
    if (RNAME(l)->port == (VALUE)NULL) {
      return VM_APStack_name_occur(l, r);
    } else {
      return 0;
    }
  } else if (RBASIC(l)->id == NULLP) {
    return 0;
  } else {
    // Agent
    int i, arity;
    int success = 0;
    arity = getArityFromSymTable(RAGENT(l)->basic.id);
    for (i=0; i<arity; i++) {
      if (VM_APStack_has_name(RAGENT(l)->port[i],r)) {
	success++;
      } else {
	//	printf("?:");
	//	puts_term(RAGENT(l)->port[i]);
	//	puts("");
      }
    }
		printf("??:");
		puts_term(l);
		printf("\n    ");
		puts_term(r);
		puts("");
    return success;
  }
}

int VM_APStack_has_name_own(VALUE l) {
  if (IS_FIXNUM(l)) {
    return 0;
  }
  if (IS_NAMEID(RBASIC(l)->id)) {
    if (RNAME(l)->port == (VALUE)NULL) {
      return 0;
    } else {
      printf("!");puts_term(l);printf("->");
      puts_term(RNAME(l)->port); puts(""); puts("");
      printf("id=%d\n", RBASIC(l)->id);
      return 1; //VM_APStack_has_name_own(RNAME(l)->port);
    }
  } else {
    // Agent
    int i, arity;
    int success = 0;

    arity = getArityFromSymTable(RAGENT(l)->basic.id);
    printf("Arity of "); puts_term(l); 
    printf(" is %d\n", arity);
    for (i=0; i<arity; i++) {
      int j;
      for (j=0; j<arity; j++) {
	if (j==i) {
		printf("* :");
		puts_term(RAGENT(l)->port[j]);
		puts("");
	  success+=VM_APStack_has_name_own(RAGENT(l)->port[j]);
	  continue;
	}
		printf("**:");
		puts_term(RAGENT(l)->port[i]);
		puts("");
		puts_term(RAGENT(l)->port[j]);
		puts("");
	success+=VM_APStack_has_name(RAGENT(l)->port[i], RAGENT(l)->port[j]);

      }
    }	

		printf("? :");
		puts_term(l);
		puts("");

    return success;
  }
}  



int VM_APStack_check_linearity(VirtualMachine *vm) {
  int i,j;
  VALUE l,r;
  if (vm->nextPtr_apStack == -1) return 1;
  for (i=0; i<=vm->nextPtr_apStack+1; i++) {

    int success = 0;
    int arity;

    l = vm->apStack[i].l;
    r = vm->apStack[i].r;
    arity = getArityFromSymTable(RAGENT(l)->basic.id);
    success+=VM_APStack_has_name_own(l);
    printf("score=%d\n\n", success);

    success+=VM_APStack_has_name(l,r);
    printf("score=%d\n\n", success);

    success+=VM_APStack_has_name_own(r);
    printf("score=%d\n\n", success);
    
    success+=VM_APStack_has_name(r,l);
    printf("score=%d\n\n", success);

    if (success == 2) return 1;

    success = 0;
    for (j=0; j<=vm->nextPtr_apStack+1; j++) {
      if (i==j) continue;
      success +=VM_APStack_has_name(l, vm->apStack[j].l);
    printf("score=%d\n\n", success);
      success +=VM_APStack_has_name(l, vm->apStack[j].r);
    printf("score=%d\n\n", success);

      success += VM_APStack_has_name(r, vm->apStack[j].l);
    printf("score=%d\n\n", success);
      success += VM_APStack_has_name(r, vm->apStack[j].r);
    printf("score=%d\n\n", success);
    }

    printf("score=%d\n\n", success);

    if (success == getArityFromSymTable(RAGENT(l)->basic.id) +
	getArityFromSymTable(RAGENT(r)->basic.id)) {
      return 1;
    }
    puts("Linearty ERROR:");
    puts_term(l);
    puts("");
    puts_term(r);
    puts("");
    puts("");
    //    VM_APStack_allputs(vm);
    return 0;   
  }
  return 0;
}
#endif
*/


/**************************************
 CODE
**************************************/
typedef enum {
  PUSH=0,
  MKNAME,
  MKGNAME,
  MKAGENT,
  REUSEAGENT,
  MYPUSH,
  MKVAL,
  LOAD,
  OP_ADD,
  OP_SUB,
  OP_MUL,
  OP_DIV,
  OP_MOD,
  OP_LT,
  OP_LE,
  OP_EQ,
  OP_NE,
  OP_JMPEQ0,
  OP_JMP,
  OP_UNM,
  OP_RAND,

  RET_FREE_LR,
  RET_FREE_L,
  RET_FREE_R,
  RET,
  NOP,  
} Code;


static void* CodeAddr[NOP+1];


typedef enum {
  NB_NAME=0,
  NB_META,
  NB_INTNAME,
} NB_TYPE;


// NBIND 数は meta数(MAX_AGENT_PORT*2) + 一つの rule（や aplist） における
// 最大name出現数(100)
#define MAX_NBIND MAX_AGENT_PORT*2+100
typedef struct {
  char *name;
  int offset;
  int refnum; // 参照回数：0 ならば free、1以上ならば bind
  NB_TYPE type;
} NameBind;
/* offset の使い方
offset は、AbstractMachine のローカルスタックの ptr
0 から昇順 ... local,global名前（NB_NAME）と、 newreg、および NB_INTNAME
LocalStackMax から +i  ... agentL+i
LocalStackMax+MAX_AGENT_PORT から +i ... agentR+i
LocalStackMax+MAX_AGENT_PORT*2 は agentL へのポインタ
LocalStackMax+MAX_AGENT_PORT*2+1 は agentR へのポインタ
*/




#define CM_MODE_RULE 0
#define CM_MODE_GLOBAL 1

#define MAX_CODE_SIZE 1024
typedef struct {
  NameBind bind[MAX_NBIND];   // management for local and global names
  int bindPtr;                // and its index.

  int localNamePtr;           // index for local and global names in Regs,
  int vmStackSize;            // the size of the array Regs.

  void *code[MAX_CODE_SIZE];  // array of compiled code
  int codeptr;                // and its index.

  int mode;

  int bindL, bindR;           // binding of ruleAgentL and ruleAgentR to VMStacks
  int occurL, occurR;
} CmEnvironment;

static CmEnvironment CmEnv;

void *ExecCode(int arg, VirtualMachine *vm, void **code);

void CmEnv_Init(int vm_heapsize) {
  int i;
  for (i=0; i<MAX_NBIND; i++) {
      CmEnv.bind[i].name = NULL;
  }
  CmEnv.bindPtr = 0;
  CmEnv.localNamePtr = 0;
  CmEnv.vmStackSize = vm_heapsize;

  CmEnv.codeptr = 0;

  void **table;
  table = ExecCode(0, NULL, NULL);
  for (i=0; i<NOP; i++) {
    CodeAddr[i] = table[i];
  }
}

void EnvClear(int mode) {
  int i;
  for (i=0; i<CmEnv.bindPtr; i++) {
    CmEnv.bind[i].name = NULL;
  }
  CmEnv.bindPtr = 0;
  CmEnv.localNamePtr = 0;
  CmEnv.codeptr = 0;
  CmEnv.mode = mode;

  CmEnv.occurL = 0;
  CmEnv.occurR = 0;
}

int EnvSetBindAsName(char *name) {
  int result;

  if (name != NULL) {
    CmEnv.bind[CmEnv.bindPtr].name = name;
    CmEnv.bind[CmEnv.bindPtr].offset = CmEnv.localNamePtr;
    CmEnv.bind[CmEnv.bindPtr].refnum = 0;
    CmEnv.bind[CmEnv.bindPtr].type = NB_NAME;
    result = CmEnv.localNamePtr;
    CmEnv.bindPtr++;
    if (CmEnv.bindPtr > MAX_NBIND) {
      puts("SYSTEM ERROR: CmEnv.bindPtr exceeded MAX_NBIND.");
      exit(-1);
    }
    CmEnv.localNamePtr++;
    if (CmEnv.localNamePtr > CmEnv.vmStackSize) {
      puts("SYSTEM ERROR: CmEnv.localNamePtr exceeded CmEnv.vmStackSize.");
      exit(-1);
    }
    return result;
  }
  return NULLP;
}


void EnvSetBindAsMeta(char *name, int offset, NB_TYPE type) {

  if (name != NULL) {
    CmEnv.bind[CmEnv.bindPtr].name = name;
    CmEnv.bind[CmEnv.bindPtr].offset = offset;
    CmEnv.bind[CmEnv.bindPtr].refnum = 0;
    CmEnv.bind[CmEnv.bindPtr].type = type;
    CmEnv.bindPtr++;
    if (CmEnv.bindPtr > MAX_NBIND) {
      puts("SYSTEM ERROR: CmEnv.bindPtr exceeded MAX_NBIND.");
      exit(-1);
    }
  }
}

// Agent用の RegNo を取得する (just for newreg)
//（これらは、Envコンパイル時に mkName、mkGname の対象にならないため
// 一時的な変数として使われる）
int EnvGetAnAgentAlloc() {

  int result;
  result = CmEnv.localNamePtr;
  CmEnv.localNamePtr++;
  if (CmEnv.localNamePtr > CmEnv.vmStackSize) {
    puts("SYSTEM ERROR: CmEnv.localNamePtr exceeded CmEnv.vmStackSize.");
    exit(-1);
  }

  return result;
}


int EnvSetBindAsIntName(char *name) {
  int result;

  if (name != NULL) {
    CmEnv.bind[CmEnv.bindPtr].name = name;
    CmEnv.bind[CmEnv.bindPtr].offset = CmEnv.localNamePtr;
    CmEnv.bind[CmEnv.bindPtr].refnum = 0;
    CmEnv.bind[CmEnv.bindPtr].type = NB_INTNAME;
    result = CmEnv.localNamePtr;

    CmEnv.bindPtr++;
    if (CmEnv.bindPtr > MAX_NBIND) {
      puts("SYSTEM ERROR: CmEnv.bindPtr exceeded MAX_NBIND.");
      exit(-1);
    }

    CmEnv.localNamePtr++;
    if (CmEnv.localNamePtr > CmEnv.vmStackSize) {
      puts("SYSTEM ERROR: CmEnv.localNamePtr exceeded CmEnv.vmStackSize.");
      exit(-1);
    }

    return result;
  }
  return NULLP;
}


int EnvSearchName(char *key) {
  int i;
  for (i=0; i<CmEnv.bindPtr; i++) {
    if (strcmp(key, CmEnv.bind[i].name) == 0) {
      CmEnv.bind[i].refnum++;
      return CmEnv.bind[i].offset;
    }
  }
  return NULLP;
}

int EnvSearch_GetNameType(char *key, NB_TYPE *type) {
  int i;
  for (i=0; i<CmEnv.bindPtr; i++) {
    if (strcmp(key, CmEnv.bind[i].name) == 0) {
      *type = CmEnv.bind[i].type;
      return 1;
    }
  }
  return 0;
}

#define EnvAddCode(c)\
  if (CmEnv.codeptr >= MAX_CODE_SIZE) {\
  puts("SYSTEM ERROR: The codeptr exceeded MAX_CODE_SIZE");\
  exit(-1);\
  }\
  CmEnv.code[CmEnv.codeptr] = c;\
  CmEnv.codeptr++;

#define EnvAddCode2(c1,c2)			\
  if (CmEnv.codeptr+1 >= MAX_CODE_SIZE) {\
  puts("SYSTEM ERROR: The codeptr exceeded MAX_CODE_SIZE");\
  exit(-1);\
  }\
  CmEnv.code[CmEnv.codeptr++] = c1;\
  CmEnv.code[CmEnv.codeptr++] = c2;

#define EnvAddCode3(c1,c2,c3)			\
  if (CmEnv.codeptr+2 >= MAX_CODE_SIZE) {\
  puts("SYSTEM ERROR: The codeptr exceeded MAX_CODE_SIZE");\
  exit(-1);\
  }\
  CmEnv.code[CmEnv.codeptr++] = c1;\
  CmEnv.code[CmEnv.codeptr++] = c2;\
  CmEnv.code[CmEnv.codeptr++] = c3;

#define EnvAddCode4(c1,c2,c3,c4)			\
  if (CmEnv.codeptr+3 >= MAX_CODE_SIZE) {\
  puts("SYSTEM ERROR: The codeptr exceeded MAX_CODE_SIZE");\
  exit(-1);\
  }\
  CmEnv.code[CmEnv.codeptr++] = c1;\
  CmEnv.code[CmEnv.codeptr++] = c2;\
  CmEnv.code[CmEnv.codeptr++] = c3;\
  CmEnv.code[CmEnv.codeptr++] = c4;

#define EnvAddCode6(c1,c2,c3,c4,c5,c6)		\
  if (CmEnv.codeptr+5 >= MAX_CODE_SIZE) {\
  puts("SYSTEM ERROR: The codeptr exceeded MAX_CODE_SIZE");\
  exit(-1);\
  }\
  CmEnv.code[CmEnv.codeptr++] = c1;\
  CmEnv.code[CmEnv.codeptr++] = c2;\
  CmEnv.code[CmEnv.codeptr++] = c3;\
  CmEnv.code[CmEnv.codeptr++] = c4;\
  CmEnv.code[CmEnv.codeptr++] = c5;\
  CmEnv.code[CmEnv.codeptr++] = c6;



#define EnvCodeClear() CmEnv.codeptr=0
  

void EnvAddCodePUSH(void* c1, void* c2) {
  EnvAddCode3(CodeAddr[PUSH],c1,c2);
}


void EnvAddCodeMYPUSH(void* c1, void* c2) {
  EnvAddCode3(CodeAddr[MYPUSH],c1,c2);
}


int Check_metaOccursOnce() {
  int i;

  for (i=0; i<CmEnv.bindPtr; i++) {

    if (CmEnv.bind[i].type == NB_META) {
      if (CmEnv.bind[i].refnum != 1) { // Be just once!
	printf("ERROR: The meta variable '%s' is not bound ", CmEnv.bind[i].name);
	return 0;
      }
      //    } else if (CmEnv.bind[i].type == NB_INTNAME) {
      //      if (CmEnv.bind[i].refnum == 0) {
      //	printf("Error: %s does not occur at RHS.\n", CmEnv.bind[i].name);
      //	return 0;
      //      }
    }
  }

  return 1;

}

int Check_nameOccurrenceWithEnv() {
  int i;
  for (i=0; i<CmEnv.bindPtr; i++) {
    if (CmEnv.bind[i].type == NB_NAME) {
      if (CmEnv.bind[i].refnum > 2) {
	printf("ERROR: The name '%s' occurs more than twice.\n", 
	       CmEnv.bind[i].name);
	return 0;
      }
    }
  }
  return 1;
}

int ProduceCodeWithEnv(void **code, int offset) {
  int i;

  { 
    int count_names=0;
    for (i=0; i<CmEnv.bindPtr; i++) {
      if (CmEnv.bind[i].type == NB_NAME) {
	count_names++;
      }
    }
    if (offset + count_names*3 > MAX_CODE_SIZE) {
      puts("System ERROR: Generated codes were too big.");
      return -1;
    }
  }

  { 

    int ptr=offset;
    //    code[ptr++] = CodeAddr[OP_FREE_LR];
    for (i=0; i<CmEnv.bindPtr; i++) {
      
      if (CmEnv.bind[i].type == NB_NAME) {
	
	if (CmEnv.bind[i].refnum > 0) {
	  code[ptr++] = CodeAddr[MKNAME];
	  
	} else {
	  code[ptr++] = CodeAddr[MKGNAME];
	  code[ptr++] = CmEnv.bind[i].name;
	}
	code[ptr++] = (void *)(unsigned long)CmEnv.bind[i].offset;
      }
    }
    
    if (ptr + CmEnv.codeptr > MAX_CODE_SIZE) {
      puts("System ERROR: Generated codes were too big.");
      return -1;
    }
    
    for (i=0; i<CmEnv.codeptr; i++) {
      code[ptr++] = CmEnv.code[i];
    }
    
    return (ptr-offset);
  }
}


int ProduceCode(void **code, int offset) {
  int ptr=offset;
  int i;
  for (i=0; i<CmEnv.codeptr; i++) {
    code[ptr] = CmEnv.code[i];
    ptr++;
  }

  return CmEnv.codeptr;
}


void CopyCode(int byte, void **source, void **target) {
  int i;
  for (i=0; i<byte; i++) {
    target[i]=source[i];
  }
}


/*
void EnvPutsCode() {
  int i,j,arity;
  for (i=0; i<CmEnv.localNamePtr; i++) {
    printf("var%d=mkName\n", i);
  }
  for (i=0; i<CmEnv.codeptr; i++) {
    switch (CmEnv.code[i]) {
    case RET:
      puts("ret");
      break;
    case PUSH:
      printf("push var%d var%d\n", CmEnv.code[i+1], CmEnv.code[i+2]);
      i +=2;
      break;
    case MKNAME:
      printf("var%d=mkname\n", CmEnv.code[i+1]);
      i +=1;
      break;
    case MKAGENT:
      printf("var%d=mkagent %d %d", 
	     CmEnv.code[i+1], CmEnv.code[i+2], CmEnv.code[i+3]);
      arity = CmEnv.code[i+3];
      i +=3;
      for(j=0; j<arity; j++) {
	i++;
	printf(" var%d", CmEnv.code[i]);
      }
      puts("");
      break;
    default:
      printf("CODE %d\n", CmEnv.code[i]);
      
    }
  }
}

*/


void PutsCodeN(void **code, int n) {
  int i,j;
  unsigned long arity;
  i=0;

  puts("[PutsCode]");
  if (n==-1) n = MAX_CODE_SIZE;
  for (i=0; i<n; i++) {
    printf("%d: ", i);
    if (code[i] == CodeAddr[MKNAME]) {
      printf("var%lu=mkname\n", (unsigned long)code[i+1]);
      i +=1;
    } else if (code[i] == CodeAddr[MKGNAME]) {
      printf("var%lu=mkgname %s\n", (unsigned long)code[i+2], (char *)code[i+1]);
      i +=2;
    } else if (code[i] == CodeAddr[MKAGENT]) {
      printf("var%lu=mkagent %lu %lu", 
	     (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      arity = (unsigned long)code[i+3];
      i +=3;
      for(j=0; j<arity; j++) {
	i++;
	printf(" var%lu", (unsigned long)code[i]);
      }
      puts("");
    } else if (code[i] == CodeAddr[REUSEAGENT]) {
      printf("reuseagent var%lu as id=%lu arity=%lu", 
	     (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      arity = (unsigned long)code[i+3];
      i +=3;
      for(j=0; j<arity; j++) {
	i++;
	printf(" var%lu", (unsigned long)code[i]);
      }
      puts("");
    } else if (code[i] == CodeAddr[PUSH]) {
      printf("push var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2]);
      i +=2;
    } else if (code[i] == CodeAddr[MYPUSH]) {
      printf("mypush var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2]);
      i +=2;
    } else if (code[i] == CodeAddr[RET]) {
	puts("ret");
      if (n==MAX_CODE_SIZE) {
	return;
      }
    } else if (code[i] == CodeAddr[RET_FREE_L]) {
	puts("retFreeL");
      if (n==MAX_CODE_SIZE) {
	return;
      }
    } else if (code[i] == CodeAddr[RET_FREE_R]) {
	puts("retFreeR");
      if (n==MAX_CODE_SIZE) {
	return;
      }
    } else if (code[i] == CodeAddr[RET_FREE_LR]) {
	puts("retFreeLR");
      if (n==MAX_CODE_SIZE) {
	return;
      }
    } else if (code[i] == CodeAddr[MKVAL]) {
      printf("mkval var%lu type%lu %lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[LOAD]) {
      printf("load var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2]);
      i+=2;
    } else if (code[i] == CodeAddr[OP_ADD]) {
      printf("add var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_SUB]) {
      printf("sub var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_MUL]) {
      printf("mul var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_DIV]) {
      printf("div var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_MOD]) {
      printf("mod var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_LT]) {
      printf("lt var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_LE]) {
      printf("le var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_EQ]) {
      printf("eq var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_NE]) {
      printf("ne var%lu var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2], (unsigned long)code[i+3]);
      i+=3;
    } else if (code[i] == CodeAddr[OP_JMPEQ0]) {
      printf("jmpeq0 var%lu %lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2]);
      i+=2;
    } else if (code[i] == CodeAddr[OP_JMP]) {
      printf("jmpeq0 %lu\n", (unsigned long)code[i+1]);
      i+=1;
    } else if (code[i] == CodeAddr[OP_UNM]) {
      printf("unm var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2]);
      i+=2;
    } else if (code[i] == CodeAddr[OP_RAND]) {
      printf("rnd var%lu var%lu\n", (unsigned long)code[i+1], (unsigned long)code[i+2]);
      i+=2;
    } else if (code[i] == CodeAddr[NOP]) {
      printf("nop\n");
    } else {
      printf("CODE %lu\n", (unsigned long)code[i]);      
    }
  }
}


void PutsCode(void **code) {
  PutsCodeN(code, -1);
}


int CompileExprFromAst(int target, Ast *ptr) {

  if (ptr == NULL) {
    return 1;
  }

  switch (ptr->id) {
  case AST_INT:
    EnvAddCode4(CodeAddr[MKVAL],
		 (void *)(unsigned long)target,
		 (void *)(unsigned long)ID_INT,
		 (void *)(unsigned long)(ptr->intval));
    return 1;
    break;

  case AST_NAME: {
    int result = EnvSearchName(ptr->left->sym);
    if (result == NULLP) {
      //      result=EnvSetBindAsIntName(ptr->left->sym);
      printf("ERROR: '%s' has not been defined previously.\n",
	     ptr->left->sym);
      return 0;
    }
    EnvAddCode3(CodeAddr[LOAD],
		(void *)(unsigned long)target,
		(void *)(unsigned long)result);
    return 1;
    break;
  }
  case AST_RAND: {
    int newreg = EnvGetAnAgentAlloc();
    if (!CompileExprFromAst(newreg, ptr->left)) return 0;
    EnvAddCode3(CodeAddr[OP_RAND],
		(void *)(unsigned long)target,
		(void *)(unsigned long)newreg);

    return 1;
    break;
  }
  case AST_UNM: {
    int newreg = EnvGetAnAgentAlloc();
    if (!CompileExprFromAst(newreg, ptr->left)) return 0;
    EnvAddCode3(CodeAddr[OP_UNM],
		(void *)(unsigned long)target,
		(void *)(unsigned long)newreg);

    return 1;
    break;
  }
  case AST_PLUS: 
  case AST_SUB:
  case AST_MUL:
  case AST_DIV:
  case AST_MOD:
  case AST_LT:
  case AST_LE:
  case AST_EQ:
  case AST_NE: {
    int newreg = EnvGetAnAgentAlloc();
    int newreg2 = EnvGetAnAgentAlloc();
    if (!CompileExprFromAst(newreg, ptr->left)) return 0;
    if (!CompileExprFromAst(newreg2, ptr->right)) return 0;

    switch (ptr->id) {
    case AST_PLUS:
      EnvAddCode(CodeAddr[OP_ADD]);
      break;
    case AST_SUB:
      EnvAddCode(CodeAddr[OP_SUB]);
      break;
    case AST_MUL:
      EnvAddCode(CodeAddr[OP_MUL]);
      break;
    case AST_DIV:
      EnvAddCode(CodeAddr[OP_DIV]);
      break;
    case AST_MOD:
      EnvAddCode(CodeAddr[OP_MOD]);
      break;
    case AST_LT:
      EnvAddCode(CodeAddr[OP_LT]);
      break;
    case AST_LE:
      EnvAddCode(CodeAddr[OP_LE]);
      break;
    case AST_EQ:
      EnvAddCode(CodeAddr[OP_EQ]);
      break;
    case AST_NE:
      EnvAddCode(CodeAddr[OP_NE]);
      break;
    default:
      EnvAddCode(CodeAddr[OP_MOD]);
    }
    EnvAddCode3((void *)(unsigned long)target,
		(void *)(unsigned long)newreg,
		(void *)(unsigned long)newreg2);

    return 1;
    break;
  }
  default:
    puts("System ERROR: Wrong AST was given to CompileExpr.");
    return 0;

  }

}

// Rule や ap の中の term をコンパイルするときに使う
int CompileTermFromAst(Ast *ptr, int target) {
  // input:
  // target == -1  => a new cell is produced in localHeap
  //   othereise   => the target is reused as the above new cell
  //
  // output:
  // return: offset in localHeap

  int result, mkagent;
  int i, arity;

  int alloc[MAX_AGENT_PORT];
  
  if (ptr == NULL) {
    return NULLP;
  }

  switch (ptr->id) {
  case AST_NAME:
    
    result = EnvSearchName(ptr->left->sym);
    if (result == NULLP) {
      result=EnvSetBindAsName(ptr->left->sym);
    }
    return result;
    break;

  case AST_INT:
    result = EnvGetAnAgentAlloc();
    EnvAddCode4(CodeAddr[MKVAL],
		(void *)(unsigned long)result,
		(void *)(unsigned long)ID_INT,
		(void *)(unsigned long)(ptr->intval));
    return result;
    break;

  case AST_NIL:
    if (target == -1) {      
      result = EnvGetAnAgentAlloc();
      mkagent = MKAGENT;
    } else {
      result = target;
      mkagent = REUSEAGENT;
    }
    EnvAddCode4(CodeAddr[mkagent],
		(void *)(unsigned long)result,
		(void *)(unsigned long)(ID_NIL),
		(void *)(unsigned long)0);
    return result;
    break;

  case AST_CONS:
    if (target == -1) {      
      result = EnvGetAnAgentAlloc();
      mkagent = MKAGENT;
    } else {
      result = target;
      mkagent = REUSEAGENT;
    }
    alloc[0] = CompileTermFromAst(ptr->left, -1);
    alloc[1] = CompileTermFromAst(ptr->right, -1);
    EnvAddCode6(CodeAddr[mkagent],
		(void *)(unsigned long)result,
		(void *)(unsigned long)(ID_CONS),
		(void *)(unsigned long)(2),
		(void *)(unsigned long)alloc[0],
		(void *)(unsigned long)alloc[1]);    
    return result;
    break;

  case AST_OPCONS:
    if (target == -1) {      
      result = EnvGetAnAgentAlloc();
      mkagent = MKAGENT;
    } else {
      result = target;
      mkagent = REUSEAGENT;
    }
    ptr = ptr->right;
    alloc[0] = CompileTermFromAst(ptr->left, -1);
    alloc[1] = CompileTermFromAst(ptr->right->left, -1);
    EnvAddCode6(CodeAddr[mkagent],
		(void *)(unsigned long)result,
		(void *)(unsigned long)(ID_CONS),
		(void *)(unsigned long)(2),
		(void *)(unsigned long)alloc[0],
		(void *)(unsigned long)alloc[1]);    
    return result;
    break;

  case AST_TUPLE:
    if (target == -1) {      
      result = EnvGetAnAgentAlloc();
      mkagent = MKAGENT;
    } else {
      result = target;
      mkagent = REUSEAGENT;
    }
    arity = ptr->intval;
    ptr=ptr->right;
    for(i=0; i< MAX_AGENT_PORT; i++) {
      if (ptr == NULL) break;
      alloc[i] = CompileTermFromAst(ptr->left, -1);
      ptr = ast_getTail(ptr);
    }

    EnvAddCode4(CodeAddr[mkagent],
		(void *)(unsigned long)result,
		(void *)(unsigned long)(GET_TUPLEID(arity)),
		(void *)(unsigned long)(arity));
    for(i=0; i< arity; i++) {
      EnvAddCode((void *)(unsigned long)alloc[i]);    
    }
    return result;
    break;

  case AST_AGENT:

    if (target == -1) {      
      result = EnvGetAnAgentAlloc();
      mkagent = MKAGENT;
    } else {
      result = target;
      mkagent = REUSEAGENT;
    }

    int id = getAgentID((char *)ptr->left->sym);

    /* For arity */
    //    result->arity = ptr->arity;
    arity=0;
    ptr=ptr->right;
    for(i=0; i< MAX_AGENT_PORT; i++) {
      if (ptr == NULL) break;
      alloc[i] = CompileTermFromAst(ptr->left, -1);
      arity++;
      ptr = ast_getTail(ptr);
    }
    // MKAGENT var ID ARITY var0 var1 ...
    EnvAddCode4(CodeAddr[mkagent],
		(void *)(unsigned long)result,
		(void *)(unsigned long)id,
		(void *)(unsigned long)arity);
    setArityToSymTable(id, arity);

    for(i=0; i< arity; i++) {
      EnvAddCode((void *)(unsigned long)alloc[i]);    
    }
    return result;
    break;

  case AST_ANNOTATION_L:
  case AST_ANNOTATION_R:
    if (ptr->id == AST_ANNOTATION_L) {
      CmEnv.occurL = 1; // *L が出現したことを示す
      result = CmEnv.bindL; //OFFSET_ANNOTATE_L;
    } else {
      CmEnv.occurR = 1; // *L が出現したことを示す
      result = CmEnv.bindR; // OFFSET_ANNOTATE_R;
    }

    
    result = CompileTermFromAst(ptr->left, result);
    return result;
    break;

    

  default:
    puts("ERROR: something strange in CompileTermFromAst.");
    puts_ast(ptr);
    exit(1);

  }

}




// rule の中の aps をコンパイルするときに使う
// この関数が呼ばれる前に、rule agents の meta names は
// Environment に積まれている。
int check_invalid_occurrence_as_rule(Ast *ast) {
  NB_TYPE type;

  if (ast->id == AST_NAME) {

    if (EnvSearch_GetNameType(ast->left->sym, &type)) {
      if (type == NB_INTNAME) {
	printf("ERROR: The variable '%s' for an integer cannot be used as an agent ",
	       ast->left->sym);
	return 0;
      }
    } else {
      //      printf("ERROR: The name '%s' is not bound ", ast->left->sym);
      //      return 0;
    }
  } else if (ast->id == AST_INT) {
    printf("ERROR: The integer '%d' is used as an agent ",
	   ast->intval);
    return 0;
  }

  return 1;
}


int check_invalid_occurrence(Ast *ast) {
  if (ast->id == AST_INT) {
    printf("ERROR: The integer '%d' is used as an agent.\n",
	   ast->intval);
    return 0;
  } else {
    return 1;
  }  
}



int CompileAPListFromAst(Ast *at) {
  int t1,t2;
  int count=0;

  while (at!=NULL) {
    if (!check_invalid_occurrence_as_rule(at->left->left) ||
	!check_invalid_occurrence_as_rule(at->left->right)) {
      return 0;
    }

    t1=CompileTermFromAst(at->left->left, -1);
    t2=CompileTermFromAst(at->left->right, -1);
    if (count != 0) {
      // 2度目は PUSH。
      EnvAddCodePUSH((void *)(unsigned long)t1, (void *)(unsigned long)t2);      
    } else {
      // はじめに MYPUSH を吐き、
      EnvAddCodeMYPUSH((void *)(unsigned long)t1, (void *)(unsigned long)t2);
      count++;
    }
    at = ast_getTail(at);
  }
  //  return clist1;
  if ((CmEnv.occurL == 0) && (CmEnv.occurR == 0)) {
    EnvAddCode(CodeAddr[RET_FREE_LR]);  
  } else if ((CmEnv.occurL == 1) && (CmEnv.occurR == 1)) {
    EnvAddCode(CodeAddr[RET]);  
  } else if (CmEnv.occurL == 1) {
    // only *L is occurred
    if (CmEnv.bindL == OFFSET_ANNOTATE_L) {
      EnvAddCode(CodeAddr[RET_FREE_R]);  
    } else {
      EnvAddCode(CodeAddr[RET_FREE_L]);  
    }
  } else {
    // only *R is occurred
    if (CmEnv.bindL == OFFSET_ANNOTATE_L) {
      EnvAddCode(CodeAddr[RET_FREE_L]);  
    } else {
      EnvAddCode(CodeAddr[RET_FREE_R]);  
    }
  }

  return 1;
}


int CompileStmListFromAst(Ast *at) {
  Ast *ptr;
  int toRegLeft;

  while (at!=NULL) {
    ptr=at->left;

    // (AST_LD (AST_NAME sym NULL) some)
    if (ptr->id != AST_LD) {
      puts("System ERROR: The given StmList contains something besides statements.");
      exit(-1);
    }
    // operation for x=y:
    // for the x
    toRegLeft = EnvSearchName(ptr->left->left->sym);
    if (toRegLeft == NULLP) {
      toRegLeft=EnvSetBindAsIntName(ptr->left->left->sym);
    } else {
      printf("Warning: '%s' has been already defined.\n", ptr->left->left->sym);
    }

    // for the y
    if (ptr->right->id == AST_NAME) {
      // y is a name
      int toRegRight=EnvSearchName(ptr->right->left->sym);
      if (toRegRight == NULLP) {
	toRegRight=EnvSetBindAsIntName(ptr->right->left->sym);
      }
      EnvAddCode3(CodeAddr[LOAD],
		  (void *)(unsigned long)toRegLeft,
		  (void *)(unsigned long)toRegRight);

    } else if (ptr->right->id == AST_INT) {
      // y is an integer
      EnvAddCode4(CodeAddr[MKVAL],
		  (void *)(unsigned long)toRegLeft,
		  (void *)(unsigned long)ID_INT,
		  (void *)(unsigned long)ptr->right->intval);
      
    } else {
      // y is an expression
      if (!CompileExprFromAst(toRegLeft, ptr->right)) return 0;

    }



    at = ast_getTail(at);
  }

  return 1;
}




#define TGT_LEFT 0
#define TGT_RIGHT 1

int SubstAst(char *sym, Ast *aterm, Ast *tgt, int place) {
  Ast *target;
  if (place == TGT_LEFT) {
    target = tgt->left;
  } else {
    target = tgt->right;
  }

  if (target->id == AST_NAME) {
    if (strcmp(target->left->sym, sym) == 0) {

      //      target = aterm;
      if (place == 0) {
	tgt->left = aterm;
      } else {
	tgt->right = aterm;
      }

      return 1;
    } else {
      return 0;
    }
  } else if ((target->id == AST_CONS) ||
	     (target->id == AST_OPCONS)) {
      //    } else if (SubstAst(sym, aterm, target->right, place)) {
    if (SubstAst(sym, aterm, target, TGT_RIGHT)) {
      return 1;
    } else {
      return 0;
    }
  } else if ((target->id == AST_TUPLE) ||
	     (target->id == AST_AGENT)) {
    int i;
    target=target->right;
    for(i=0; i< MAX_AGENT_PORT; i++) {
      if (target == NULL) return 0;
      //      if (SubstAst(sym, aterm, target->left, place)) return 1;
      if (SubstAst(sym, aterm, target, TGT_LEFT)) return 1;
      target = ast_getTail(target);
    }
    return 0;
  } else if (target->id == AST_LIST) {
    while (target->right != NULL) {
      if (SubstAst(sym, aterm, target, TGT_LEFT)) return 1;
      target = ast_getTail(target);
    }
    return 0;
  } else {
    return 0;
  }

}


int SubstASTList(int nth, char *sym, Ast *aterm, Ast *ast) {
  Ast *target, *at = ast;
  int ct = 0;

  while (at != NULL) {
    target = at->left;

    if (ct == nth) {
      ct++;
      at = ast_getTail(at);
      continue;
    }

    // SubstAst 内で target->left の値を書き換えても、
    // 関数から出ると元に戻ってしまう。
    // そこで、引数として target を渡し、
    // SubstAst の中で TGT_LEFT ならば target->left を
    // 書き換えるようにした。
    if (SubstAst(sym, aterm, target, TGT_LEFT)) {
	
      return 1;
    }
    if (SubstAst(sym, aterm, target, TGT_RIGHT)) {


      return 1;
    }
    ct++;
    at = ast_getTail(at);

  }

  return 0;
}


void RewriteAPListOnAST(Ast *body) {
  Ast *at, *prev, *target, *aps;
  int ct = 0;

  aps = ast_getNth(body, 1);
  at = prev = ast_getNth(body, 1);

  while (at != NULL) {

    target = at->left;

    //        printf("\n[target] "); puts_ast(target);
    //        printf("\n%dnth in ", ct); puts_ast(aps); printf("\n\n");

    if (target->left->id == AST_NAME) {

      // replace sym with target->right except for the ct-th active pair
      if (SubstASTList(ct, target->left->left->sym, target->right, aps)) {
	//		printf("=== hit %dth\n", ct);
	if (prev != at) {
	  // //	  ct++;
	  prev->right = at->right;
	  at=at->right;
	} else {
	  aps=body->right->left = body->right->left->right;
	  prev=at=at->right;
	}
	continue;
      }
    }
    if (target->right->id == AST_NAME) {
      if (SubstASTList(ct, target->right->left->sym, target->left, aps)) {
	//		printf("=== hit %dth\n", ct);
	if (prev != at) {
	  ////	  ct++;
	  prev->right = at->right;
	  at=at->right;
	} else {
	  aps=body->right->left = body->right->left->right;			     
	  prev= at = body->right->left;
	}
	continue;
      }
    }
    ct++;
    prev = at;
    at = at->right;
  }

}




/**************************************
 TABLE for RULES
**************************************/
typedef struct RuleList {
  int sym;
  int exists;
  void* code[MAX_CODE_SIZE];
  struct RuleList *next;
} RuleList;

RuleList *newRuleList() {
  RuleList *alist;
  alist = malloc(sizeof(RuleList));
  if (alist == NULL) {
    printf("Malloc error\n");
    exit(-1);
  }
  alist->exists=0;
  return alist;
}

#define RULEHASH_SIZE NUM_AGENTS
static RuleList *RuleTable[RULEHASH_SIZE];

void InitRuleTable() {
  int i;
  for (i=0; i<RULEHASH_SIZE; i++) {
    RuleTable[i] = NULL;
  }
}

void recordRule(int symlID, int symrID, int exists, int byte, void **code) {
  RuleList *add;

  if( RuleTable[symlID] == NULL ) {  /* もしハッシュテーブルが空ならば */
    add = newRuleList();             /* データノードを作成し */
    add->sym = symrID;
    if (exists != 0) {
      CopyCode(byte, code, add->code);
    }
    add->exists= exists;
    add->next = NULL;
    RuleTable[symlID] = add;        /* 単にセット */
    return;
  } else {  /* 線形探査が必要 */
    RuleList *at = RuleTable[symlID];  /* 先頭をセット */
    while( at != NULL ) {
      if( at->sym == symrID) {  /* すでにあれば... */
	if (exists != 0) {
	  CopyCode(byte, code, at->code);
	}
	at->exists= exists;
	return;
      }
      at = at->next;  /* 次のチェーンを辿る */
    }
    /* key がなかった → 先頭に追加 */
    add = newRuleList();  /* malloc ＋エラー処理 */
    add->sym = symrID;
    if (exists != 0) {
      CopyCode(byte, code, add->code);
    }
    add->exists= exists;
    add->next = RuleTable[symlID];  /* 以前の先頭を自分の次にする */
    RuleTable[symlID] = add;        /* 先頭に追加 */
    return;
  }
}


// SetMeta(Ast *astL, int idL, Ast *astR, int idR)
// 例えば、A(x1,x2)><B(y1) という rule に対して
// SetMeta(ast of the A, id of the A, ast of the B, id of the B)
// という引数で呼び出される。
// 関数内では x1, x2 という文字列が VMのレジスタである OFFSET_META_L(0)番, 
// OFFSET_META_L(1)番, y1 という文字列が OFFSET_META_R(0)番 を
// 参照できるように EnvSetBindAsMeta にて紐付けている。
// また、idL と idR に対しての Arity をセットしている
// （Arity の変化があったら warning を出せるようにするため）。
void setMeta(Ast *astL, int idL, Ast *astR, int idR) {
  int arity, i;
  Ast *ptr;

  arity=0;
  ptr = astL->right;
  for (i=0; i<MAX_AGENT_PORT; i++) {
    if (ptr == NULL) break;
    if (ptr->left->id == AST_NAME) {
      EnvSetBindAsMeta(ptr->left->left->sym, OFFSET_META_L(i), NB_META);
    } else {
      EnvSetBindAsMeta(ptr->left->left->sym, OFFSET_META_L(i), NB_INTNAME);
    }
    arity++;
    ptr = ast_getTail(ptr);
  }
  setArityToSymTable(idL, arity);
  
  arity=0;
  ptr = astR->right;
  for (i=0; i<MAX_AGENT_PORT; i++) {
    if (ptr == NULL) break;
    if (ptr->left->id == AST_NAME) {
      EnvSetBindAsMeta(ptr->left->left->sym, OFFSET_META_R(i), NB_META);
    } else {
      EnvSetBindAsMeta(ptr->left->left->sym, OFFSET_META_R(i), NB_INTNAME);
    }
    arity++;
    ptr = ast_getTail(ptr);
  }
  setArityToSymTable(idR, arity);
}


void setAnnotateLR(int left, int right) {
  CmEnv.bindL = left;
  CmEnv.bindR = right;  
}


void MakeRule(Ast *ast) {
  int numr, numl, idR, idL;
  Ast *ruleL, *ruleR, *bodies, *body, *aps, *stms, *guard;

  void* code[MAX_CODE_SIZE];
  int codeptr=0;
  int byte; // コンパイルで生成されたコード数保存用

  ruleL = ast->left->left;
  ruleR = ast->left->right;

  bodies = ast->right;

  //#define MYDEBUG
#ifdef MYDEBUG
    puts_ast(ruleL); puts("");
    puts_ast(ruleR); puts("");
    puts_ast(bodies); 
#endif

  // rule agent の id を numl, numr に格納
  if (ruleL->id == AST_TUPLE) {
    numl = GET_TUPLEID(ruleL->intval);
  } else if (ruleL->id == AST_OPCONS) {
    numl = ID_CONS;
  } else if (ruleL->id == AST_NIL) {
    numl = ID_NIL;
  } else {
    numl=getAgentID(ruleL->left->sym);
  }

  if (ruleR->id == AST_TUPLE) {
    numr = GET_TUPLEID(ruleR->intval);
  } else if (ruleR->id == AST_OPCONS) {
    numr = ID_CONS;
  } else if (ruleR->id == AST_NIL) {
    numr = ID_NIL;
  } else {
    numr=getAgentID(ruleR->left->sym);
  }


  //  puts("Bodies");
  //  puts_ast(bodies); puts("");
  //  puts("");



  do {

    body = bodies->left;

    //        puts("");puts("ruleL"); puts_ast(ruleL); puts("");
    //        puts("ruleR"); puts_ast(ruleR);puts("");
    //        puts(""); puts_ast(body->right); puts("");

        RewriteAPListOnAST(body->right);

    //        puts(""); puts_ast(body->right); puts("");

    guard = ast_getNth(body,0);
    stms = ast_getNth(body,1);
    aps = ast_getNth(body,2);



    //            puts(""); puts_ast(aps); puts("");


    /*
    puts("");puts("Gurad");
    puts_ast(guard);
    puts("");puts("Stms");
    puts_ast(stms);
    puts("");puts("Aps");
    puts_ast(aps);
    */


    EnvClear(CM_MODE_RULE);
    
    if (numl<=numr) {
      idL=numl;
      idR=numr;      
      setMeta(ruleL, idL, ruleR, idR);
      setAnnotateLR(OFFSET_ANNOTATE_L, OFFSET_ANNOTATE_R);
    } else {
      idL=numr;
      idR=numl;      
      setMeta(ruleR, idL, ruleL, idR);      
      setAnnotateLR(OFFSET_ANNOTATE_R, OFFSET_ANNOTATE_L);
    }

    
    // Compile ast terms    
    if (guard != NULL) {
      int label;  // 飛び先指定用

      // Gurad のコンパイル
      int newreg = EnvGetAnAgentAlloc();
      if (!CompileExprFromAst(newreg, guard)) return;
      byte = ProduceCode(code,codeptr);
      codeptr+=byte;

      //JMPEQ0 用コードを作成
      code[codeptr++] = CodeAddr[OP_JMPEQ0];
      code[codeptr++] = (void *)(unsigned long)newreg;
      label = codeptr++;  // 飛び先を格納するアドレスを記憶しておく

      // stms と aps のコンパイル
      EnvCodeClear();
      if (!CompileStmListFromAst(stms)) return;
      if (!CompileAPListFromAst(aps)) {
	printf("in the rule:\n  %s >< %s\n",
	       getNameFromSymTable(numl),
	       getNameFromSymTable(numr));
	       return;
      }
      byte = ProduceCodeWithEnv(code,codeptr);
      if (byte < 0) {
	puts("System ERROR: Generated codes were too big.");
	return;
      }

      // 次の guard コンパイルで &code[codeptr] にて指定できるように
      // codeptr を更新しておく。
      codeptr += byte;
      if (codeptr > MAX_CODE_SIZE) {
	puts("System ERROR: Generated codes were too big.");
	return;
      }

      // JMPEQ0 のとび先を格納
      code[label]=(void *)(unsigned long)byte;

      
      //      puts("");
      //      PutsCodeN(code, codeptr);
      //      puts("");
      
    } else {
      // 通常コンパイル
      if (!CompileStmListFromAst(stms)) return;
      if (!CompileAPListFromAst(aps)) {
	printf("in the rule:\n  %s >< %s\n",
	       getNameFromSymTable(numl),
	       getNameFromSymTable(numr));
	       return;
      }
      byte = ProduceCodeWithEnv(code,codeptr);
      codeptr += byte;
      if (byte < 0) {
	puts("System ERROR: Generated codes were too big.");
	return;
      }

    } 

    if (!Check_metaOccursOnce()) {
      printf("in the rule:\n  %s >< %s.\n", 
	     getNameFromSymTable(numl),
	     getNameFromSymTable(numr));

      //      puts_ast(ruleL); printf("><");
      //      puts_ast(ruleR); puts("");
      return;
    }
    bodies = ast_getTail(bodies);
  } while (bodies != NULL);

#ifdef MYDEBUG
    PutsCodeN(code, codeptr); exit(1);
#endif

  // Regist a rule between heap_syml and heap_symr 
  recordRule(idL, idR, 1, codeptr, code); 



  if (numl != numr) {
    
    // Regist the rule between heap_symr and heap_symr as EMPTY.
    recordRule(idR, idL, 0, -1, NULL);
  }
}


void *getRuleCode(VALUE heap_syml, VALUE heap_symr, int *result) {
  int syml = RAGENT(heap_syml)->basic.id;
  int symr = RAGENT(heap_symr)->basic.id;
  
  //RuleList *add;
  
  if( RuleTable[syml] == NULL ) {  /* もしハッシュテーブルが空ならば */
    *result=0;
    return NULL;
  } else {  /* 線形探査が必要 */
    RuleList *at = RuleTable[syml];  /* 先頭をセット */
    while( at != NULL ) {
      if( at->sym == symr) {  /* すでにあれば... */
	//	if (at->coeqlist == NULL) {
	if (at->exists == 0) {
	  *result=0;
	  return NULL;
	} else {
	  *result=1;
	  return at->code;
	}
      }
      at = at->next;  /* 次のチェーンを辿る */
    }
    /* key がなかった → 先頭に追加 */
    *result=0;
    return NULL;
  }
}


void *ExecCode(int arg, VirtualMachine *vm, void** code) {
  int arity, i, pc=0;
  VALUE a1;

  //http://magazine.rubyist.net/?0008-YarvManiacs
  static const void *table[] = {
    &&E_PUSH, &&E_MKNAME, &&E_MKGNAME, &&E_MKAGENT, &&E_REUSEAGENT, &&E_MYPUSH,
    &&E_MKVAL, &&E_LOAD, &&E_ADD, &&E_SUB, &&E_MUL, &&E_DIV, &&E_MOD, 
    &&E_LT, &&E_LE, &&E_EQ, &&E_NE, &&E_JMPEQ0, &&E_JMP, &&E_UNM, 
    &&E_RAND, 
    &&E_RET_FREE_LR, &&E_RET_FREE_L, &&E_RET_FREE_R, &&E_RET, 
    &&E_NOP, 
  };

  // table 作成用（通常（コード実行時）は arg=1 で呼び出す）
  if (arg == 0) {
    return table;
  }

  //freeAgent(vm->L); freeAgent(vm->R);
  //freeAgent(vm->agentReg[OFFSET_META_L(MAX_AGENT_PORT-1)]);
  //freeAgent(vm->agentReg[OFFSET_META_R(MAX_AGENT_PORT-1)]);


  goto *code[pc];

 E_MKNAME:
  //    puts("mkname");
  a1 = makeName(vm);
  vm->agentReg[(unsigned long)code[pc+1]] = a1;
  pc +=2;
  goto *code[pc];

 E_MKGNAME:
  //    puts("mkgname");
  a1 = opMakeName(vm, (char *)code[pc+1]);
  vm->agentReg[(unsigned long)code[pc+2]] = a1;
  pc +=3;
  goto *code[pc];
  
 E_MKAGENT:
  //    puts("mkagent");
  arity = (unsigned long)code[pc+3];
  a1 = makeAgent(vm, (unsigned long)code[pc+2]);
  vm->agentReg[(unsigned long)code[pc+1]] = a1;
  pc +=4;
  for(i=0; i<arity; i++) {
    RAGENT(a1)->port[i] = vm->agentReg[(unsigned long)code[pc]];	  
    pc++;
  }
  goto *code[pc];



#ifndef THREAD
#define PUSH(vm, a1, a2)				 \
  if ((!IS_FIXNUM(a1)) && (RBASIC(a1)->id == ID_NAME) && \
      (RNAME(a1)->port == (VALUE)NULL)) {			\
    RNAME(a1)->port = a2;					\
  } else if ((!IS_FIXNUM(a2)) && (RBASIC(a2)->id == ID_NAME) && \
	     (RNAME(a2)->port == (VALUE)NULL)) {		\
    RNAME(a2)->port = a1;					\
  } else {							\
    VM_PushAPStack(vm, a1,a2);					\
  }
#else
#define PUSH(vm, a1, a2)						\
  if ((!IS_FIXNUM(a1)) && (RBASIC(a1)->id == ID_NAME) &&		\
      (RNAME(a1)->port == (VALUE)NULL)) {				\
    if (!(__sync_bool_compare_and_swap(&(RNAME(a1)->port), NULL, a2))) { \
      if (MaxThreadNum - ActiveThreadNum != 0) {			\
	PushAPStack(a1,a2);						\
      } else {								\
	VM_PushAPStack(vm, a1,a2);					\
      }									\
    }									\
  } else if ((!IS_FIXNUM(a2)) && (RBASIC(a2)->id == ID_NAME) &&		\
	     (RNAME(a2)->port == (VALUE)NULL)) {			\
    if (!(__sync_bool_compare_and_swap(&(RNAME(a2)->port), NULL, a1))) { \
      if (MaxThreadNum - ActiveThreadNum != 0) {			\
	PushAPStack(a1,a2);						\
      } else {								\
	VM_PushAPStack(vm, a1,a2);					\
      }									\
    }									\
  } else {								\
    if (MaxThreadNum - ActiveThreadNum != 0) {				\
      PushAPStack(a1,a2);						\
    } else {								\
      VM_PushAPStack(vm, a1,a2);					\
    }									\
  }
#endif  


 E_PUSH:
  //    puts("push");
  PUSH(vm, vm->agentReg[(unsigned long)code[pc+1]], vm->agentReg[(unsigned long)code[pc+2]]);

  /*
#ifndef THREAD
  VM_PushAPStack(vm, vm->agentReg[(unsigned long)code[pc+1]], vm->agentReg[(unsigned long)code[pc+2]]);
#else
  if (MaxThreadNum - ActiveThreadNum != 0) {
    PushAPStack(vm->agentReg[(unsigned long)code[pc+1]], vm->agentReg[(unsigned long)code[pc+2]]);
  } else {
    VM_PushAPStack(vm, vm->agentReg[(unsigned long)code[pc+1]], vm->agentReg[(unsigned long)code[pc+2]]);
  }
#endif
  */

  pc +=3;
  goto *code[pc];



#ifndef THREAD
#define MYPUSH(vm, a1, a2)				 \
  if ((!IS_FIXNUM(a1)) && (RBASIC(a1)->id == ID_NAME) && \
      (RNAME(a1)->port == (VALUE)NULL)) {			\
    RNAME(a1)->port = a2;					\
  } else if ((!IS_FIXNUM(a2)) && (RBASIC(a2)->id == ID_NAME) && \
	     (RNAME(a2)->port == (VALUE)NULL)) {		\
    RNAME(a2)->port = a1;					\
  } else {							\
    VM_PushAPStack(vm, a1,a2);					\
  }
#else
#define MYPUSH(vm, a1, a2)						\
  if ((!IS_FIXNUM(a1)) && (RBASIC(a1)->id == ID_NAME) &&		\
      (RNAME(a1)->port == (VALUE)NULL)) {				\
    if (!(__sync_bool_compare_and_swap(&(RNAME(a1)->port), NULL, a2))) { \
      VM_PushAPStack(vm, a1,a2);					\
    }									\
  } else if ((!IS_FIXNUM(a2)) && (RBASIC(a2)->id == ID_NAME) &&		\
	     (RNAME(a2)->port == (VALUE)NULL)) {			\
    if (!(__sync_bool_compare_and_swap(&(RNAME(a2)->port), NULL, a1))) { \
      VM_PushAPStack(vm, a1,a2);					\
    }									\
  } else {								\
    VM_PushAPStack(vm, a1,a2);						\
  }
#endif  




 E_MYPUSH:
  //    puts("mypush");
  //  VM_PushAPStack(vm, vm->agentReg[(unsigned long)code[pc+1]], vm->agentReg[(unsigned long)code[pc+2]]);
  MYPUSH(vm, vm->agentReg[(unsigned long)code[pc+1]], vm->agentReg[(unsigned long)code[pc+2]]);
  pc +=3;
  goto *code[pc];

 E_MKVAL:
  //    puts("mkval reg type num");
  //a1 = makeVal_int(vm, (unsigned long)code[pc+3]);
  a1 = INT2FIX((long)code[pc+3]);
  vm->agentReg[(unsigned long)code[pc+1]] = a1;
  pc +=4;
  goto *code[pc];


 E_LOAD:
  //    puts("load reg reg");
  //a1 = makeVal_int(vm, (unsigned long)code[pc+3]);
  vm->agentReg[(unsigned long)code[pc+1]] = 
    vm->agentReg[(unsigned long)code[pc+2]];
  pc +=3;
  goto *code[pc];

 E_ADD:
  //    puts("ADD reg reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
        INT2FIX(FIX2INT(vm->agentReg[(unsigned long)code[pc+2]])+FIX2INT(vm->agentReg[(unsigned long)code[pc+3]]));
  pc +=4;
  goto *code[pc];

 E_SUB:
  //    puts("SUB reg reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
    INT2FIX(FIX2INT(vm->agentReg[(unsigned long)code[pc+2]])-
	    FIX2INT(vm->agentReg[(unsigned long)code[pc+3]]));
  pc +=4;
  goto *code[pc];

 E_MUL:
  //    puts("SUB reg reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
    INT2FIX(FIX2INT(vm->agentReg[(unsigned long)code[pc+2]])*
	    FIX2INT(vm->agentReg[(unsigned long)code[pc+3]]));
  pc +=4;
  goto *code[pc];

 E_DIV:
  //    puts("SUB reg reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
    INT2FIX(FIX2INT(vm->agentReg[(unsigned long)code[pc+2]])/
	    FIX2INT(vm->agentReg[(unsigned long)code[pc+3]]));
  pc +=4;
  goto *code[pc];

 E_MOD:
  //    puts("SUB reg reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
    INT2FIX(FIX2INT(vm->agentReg[(unsigned long)code[pc+2]])%
	    FIX2INT(vm->agentReg[(unsigned long)code[pc+3]]));
  pc +=4;
  goto *code[pc];

 E_LT:
  //    puts("SUB reg reg reg");
  if (FIX2INT(vm->agentReg[(unsigned long)code[pc+2]]) <
      FIX2INT(vm->agentReg[(unsigned long)code[pc+3]])) {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(1);
  } else {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(0);
  }    
  pc +=4;
  goto *code[pc];

 E_LE:
  //    puts("SUB reg reg reg");
  if (FIX2INT(vm->agentReg[(unsigned long)code[pc+2]]) <=
      FIX2INT(vm->agentReg[(unsigned long)code[pc+3]])) {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(1);
  } else {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(0);
  }    
  pc +=4;
  goto *code[pc];

 E_EQ:
  //    puts("SUB reg reg reg");
  if (FIX2INT(vm->agentReg[(unsigned long)code[pc+2]]) ==
      FIX2INT(vm->agentReg[(unsigned long)code[pc+3]])) {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(1);
  } else {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(0);
  }    
  pc +=4;
  goto *code[pc];

 E_NE:
  //    puts("SUB reg reg reg");
  if (FIX2INT(vm->agentReg[(unsigned long)code[pc+2]]) !=
      FIX2INT(vm->agentReg[(unsigned long)code[pc+3]])) {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(1);
  } else {
    vm->agentReg[(unsigned long)code[pc+1]] = INT2FIX(0);
  }    
  pc +=4;
  goto *code[pc];

 E_JMPEQ0:
  //    puts("JMPEQ0 reg pc");
  if (FIX2INT(vm->agentReg[(unsigned long)code[pc+1]]) == 0) {
    pc += (unsigned long)code[pc+2];
  }
  pc +=3;
  goto *code[pc];

 E_JMP:
  //    puts("JMP pc");
  pc += vm->agentReg[(unsigned long)code[pc+1]];
  pc +=2;
  goto *code[pc];

 E_UNM:
  //    puts("UNM reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
    INT2FIX(-1 * FIX2INT(vm->agentReg[(unsigned long)code[pc+2]]));
  pc +=3;
  goto *code[pc];

 E_RAND:
  //    puts("RAND reg reg");
  vm->agentReg[(unsigned long)code[pc+1]] = 
    INT2FIX(rand()%FIX2INT(vm->agentReg[(unsigned long)code[pc+2]]));
  pc +=3;
  goto *code[pc];


  // extended codes should be ended here.
 E_REUSEAGENT: // reuseagent target id arity
  //    puts("reuseagent");
  arity = (unsigned long)code[pc+3];
  a1 = vm->agentReg[(unsigned long)code[pc+1]];
  RAGENT(a1)->basic.id = (unsigned long)code[pc+2];
  pc +=4;
  for(i=0; i<arity; i++) {
    RAGENT(a1)->port[i] = vm->agentReg[(unsigned long)code[pc]];	  
    pc++;
  }
  goto *code[pc];


 E_RET_FREE_LR:
  //    puts("ret");
  freeAgent(vm->agentReg[OFFSET_ANNOTATE_L]);
  freeAgent(vm->agentReg[OFFSET_ANNOTATE_R]);
  //  freeAgent(vm->L);
  //  freeAgent(vm->R);
  return NULL;
  
 E_RET_FREE_L:
  //    puts("ret");
  freeAgent(vm->agentReg[OFFSET_ANNOTATE_L]);
  //  freeAgent(vm->L);
  return NULL;

 E_RET_FREE_R:
  //    puts("ret");
  freeAgent(vm->agentReg[OFFSET_ANNOTATE_R]);
  //  freeAgent(vm->R);
  return NULL;

 E_RET:
  //    puts("ret");
  return NULL;

 E_NOP:
  return NULL;



}




void errprintf(int tid) {
  printf("%2d:", tid);
}  

void errputs(char *s, int tid) {
  /*
    errprintf(tid);
    puts(s);
  */
}


/******************************************
 Mark and Sweep
******************************************/
#ifndef THREAD

/* 31bit目が 1 ならば、Garbage Collection の Mark&Sweep にて、
   Mark されたことを意味する*/
#define FLAG_MARKED 0x01 << 30
#define IS_FLAG_MARKED(a) ((a) & FLAG_MARKED)
#define SET_FLAG_MARKED(a) ((a) = ((a) | FLAG_MARKED))
#define TOGGLE_FLAG_MARKED(a) ((a) = ((a) ^ FLAG_MARKED))


void markHeapRec(VALUE ptr) {
 loop:  
  if ((ptr == (VALUE)NULL) || (RBASIC(ptr)->id == NULLP) || (IS_FIXNUM(ptr))) {
    return;
  } else if (IS_NAMEID(RBASIC(ptr)->id)) {
    if (ptr == ShowNameHeap) return;

    SET_FLAG_MARKED(RBASIC(ptr)->id);
    if (RNAME(ptr)->port != (VALUE)NULL) {
      ptr = RNAME(ptr)->port;
      goto loop;
    }
  } else {
    if (RBASIC(ptr)->id == ID_CONS) {
      if (IS_FIXNUM(RAGENT(ptr)->port[0])) {
	SET_FLAG_MARKED(RBASIC(ptr)->id);
	ptr = RAGENT(ptr)->port[1];
	goto loop;
      }
    }      

    int arity = getArityFromSymTable(RBASIC(ptr)->id);
    SET_FLAG_MARKED(RBASIC(ptr)->id);
    if (arity == 1) {
      ptr = RAGENT(ptr)->port[0];
      goto loop;
    } else { // it contains the case that i==0.
      int i;
      for(i=0; i<arity; i++) {
	markHeapRec(RAGENT(ptr)->port[i]);
      }
    }
  }
}


void mark_name_port0(VALUE ptr) {
  if (ptr != (VALUE)NULL) {

    SET_FLAG_MARKED(RBASIC(ptr)->id);
    if (RNAME(ptr)->port != (VALUE)NULL) {
      ShowNameHeap=ptr;
      markHeapRec(RNAME(ptr)->port);
      ShowNameHeap=(VALUE)NULL;
    }      
  }
}


void mark_allHash() {
  int i;
  NameList *at;

  for (i=0; i<NAME_HASHSIZE; i++) {
    at = NameHashTable[i];
    while (at != NULL) {
      if (at->heap != (VALUE)NULL) {
	if (IS_NAMEID(RBASIC(at->heap)->id))  {
	  mark_name_port0(at->heap);
	}
      }
      at = at->next;
    }
  }
}

void sweepAgentHeap(Heap *hp) {
  int i;
  for (i=0; i < hp->size; i++) {
    if (!IS_FLAG_MARKED( ((Agent *)hp->heap)[i].basic.id)) {
      SET_FLAG_AVAIL( ((Agent *)hp->heap)[i].basic.id);
    } else {
      TOGGLE_FLAG_MARKED( ((Agent *)hp->heap)[i].basic.id);
    }
  }
}
void sweepNameHeap(Heap *hp) {
  int i;
  for (i=0; i < hp->size; i++) {
    if (!IS_FLAG_MARKED( ((Name *)hp->heap)[i].basic.id)) {
      SET_FLAG_AVAIL( ((Name *)hp->heap)[i].basic.id);
    } else {
      TOGGLE_FLAG_MARKED( ((Name *)hp->heap)[i].basic.id);
    }
  }
}



void mark_and_sweep() {
  mark_allHash();
  sweepAgentHeap(&(VM.agentHeap));
  sweepNameHeap(&VM.nameHeap);
  VM.nextPtr_apStack = -1;  
}

#endif



/***********************************
 exec coequation
**********************************/
//#define DEBUG


#define CAS_USLEEP 4


// tid は threadid
void execActivePair(VirtualMachine *vm, VALUE a1, VALUE a2) {

 loop:
  //  if (RBASIC(a2)->id >= START_ID_OF_AGENT) {
  if (IS_FIXNUM(a2)) {
    printf("Runtime ERROR: "); puts_term(a1); printf("~"); puts_term(a2); 
    printf("\nInteger %d can not be used as an agent\n", FIX2INT(a2));
#ifndef THREAD
    mark_and_sweep();
    return;
#else
    printf("Retrieve is not supported in the multi-threaded version.\n");
    exit(-1);
#endif
  }
  if (RBASIC(a2)->id < ID_NAME) {
  loop_a2IsAgent:
  if (IS_FIXNUM(a1)) {
    printf("Runtime ERROR: "); puts_term(a1); printf("~"); puts_term(a2); 
    printf("\nInteger %d can not be used as an agent\n", FIX2INT(a1));
#ifndef THREAD
    mark_and_sweep();
    return;
#else
    printf("Retrieve is not supported in the multi-threaded version.\n");
    exit(-1);
#endif
  }

    //    if (RBASIC(a1)->id >= START_ID_OF_AGENT) {
    if (RBASIC(a1)->id < ID_NAME) {
      
      /* for the case of  s - t  */
#ifdef DEBUG   
      puts("");
      puts("--------------------------------------");
      puts("execActive");
      puts("--------------------------------------");
      puts_term(a1);puts("");
      printf("><");puts("");
      puts_term(a2);puts("");
      puts("--------------------------------------");
      puts("");
#endif


      if (RBASIC(a1)->id > RBASIC(a2)->id) {
	VALUE tmp;
	tmp=a1;
	a1=a2;
	a2=tmp;
      }
      
      int result;
      void **code;
            
      code = getRuleCode(a1, a2, &result);

      if (result == 0) {
	printf("Runtime Error: There is no interaction rule for the following pair:\n  ");
	puts_term(a1);
	printf("~");
	puts_term(a2);
	puts("");

	if (yyin != stdin) exit(-1);

#ifndef THREAD
	mark_and_sweep();
	return;
#else
	printf("Retrieve is not supported in the multi-threaded version.\n");
	exit(-1);
#endif
      }
      // normal op
      

      //      PutsCode(at);
      //      return;
      
#ifdef COUNT_INTERACTION
      vm->NumberOfInteraction++;
#endif
      
      int i;
      for (i=0; i<MAX_AGENT_PORT; i++) {
	vm->agentReg[OFFSET_META_L(i)] = RAGENT(a1)->port[i];
      }
      for (i=0; i<MAX_AGENT_PORT; i++) {
	vm->agentReg[OFFSET_META_R(i)] = RAGENT(a2)->port[i];
      }
      vm->agentReg[OFFSET_ANNOTATE_L] = a1;
      vm->agentReg[OFFSET_ANNOTATE_R] = a2;

      //freeAgent(a1);
      //freeAgent(a2);

      //      vm->L = a1;
      //      vm->R = a2;

      ExecCode(1, vm, code);


	
      return;
    }  else {

      // a2 is agent
      if (RNAME(a1)->port != (VALUE)NULL) {

	VALUE a1p0;
	a1p0=RNAME(a1)->port;
	freeName(a1);
	a1=a1p0;
	goto loop_a2IsAgent;
      } else {
#ifndef THREAD
	RNAME(a1)->port=a2;
#else
	if (!(__sync_bool_compare_and_swap(&(RNAME(a1)->port), NULL, a2))) {
	  usleep(CAS_USLEEP);
	  //	  goto loop_a2IsAgent;
	  goto loop;
	}
#endif

      }
    }
  } else {
    if (RNAME(a2)->port != (VALUE)NULL) {
      VALUE a2p0;
      a2p0=RNAME(a2)->port;
      freeName(a2);
      a2=a2p0;
      goto loop;
    } else {
#ifndef THREAD
      RNAME(a2)->port=a1;
#else
      if (!(__sync_bool_compare_and_swap(&(RNAME(a2)->port), NULL, a1))) {
	  usleep(CAS_USLEEP);;
	  goto loop;
	}
#endif
    }
  }
}
 

void Init_VM(VirtualMachine *vm, 
	     unsigned int agentBufferSize, unsigned int apStackSize) {
  VM_InitBuffer(vm, agentBufferSize);
  VM_APStackInit(vm, apStackSize);
}



#ifndef THREAD
int exec(Ast *at) {
  unsigned long long t, time;

  void* code[MAX_CODE_SIZE];

  start_timer(&t);

  EnvClear(CM_MODE_GLOBAL);

  // for 'where' expression
  if (!CompileStmListFromAst(ast_getNth(at,0))) return 0;


  // for aplists
  //  puts(""); puts_ast(at); puts("");
  RewriteAPListOnAST(at);
  //  puts(""); puts_ast(at); puts("");

  at = ast_getNth(at,1);

  // Syntax error check
  {  Ast *tmp_at=at;
  while (tmp_at != NULL) {
    if (!check_invalid_occurrence(tmp_at->left->left)) {
      if (yyin != stdin) exit(-1);
      return 0;
    }
    if (!check_invalid_occurrence(tmp_at->left->right)) {
      if (yyin != stdin) exit(-1);
      return 0;
    }
    tmp_at = ast_getTail(tmp_at);
  }}

  while (at != NULL) {
    int p1,p2;

    p1 = CompileTermFromAst(at->left->left, -1);
    p2 = CompileTermFromAst(at->left->right, -1);
    EnvAddCodePUSH((void *)(unsigned long)p1, (void *)(unsigned long)p2);
    at = ast_getTail(at);
  }
  EnvAddCode(CodeAddr[RET_FREE_LR]);  

  // checking whether names occur more than twice
  if (!Check_nameOccurrenceWithEnv()) {
    if (yyin != stdin) exit(-1);
    return 0;
  }
  ProduceCodeWithEnv(code,0); // '0' means that generated codes are
                              // stored in code[0,...].

  //PutsCode(code); exit(1);

  ExecCode(1, &VM, code);


#ifdef COUNT_INTERACTION
  VM_ClearInteractionNum(&VM);
#endif
  
  {
    VALUE t1, t2;
    while (PopAPStack(&VM, &t1, &t2)) {

#ifdef DEBUG
      puts("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      puts("APStack");
      puts("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      VM_APStack_allputs(&VM);
      puts("");

      /*
      if (!IS_NAMEID(RBASIC(t1)->id) && !IS_NAMEID(RBASIC(t2)->id)) {
	if (VM_APStack_check_linearity(&VM)) {
	  puts("Linearity OK");
	} else {
	  //	  puts("Linearty ERROR");
	  exit(-1);
	}
      }
      */
#endif

      execActivePair(&VM, t1, t2);



    }
  }


  time=stop_timer(&t);
#ifdef COUNT_INTERACTION
  printf("(%d interactions, %.2f sec)\n", VM_GetInteractionNum(&VM),
	 (double)(time)/1000000);
#else
  printf("(%.2f sec)\n", 
	 (double)(time)/1000000);
#endif

#ifdef CELL_USE_VERBOSE
  printf("(%lu agents and %lu names cells are used.)\n", 
	 VM.agentHeap.size - getNumOfAvailAgentHeap(&VM.agentHeap),
	 VM.nameHeap.size - getNumOfAvailNameHeap(&VM.nameHeap));
#endif	 

  return 1;
}

#else

int CpuNum=1; // CPU 数の設定用（sysconf(_SC_NPROSSEORS_CONF)) を使って求める）

static pthread_cond_t ActiveThread_all_sleep = PTHREAD_COND_INITIALIZER;
static pthread_t *Threads;
static VirtualMachine **VMs;

void *tpool_thread(void *arg) {

  VirtualMachine *vm;

  vm = (VirtualMachine *)arg;

#ifdef __CPU_ZERO
  cpu_set_t mask;
  __CPU_ZERO(&mask);
  __CPU_SET(id%CpuNum, &mask);
  if(sched_setaffinity(0, sizeof(mask), &mask)==-1) {
	printf("WARNING:\n");
  }
  printf("CPUNUM=%d, id=%d, cpuid=%d\n", CpuNum, id, id%CpuNum);
#endif

  while (1) {

    VALUE t1, t2;
    while (!PopAPStack(vm, &t1, &t2)) {
      pthread_mutex_lock(&Sleep_lock);
      ActiveThreadNum = ActiveThreadNum - 1;

      if (ActiveThreadNum == 0) {
	pthread_mutex_lock(&AllSleep_lock);
	pthread_cond_signal(&ActiveThread_all_sleep);
	pthread_mutex_unlock(&AllSleep_lock);
      }

      //      printf("[Thread %d is slept.]\n", vm->id);
      pthread_cond_wait(&APStack_not_empty, &Sleep_lock);
      ActiveThreadNum = ActiveThreadNum + 1;
      pthread_mutex_unlock(&Sleep_lock);  
      //      printf("[Thread %d is waked up.]\n", vm->id);


    }


    execActivePair(vm, t1, t2);

    
  }

  return (void *)NULL;
}

void tpool_init(unsigned int agentBufferSize, unsigned int apstack_size) {
  int i, status;
  //  static int id[100];


  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);


  CpuNum = sysconf(_SC_NPROCESSORS_CONF);

  pthread_setconcurrency(CpuNum);


  Threads = (pthread_t *)malloc(sizeof(pthread_t)*MaxThreadNum);
  if (Threads == NULL) {
    printf("the thread pool could not be created.");
    exit(-1);
  }
  ActiveThreadNum = MaxThreadNum;

  VMs = malloc(sizeof(VirtualMachine*)*MaxThreadNum);
  if (VMs == NULL) {
    printf("the thread pool could not be created.");
    exit(-1);
  }


  for (i=0; i<MaxThreadNum; i++) {
    VMs[i] = malloc(sizeof(VirtualMachine));
//    VMs[i]->id = i;
    Init_VM(VMs[i], agentBufferSize, apstack_size);
    status = pthread_create( &Threads[i],
		    &attr,
		    tpool_thread,
		    (void *)VMs[i]);
    if (status!=0) {
      printf("ERROR: Thread%d could not be created.", i);
      exit(-1);
    }
  }
}

void tpool_destroy() {
  int i;
  for (i=0; i<MaxThreadNum; i++) {
    pthread_join( Threads[i],
		  NULL);
  }
  free(Threads);


}


int exec(Ast *at) {
  unsigned long long t, time;
  int i;

#ifdef COUNT_INTERACTION
  for (i=0; i<MaxThreadNum; i++) {
    VM_ClearInteractionNum(VMs[i]);
  }
#endif

  void* code[MAX_CODE_SIZE];
  int apsnum = 0;

  start_timer(&t);
  EnvClear(CM_MODE_GLOBAL);

  if (!CompileStmListFromAst(ast_getNth(at,0))) return 0;

  RewriteAPListOnAST(at);
  at = ast_getNth(at,1);

  // Syntax error check
  {  Ast *tmp_at=at;
  while (tmp_at != NULL) {
    if (!check_invalid_occurrence(tmp_at->left->left)) return 0;
    if (!check_invalid_occurrence(tmp_at->left->right)) return 0;
    tmp_at = ast_getTail(tmp_at);
  }}


  while (at!=NULL) {
    int p1,p2;
    p1 = CompileTermFromAst(at->left->left, -1);
    p2 = CompileTermFromAst(at->left->right, -1);
    EnvAddCodeMYPUSH((void *)(unsigned long)p1, (void *)(unsigned long)p2);
    apsnum++;   //分散用
    at = ast_getTail(at);
  }
  EnvAddCode(CodeAddr[RET_FREE_LR]);  

  // checking whether names occur more than twice
  if (!Check_nameOccurrenceWithEnv()) {
    return 0;
  }
  // '0' means that generated codes are stored in code[0,...].
  ProduceCodeWithEnv(code,0);

  ExecCode(1, VMs[0], code);

  //分散用
  apsnum = apsnum / MaxThreadNum;
  if (apsnum == 0) apsnum = 1;
  for (i=1; i<MaxThreadNum; i++) {
    VALUE t1, t2;
    int j;
    for (j=0; j<apsnum; j++) {
      if (!VM_PopAPStack(VMs[0], &t1, &t2)) goto endloop;
      VM_PushAPStack(VMs[i], t1, t2);
    }
  }
 endloop:


  pthread_mutex_lock(&Sleep_lock);
  pthread_cond_broadcast(&APStack_not_empty);
  pthread_mutex_unlock(&Sleep_lock);

  usleep(10000);



  if (ActiveThreadNum != 0) {
    pthread_mutex_lock(&AllSleep_lock);
    pthread_cond_wait(&ActiveThread_all_sleep, &AllSleep_lock);
    pthread_mutex_unlock(&AllSleep_lock);
  }

  time=stop_timer(&t);

#ifdef COUNT_INTERACTION
  unsigned long total=0;
  for (i=0; i<MaxThreadNum; i++) {
    total += VM_GetInteractionNum(VMs[i]);
  }
  printf("(%lu interactions by %d threads, %.2f sec)\n", 
	 total,
	 MaxThreadNum,
	 (double)(time)/1000000.0);
#else
  printf("(%.2f sec by %d threads)\n", 	
          (double)(time)/1000000.0,
          MaxThreadNum);
#endif


  return 0;
}
#endif



int destroy() {

  return 0;
}

int main(int argc, char *argv[])
{ 
  int retrieve_flag = 1; // 1:エラー時にインタプリタへ復帰, 0:終了


#ifdef MY_YYLINENO
 initInfoLineno();
#endif

 // Pritty printing for local variables
#ifdef PRETTY_VAR
 Pretty_init();
#endif

  {
    int i, param;
    char *fname = NULL;

#ifndef MALLOC
    unsigned int max_AgentBuffer=100000;
    unsigned int min_AgentBuffer=20000;
#endif
    unsigned int max_APStack=10000;


    for (i=1; i<argc; i++) {
      if (*argv[i] == '-') {
	switch (*(argv[i] +1)) {
	case 'v':
	  printf("Inpla version %s\n", VERSION);
	  exit(-1);
	  break;
	case '-':
	case 'h':
	case '?':
	  puts("Usage: inpla [options]\n");
	  puts("Options:");
	  printf(" -f <filename>    set input file name          (Defalut is    STDIN)\n");
	  
#ifndef MALLOC
	  printf(" -c <number>      set the size of term cells   (Defalut is %8u)\n",
		 max_AgentBuffer);
#endif
	  
	  printf(" -x <number>      set the size of the AP stack (Default is %8u)\n",
		 max_APStack);
	  
#ifdef THREAD
	  printf(" -t <number>      set the number of threads    (Default is %8d)\n",
		 MaxThreadNum);
	  
#endif
	  
	  
	  printf(" -h               print this help message\n\n");
	  exit(-1);
	  break;
	  
	  
	case 'f' :
	  i++;
	  if (i < argc) {
	    fname = argv[i];
	    retrieve_flag = 0;
	  } else {
	    printf("ERROR: The option switch '-f' needs a string that specifies an input file name.");
	    exit(-1);
	  }
	  break;
	  
	  
	  
#ifndef MALLOC
	case 'c' :
	  i++;
	  if (i < argc) {
	    param = atoi(argv[i]);
	    if (param == 0) {
	      printf("ERROR: '%s' is illegal parameter for -c\n", argv[i]);
	      exit(-1);
	    }
	  } else {
	    printf("ERROR: The option switch '-c' needs a number as an argument.");
	    exit(-1);
	  }
	  max_AgentBuffer=param;
	  break;
#endif
	  
	case 'x' :
	  i++;
	  if (i < argc) {
	    param = atoi(argv[i]);
	    if (param == 0) {
	      printf("ERROR: '%s' is illegal parameter for -x\n", argv[i]);
	      exit(-1);
	    }
	  } else {
	    printf("ERROR: The option switch '-x' needs a number as an argument.");
	    exit(-1);
	  }
	  max_APStack=param;
	  break;
	  
	  
#ifdef THREAD
        case 't' :
	  i++;
	  if (i < argc) {
	    param = atoi(argv[i]);
	    if (param == 0) {
	      printf("ERROR: '%s' is illegal parameter for -t\n", argv[i]);
	      exit(-1);
	    }
	  } else {
	    printf("ERROR: The option switch '-t' needs a number as an argument.");
	    exit(-1);
	  }
	  
	  MaxThreadNum=param;
	  break;
#endif
	  
	  
	default:
	  printf("ERROR: Unrecognized option %s\n", argv[i]);
	  printf("Please use -h option for getting more information.\n\n");
	  exit(-1);
	}
      }
    }


    // Dealing with fname
    if (fname == NULL) {
      yyin = stdin;
      
    } else {
      if (!(yyin = fopen(fname, "r"))) {
	printf("Error: The file '%s' can not be opened.\n", fname);
	exit(-1);
      }
    }

    
    puts("------------------------------------------------------------");
    puts("      Inpla: Interaction nets as a programming language");
    printf("                     version %5s [built: %s]\n", 
	   VERSION, BUILT_DATE);
    puts("------------------------------------------------------------");
    
    max_AgentBuffer = min_AgentBuffer + max_AgentBuffer/MaxThreadNum;
    
    SymTable_Init();
    
    InitNameHashTable();
    InitRuleTable();
    
#ifdef THREAD
    GlobalAPStack_Init(max_APStack);
#endif
    
    ast_heapInit();
    
    CmEnv_Init(VM_LOCALVAR_SIZE);
    
    
    // builtin agents
    
    //  setNameToSymTable(ID_PAIR0, SYM_PAIR0);
    
    
#ifndef THREAD
    Init_VM(&VM, max_AgentBuffer, max_APStack);
#else
    tpool_init(max_AgentBuffer, max_APStack);
#endif    
    
    /*
      printf("Name size=%d\n", sizeof(Name));
      printf("Basic size=%d\n", sizeof(Basic));
      printf("VALUE size=%d\n", sizeof(VALUE));
      printf("IDTYPE size=%d\n", sizeof(IDTYPE));
    */
    
  }
  


  // the main loop of parsing and execution
  while(1) {

    if (yyin == stdin) printf("$ ");

    // When errors occur during parsing
    if (yyparse()!=0) {

      if (!retrieve_flag) {
	exit(0);
      }

      if (yyin != stdin) {
	fclose(yyin);
	while (yyin!=stdin) {
	  popFP();
	}
#ifdef MY_YYLINENO
	InfoLineno_AllDestroy();
#endif
      }

    }
  }

  exit(0);
}


#include "lex.yy.c"
