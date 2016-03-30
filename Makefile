PROJECT_NAME = inpla
CC = gcc
#THREAD_OPTION = -DTHREAD -DLOCK_FREE_QUEUE -lpthread -O3 -g -m32 
THREAD_OPTION = -O3 -DTHREAD 
#OPTION = -O3 -DMALLOC
OPTION = -O3 

$(PROJECT_NAME) : lex.yy.c $(PROJECT_NAME).tab.c ast.o
	$(CC) -Wall $(OPTION) -o $(PROJECT_NAME)  $(PROJECT_NAME).tab.c ast.o -lfl

ast.o: ast.c ast.h
	$(CC) -Wall $(OPTION) -o $@ -c $<


$(PROJECT_NAME).tab.c : $(PROJECT_NAME).y
	bison $^

lex.yy.c : $(PROJECT_NAME).l
#	flex -CF $^
	flex $^

clean :
	rm lex.yy.c $(PROJECT_NAME).tab.c $(PROJECT_NAME) ast.o

thread : lex.yy.c $(PROJECT_NAME).tab.c ast.o
	$(CC) -Wall -o $(PROJECT_NAME) $(THREAD_OPTION) $(PROJECT_NAME).tab.c ast.o -lfl -lpthread
