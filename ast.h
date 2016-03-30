#ifndef _AST_
#define _AST_

typedef enum {
  AST_SYM=0, AST_NAME, AST_INTNAME, AST_AGENT, AST_AP, AST_RULE,

  // this is for ASTLIST
  AST_LIST,

  // annotation
  AST_ANNOTATION_L, AST_ANNOTATION_R, 

  // builtin tuble
  AST_TUPLE,

  // operation
  AST_INT, AST_LD, AST_PLUS, AST_SUB, AST_MUL, AST_DIV, AST_MOD,
  AST_LT, AST_LE, AST_EQ, AST_NE, AST_UNM,

  // for built-in lists
  AST_CONS, AST_NIL, AST_OPCONS,

  AST_RAND, AST_SRAND,

} AST_ID;


typedef struct abstract_syntax_tree {
  AST_ID id;
  int intval;
  char *sym;
  struct abstract_syntax_tree *left,*right;
} Ast;

void ast_heapInit(void);
void ast_heapReInit(void);
Ast *ast_makeSymbol(char *name);
Ast *ast_makeInt(int num);
Ast *ast_makeAST(AST_ID id, Ast *left, Ast *right);
Ast *ast_makeTuple(Ast *tuple);
Ast *ast_addLast(Ast *l, Ast *p);
Ast *ast_getNth(Ast *p,int nth);
Ast *ast_getTail(Ast *p);
void puts_ast(Ast *p);
Ast *ast_paramToCons(Ast *ast);
void ast_recordConst(char *name, int val);


#define ast_makeCons(x1,x2) ast_makeAST(AST_LIST,x1,x2)
#define ast_makeList1(x1) ast_makeAST(AST_LIST,x1,NULL)
#define ast_makeList2(x1,x2) ast_makeAST(AST_LIST,x1,ast_makeAST(AST_LIST,x2,NULL))
#define ast_makeList3(x1,x2,x3) ast_makeAST(AST_LIST,x1,ast_makeAST(AST_LIST,x2,ast_makeAST(AST_LIST,x3,NULL)))
#define getFirst(p) getNth(p,0)


#endif
