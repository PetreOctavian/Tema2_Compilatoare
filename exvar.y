%{
	#include <stdio.h>
     	#include <string.h>


	extern int lineNo;
	extern int colNo;

	int yylex();
	int yyerror(const char *msg);

     	int EsteCorecta = 1;
	char msg[500];

	class TVAR
	{
	     char* nume;
	     int valoare;
	     TVAR* next;
	  
	  public:
	     static TVAR* head;
	     static TVAR* tail;

	     TVAR(char* n, int v = -1);
	     TVAR();
	     int exists(char* n);
             void add(char* n, int v = -1);
             int getValue(char* n);
	     void setValue(char* n, int v);
	};

	TVAR* TVAR::head;
	TVAR* TVAR::tail;

	TVAR::TVAR(char* n, int v)
	{
	 this->nume = new char[strlen(n)+1];
	 strcpy(this->nume,n);
	 this->valoare = v;
	 this->next = NULL;
	}

	TVAR::TVAR()
	{
	  TVAR::head = NULL;
	  TVAR::tail = NULL;
	}

	int TVAR::exists(char* n)
	{
	  TVAR* tmp = TVAR::head;
	  while(tmp != NULL)
	  {
	    if(strcmp(tmp->nume,n) == 0)
	      return 1;
            tmp = tmp->next;
	  }
	  return 0;
	 }

         void TVAR::add(char* n, int v)
	 {
	   TVAR* elem = new TVAR(n, v);
	   if(head == NULL)
	   {
	     TVAR::head = TVAR::tail = elem;
	   }
	   else
	   {
	     TVAR::tail->next = elem;
	     TVAR::tail = elem;
	   }
	 }

         int TVAR::getValue(char* n)
	 {
	   TVAR* tmp = TVAR::head;
	   while(tmp != NULL)
	   {
	     if(strcmp(tmp->nume,n) == 0)
	      return tmp->valoare;
	     tmp = tmp->next;
	   }
	   return -1;
	  }

	  void TVAR::setValue(char* n, int v)
	  {
	    TVAR* tmp = TVAR::head;
	    while(tmp != NULL)
	    {
	      if(strcmp(tmp->nume,n) == 0)
	      {
		tmp->valoare = v;
	      }
	      tmp = tmp->next;
	    }
	  }

	TVAR* ts = NULL;

	int nr = 0;
	char* TOK_id_VECTOR[100];

%}


%union { char* sir; int val;}

%token TOK_PROGRAM TOK_VAR TOK_BEGIN TOK_END TOK_INTEGER TOK_DIV TOK_READ TOK_WRITE TOK_FOR TOK_DO TOK_TO TOK_PLUS TOK_MINUS TOK_MULTIPLY TOK_LEFT TOK_RIGHT TOK_ASSIGN TOK_int TOK_ERROR 

%token <sir> TOK_id

%locations

%start prog

%left TOK_PLUS TOK_MINUS
%left TOK_MULTIPLY TOK_DIVIDE

%%


prog :
    TOK_PROGRAM prog_name TOK_VAR dec_list TOK_BEGIN stmt_list TOK_END
    	;
prog_name : 
	TOK_id 
    	;
dec_list :
	dec 
	|
	dec_list ';' dec
		;
dec :
	id_list ':' type
	{
		for(int i = 0 ; i < nr; i++)
		{
			if(ts->exists(TOK_id_VECTOR[i]))
				{
					printf("Eroare semantica in cazul lui '%s' : declarare multipla la linia %d\n",TOK_id_VECTOR[i], lineNo);
					EsteCorecta = 0;
				}
			else ts->add(TOK_id_VECTOR[i]);
		}			
	}
     ;
type :
	TOK_INTEGER
	;
id_list :
    	TOK_id
	{  	nr = 0;
		TOK_id_VECTOR[nr] = $1;
		nr++;
	}
	|
	id_list ',' TOK_id
	{
		TOK_id_VECTOR[nr] = $3;
		nr++;
	}
	;
stmt_list :
	stmt
	|
	stmt_list ';' stmt
	;
stmt :
	assign
	|
	read
	|
	write
	|
    for
	;
assign :
	TOK_id TOK_ASSIGN exp
	{	if(!ts->exists($1))
		{
			printf("Eroare semantica in cazul lui '%s' : asignare fara declaratie la linia %d\n",$1, lineNo);
			EsteCorecta = 0;
		}
		else ts->setValue($1,1);
	}		
	;
exp :
	term
	|
	exp TOK_PLUS term
	|
	exp TOK_MINUS term
	;
term :
	factor
	|
	term TOK_MULTIPLY factor
	|
	term TOK_DIV factor
	;
factor :
	TOK_id
	{
		
		if(ts->getValue($1) != 1)
			{
				printf("Eroare semantica in cazul lui '%s' : folosire fara asignare la linia %d\n",$1, lineNo);
				EsteCorecta = 0;
			}
		else if(!ts->exists($1))
			{
				printf("Eroare semantica in cazul lui '%s' : folosire fara declarare la linia %d\n",$1, lineNo);
				EsteCorecta = 0;
			}
	}			
	|
	TOK_int
	|
	TOK_LEFT exp TOK_RIGHT
	;
read :
	TOK_READ TOK_LEFT id_list TOK_RIGHT
	{
		for(int i = 0 ; i < nr; i++)
		{
			if(!ts->exists(TOK_id_VECTOR[i]))
				{
					printf("Eroare semantica in cazul lui '%s': asignare fara declarare la linia %d\n",TOK_id_VECTOR[i], lineNo);
					EsteCorecta = 0;
				}
			else ts->setValue(TOK_id_VECTOR[i],1);
		}			
	}
	;
write :
	TOK_WRITE TOK_LEFT id_list TOK_RIGHT
	{
		for(int i = 0 ; i < nr; i++)
		{
			if(ts->getValue(TOK_id_VECTOR[i]) != 1)
				{
					printf("Eroare semantica in cazul lui '%s': scriere fara asignare la linia %d\n",TOK_id_VECTOR[i], lineNo);
					EsteCorecta = 0;
				}
			else if(!ts->exists(TOK_id_VECTOR[i]))
				{
					printf("Eroare semantica in cazul lui '%s' : scriere fara declarare la linia %d\n",TOK_id_VECTOR[i], lineNo);
					EsteCorecta = 0;
				}
		}			
	}
	;
for :
	TOK_FOR index_exp TOK_DO body
	;
index_exp :
	TOK_id TOK_ASSIGN exp TOK_TO exp
	{	if(!ts->exists($1))
		{
			printf("Eroare semantica in cazul lui '%s' : asignare fara declarare la linia %d\n",$1, lineNo);
			EsteCorecta = 0;
		}
		else ts->setValue($1,1);
	}		
	;
body :
	stmt
	|
	TOK_BEGIN stmt_list TOK_END
	;

	
%%

int yyerror(const char *msg)
{
	printf("Eroare sintactica la linia %d\n",lineNo);
	EsteCorecta = 0;
	return 1;
}


int main()
{
	try{
		
		yyparse();
	}
	catch(int)
	{
		printf("Eroare lexicala la linia %d \n", yylloc.first_line);
		EsteCorecta = 0;
	}

	if(EsteCorecta == 1)
	{
		printf("CORECT!\n");		
	}
	else 
	{
		printf("GRESIT!\n");		
	}	

       return 0;
}


