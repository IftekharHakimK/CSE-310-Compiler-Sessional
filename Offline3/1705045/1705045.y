
%{
#include<bits/stdc++.h>
using namespace std;

ofstream logout,errorout;
#include "SymbolTable.cpp"

#define YYSTYPE pair<string,string> // first-> full word, second-> int/float/... when necessary



int yyparse(void);
int yylex(void);

string a,b;

extern FILE *yyin;


SymbolTable *table = new SymbolTable(30);
SymbolInfo *info;
extern int line_count,error_count;
vector<pair<string,string>> declared_vars;
vector<pair<string,string>>declared_params;
vector<string>type_of_params;
vector<vector<string>>taken_arguments;

void yyerror(char *s)
{
	error_count++;
	logout<<"Error at line "<<line_count<<": syntax error"<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": syntax error"<<endl<<endl;
}


%}

%token IF ELSE FOR WHILE INT FLOAT DOUBLE CHAR RETURN VOID PRINTLN ADDOP MULOP ASSIGNOP RELOP LOGICOP NOT SEMICOLON COMMA LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD INCOP DECOP CONST_INT CONST_FLOAT ID
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		logout<<"Line "<<line_count<<": start : program"<<endl<<endl;
	}
	;

program : program unit 
		{
			$$.first=$1.first+"\n"+$2.first;
			logout<<"Line "<<line_count<<": program : program unit"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| unit 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": program : unit"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| error
		{
			$$={"",""};
			logout<<"Line "<<line_count<<": program : error"<<endl<<endl;
		}
		| program error
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": program : program error"<<endl<<endl;
			logout<<$1.first<<endl;
		}
	;
	
unit : var_declaration 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": unit : var_declaration"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
     	| func_declaration 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": unit : func_declaration"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
     	| func_definition 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": unit : func_definition"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 
				{
					$$.first=$1.first+" "+$2.first+$3.first+$4.first+$5.first+$6.first;
					logout<<"Line "<<line_count<<": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl<<endl;
					
					if(!table->fullLookup($2.first))
					{
						SymbolInfo * temp = NULL;
						temp = new functionInfo($2.first,"ID",$1.first);
						for(string s:type_of_params)
						{
							temp -> addParameter(s);
						}
						type_of_params.clear();
						table->Insert(temp);
					}
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;
					}
					logout<<$$.first<<endl<<endl;

					if(table->curName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
					}

				}
				| type_specifier ID LPAREN RPAREN SEMICOLON 
				{
					$$.first=$1.first+" "+$2.first+$3.first+$4.first+$5.first;
					logout<<"Line "<<line_count<<": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl<<endl;
					
					if(!table->Lookup($2.first))
					{
						SymbolInfo * temp = NULL;
						temp = new functionInfo($2.first,"ID",$1.first);
						for(string s:type_of_params)
						{
							temp -> addParameter(s);
						}
						type_of_params.clear();
						table->Insert(temp);
					}
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;
					}
					logout<<$$.first<<endl<<endl;

					if(table->curName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
					}
				}
				;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 	
				{	
			
					if(table->fullLookup($2.first)==NULL)
					{
						SymbolInfo * temp = new functionInfo($2.first,"ID",$1.first);
						table->InsertPrev(temp);
						
						for(int i=0;i<declared_params.size();i++)
						{
							if(declared_params[i].first.size()==0)
							{
								error_count++;
								logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
								errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
							}
						}

						for(auto u:declared_params)
						{
							if(!table->Lookup(u.first)&&u.first.size()>0)
								table->Insert(new variableInfo(u.first,"ID",u.second));
						}
						declared_params.clear();
																			
						for(string s:type_of_params)
						{
							temp -> addParameter(s);
						}
						type_of_params.clear();
						temp->setDefined();
					}
					else if(!table->fullLookup($2.first)->isDefined())
					{
						SymbolInfo * temp = table->fullLookup($2.first);

						if(temp->getParameterList().size()!=type_of_params.size())
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.first<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.first<<endl<<endl;

							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						else if(temp->getParameterList()!=type_of_params)
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Inconsistent function definition and declaration parameter list"<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Inconsistent function definition and declaration parameter list"<<endl<<endl;

							vector<string> params;


							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						else if(temp->getReturnType()!=$1.first)
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.first<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.first<<endl<<endl;

							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						else
						{
							for(int i=0;i<declared_params.size();i++)
							{
								if(declared_params[i].first.size()==0)
								{
									error_count++;
									logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
									errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
								}
							}
							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						temp->setDefined();
					}
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;

						for(auto u:declared_params)
						{
								table->Insert(new variableInfo(u.first,"ID",u.second));
						}
						declared_params.clear();
					}

					if(table->parentName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
					}
					type_of_params.clear();
					declared_params.clear();

				} compound_statement 
				{
					$$.first=$1.first+" "+$2.first+$3.first+$4.first+$5.first+$7.first;

					//cout<<"Compound "<<$7.first<<endl;

																	
					logout<<"Line "<<line_count<<": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| type_specifier ID LPAREN RPAREN
				{
					if(table->fullLookup($2.first)==NULL)
					{
						SymbolInfo * temp = new functionInfo($2.first,"ID",$1.first);
						table->InsertPrev(temp);
						
						for(int i=0;i<declared_params.size();i++)
						{
							if(declared_params[i].first.size()==0)
							{
								error_count++;
								logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
								errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
							}
						}

						for(auto u:declared_params)
						{
							if(!table->Lookup(u.first)&&u.first.size()>0)
								table->Insert(new variableInfo(u.first,"ID",u.second));
						}
						declared_params.clear();
																			
						for(string s:type_of_params)
						{
							temp -> addParameter(s);
						}
						type_of_params.clear();
						temp->setDefined();
					}
					else if(!table->fullLookup($2.first)->isDefined())
					{
						SymbolInfo * temp = table->fullLookup($2.first);

						if(temp->getParameterList().size()!=type_of_params.size())
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.first<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.first<<endl<<endl;

							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						else if(temp->getParameterList()!=type_of_params)
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Inconsistent function definition and declaration parameter list"<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Inconsistent function definition and declaration parameter list"<<endl<<endl;

							vector<string> params;


							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						else if(temp->getReturnType()!=$1.first)
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.first<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.first<<endl<<endl;

							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						else
						{
							for(int i=0;i<declared_params.size();i++)
							{
								if(declared_params[i].first.size()==0)
								{
									error_count++;
									logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
									errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.first<<endl<<endl;
								}
							}
							for(auto u:declared_params)
							{
								if(u.first.size()>0)
									table->Insert(new variableInfo(u.first,"ID",u.second));
							}
							declared_params.clear();
						}
						temp->setDefined();
					}
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.first<<endl<<endl;

						for(auto u:declared_params)
						{
								table->Insert(new variableInfo(u.first,"ID",u.second));
						}
						declared_params.clear();
					}
					if(table->parentName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.first<<endl<<endl;
					}
					type_of_params.clear();
					declared_params.clear();
				} compound_statement 	
				{
					$$.first=$1.first+" "+$2.first+$3.first+$4.first+$6.first;
					
					logout<<"Line "<<line_count<<": func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID 
				{
					$$.first=$1.first+$2.first+$3.first+" "+$4.first;
					
					if($3.first=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						type_of_params.push_back($3.first);
						declared_params.push_back({$4.first,$3.first});
					}
					else if(find(declared_params.begin(),declared_params.end(),make_pair($4.first,$3.first))==declared_params.end())
					{
						type_of_params.push_back($3.first);
						declared_params.push_back({$4.first,$3.first});
					}
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$4.first<<" in parameter"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$4.first<<" in parameter"<<endl<<endl;
						type_of_params.push_back($3.first);
						declared_params.push_back({$4.first,$3.first});
					}
					logout<<"Line "<<line_count<<": parameter_list : parameter_list COMMA type_specifier ID"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| parameter_list COMMA type_specifier 
				{
					$$.first=$1.first+$2.first+$3.first;
					logout<<"Line "<<line_count<<": parameter_list : parameter_list COMMA type_specifier"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
					if($3.first=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
					}
					type_of_params.push_back($3.first);
					declared_params.push_back({"",$3.first});
					
				}
				| type_specifier ID 
				{
					$$.first=$1.first+" "+$2.first;
					logout<<"Line "<<line_count<<": parameter_list : type_specifier ID"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
					type_of_params.clear();
					declared_params.clear();
					if($1.first=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
					}
					type_of_params.push_back($1.first);
					declared_params.push_back({$2.first,$1.first});
				}
				| type_specifier
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": parameter_list : type_specifier"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
					type_of_params.clear();
					if($1.first=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
					}
					type_of_params.push_back($1.first);
					declared_params.push_back({"",$1.first});
				}
				| error 
				{
					$$={"",""};
					logout<<"Line "<<line_count<<": parameter_list : error"<<endl<<endl;
				}
				| parameter_list error
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": parameter_list : error"<<endl<<endl;
					logout<<$1.first<<endl<<endl;
				}
				;

 		
compound_statement : LCURL statements RCURL 
				{
					$$.first=$1.first+"\n"+$2.first+$3.first;
					logout<<"Line "<<line_count<<": compound_statement : LCURL statements RCURL"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
					table->printAll();
					table->ExitScope();
				}
 		    	| LCURL RCURL
				{
					$$.first="{}";
					logout<<"Line "<<line_count<<": compound_statement : LCURL RCURL"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
					table->printAll();
					table->ExitScope();
				}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
				{
					$$.first=$1.first+" "+$2.first+$3.first;
					logout<<"Line "<<line_count<<": var_declaration : type_specifier declaration_list SEMICOLON"<<endl<<endl;
					
					if(!($1.first=="int"||$1.first=="char"||$1.first=="float"||$1.first=="double"))
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable type cannot be "<<$1.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable type cannot be "<<$1.first<<endl<<endl;
					}
					else
					{
						for(auto u:declared_vars)
						{
							string s = u.first;
							string length = u.second;
							if(!table->Lookup(s))
							{
								if(length.size()==0)
								{
									table->Insert(new variableInfo(s,"ID",$1.first));
								}
								else
								{
									table->Insert(new arrayInfo(s,"ID",length,$1.first));
								}
							}
							else
							{
								error_count++;
								logout<<"Error at line "<<line_count<<": Multiple declaration of "<<s<<endl<<endl;
								errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<s<<endl<<endl;
							}
						}
					}
					declared_vars.clear();
					logout<<$$.first<<endl<<endl;
				}
 		 ;
 		 
type_specifier : INT 
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": type_specifier : INT"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| FLOAT 
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": type_specifier : FLOAT"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| VOID 
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": type_specifier : VOID"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				;
 		
declaration_list : declaration_list COMMA ID 
				{
					$$.first=$1.first+$2.first+$3.first;
					
					if(!table->Lookup($3.first))
						declared_vars.push_back({$3.first,""});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.first<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : declaration_list COMMA ID"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
				{
					$$.first=$1.first+$2.first+$3.first+$4.first+$5.first+$6.first;
					
					if(!table->Lookup($3.first)) declared_vars.push_back({$3.first,$5.first});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.first<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| ID 
				{
					$$.first = $1.first;
					
					if(!table->Lookup($1.first)) declared_vars.push_back({$1.first,""});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.first<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : ID"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| ID LTHIRD CONST_INT RTHIRD 
				{
					$$.first=$1.first+$2.first+$3.first+$4.first;

					if(!table->Lookup($1.first)) declared_vars.push_back({$1.first,$3.first});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.first<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.first<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : ID LTHIRD CONST_INT RTHIRD"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| error 
				{
					$$={"",""};
					logout<<"Line "<<line_count<<": declaration_list : error"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| declaration_list error 
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": declaration_list : declaration_list error"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				;
 		  
statements : statement 
			{
				
				if($1.first.size()){ //recovery
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": statements : statement"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				else
				{
					$$={"",""};
				}
			}
			| statements statement 
			{
				if($2.first.size()){
					$$.first=$1.first+"\n"+$2.first;
					logout<<"Line "<<line_count<<": statements : statements statement"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				else
				{
					$$=$1;
				}
			}
			| statements func_declaration
			{
				$$.first=$1.first+$2.first;
				logout<<"Line "<<line_count<<": statements : statements func_declaration"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| statements func_definition
			{
				$$.first=$1.first+$2.first;
				logout<<"Line "<<line_count<<": statements : statements func_definition"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| func_declaration
			{
				$$=$1;
				logout<<"Line "<<line_count<<": statements : func_declaration"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| func_definition
			{
				$$=$1;
				logout<<"Line "<<line_count<<": statements : func_definition"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| error
			{
				$$={"",""};
				logout<<"Line "<<line_count<<": statements : error"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| statements error
			{
				$$.first=$1.first;
				logout<<"Line "<<line_count<<": statements : statements error"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			;
	   
statement : var_declaration 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": statement : var_declaration"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| expression_statement 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": statement : expression_statement"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| compound_statement 
		{
			$$.first=$1.first;
			logout<<"Line "<<line_count<<": statement : compound_statement"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement 
		{
			$$.first=$1.first+$2.first+$3.first+$4.first+$5.first+$6.first+$7.first;
			logout<<"Line "<<line_count<<": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		{
			$$.first=$1.first+$2.first+$3.first+$4.first+$5.first;
			logout<<"Line "<<line_count<<": statement : IF LPAREN expression RPAREN statement"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| IF LPAREN expression RPAREN statement ELSE statement 
		{
			$$.first=$1.first+$2.first+$3.first+$4.first+$5.first+$6.first+$7.first;
			logout<<"Line "<<line_count<<": statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| WHILE LPAREN expression RPAREN statement 
		{
			$$.first=$1.first+$2.first+$3.first+$4.first+$5.first;
			logout<<"Line "<<line_count<<": statement : WHILE LPAREN expression RPAREN statement"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON 
		{
			$$.first=$1.first+$2.first+$3.first+$4.first+$5.first;
			logout<<"Line "<<line_count<<": statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl<<endl;
			

			SymbolInfo * temp = table->fullLookup($3.first);
			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$3.first<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable"<<$3.first<<endl<<endl;
			}
			else if(temp->getClassType()!="variable")
			{
				error_count++;
				logout<<"Error at line no "<<line_count<<": "<<$3.first<<" cannot be printed"<<endl<<endl;
				errorout<<"Error at line no "<<line_count<<": "<<$3.first<<" cannot be printed"<<endl<<endl;
			}
			logout<<$$.first<<endl<<endl;
		}
		| RETURN expression SEMICOLON 
		{
			$$.first=$1.first+$2.first+$3.first;
			logout<<"Line "<<line_count<<": statement : RETURN expression SEMICOLON"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		;
	  
expression_statement 	: SEMICOLON 
						{
							$$.first=$1.first;
							logout<<"Line "<<line_count<<": expression : SEMICOLON"<<endl<<endl;
							logout<<$$.first<<endl<<endl;
						}
						| expression SEMICOLON  
						{
							$$.first=$1.first+$2.first;
							logout<<"Line "<<line_count<<": expression_statement : expression SEMICOLON"<<endl<<endl;
							logout<<$$.first<<endl<<endl;
						}
						;
	  
variable : ID 
		{
			$$.first=$1.first;

			logout<<"Line "<<line_count<<": variable : ID"<<endl<<endl;
			

			SymbolInfo * temp =table->fullLookup($1.first);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.first<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.first<<endl<<endl;
				$$.second="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.first<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.first<<" is a function"<<endl<<endl;
					$$.second="";
				}
				else if(temp->getClassType()!="array")
				{
					$$.second=temp->getSpecifier();
				}
				else
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.first<<" is an array"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.first<<" is an array"<<endl<<endl;
					$$.second="";
				}
			}
			logout<<$$.first<<endl<<endl;
		}
		| ID LTHIRD expression RTHIRD 
		{
			$$.first=$1.first+$2.first+$3.first+$4.first;
			logout<<"Line "<<line_count<<": variable : ID LTHIRD expression RTHIRD"<<endl<<endl;

			if($3.second!="int"&&$3.second.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				$$.second="";
			}

			SymbolInfo * temp =table->fullLookup($1.first);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.first<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.first<<endl;
				$$.second="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.first<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.first<<" is a function"<<endl<<endl;
					$$.second="";
				}
				if(temp->getClassType()!="array")
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": "<<$1.first<<" not an array"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": "<<$1.first<<" not an array"<<endl<<endl;

					$$.second="";
				}
				else
				{
					$$.second=temp->getSpecifier();
				}
			}
			
			logout<<$$.first<<endl<<endl;
		}
		;
	 
expression : logic_expression 
		{
			$$.first=$1.first;
			$$.second=$1.second;

			logout<<"Line "<<line_count<<": expression : logic expression"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| variable ASSIGNOP logic_expression 
		{
			$$.first=$1.first+$2.first+$3.first;
			$$.second=$1.second;
			logout<<"Line "<<line_count<<": expression : variable ASSIGNOP logic_expression"<<endl<<endl;

			if($3.second=="void")
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
				$$.second="";
			}
			else if((!(($1.second==$3.second)||($1.second=="float"&&$3.second=="int")))&&$1.second.size()>0&&$3.second.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Type Mismatch"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Type Mismatch"<<endl<<endl;
				$$.second="";
			}

			if($1.second.size()==0||$3.second.size()==0) $$.second="";
		   	
			logout<<$$.first<<endl<<endl;
		}
	   ;
			
logic_expression : rel_expression 
			{
				$$.first=$1.first;
				$$.second=$1.second;

				logout<<"Line "<<line_count<<": logic_expression : rel_expression"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}	
			| rel_expression LOGICOP rel_expression 
			{
				$$.first=$1.first+$2.first+$3.first;
				$$.second="int";

				logout<<"Line "<<line_count<<": logic_expression : rel_expression LOGICOP rel_expression"<<endl<<endl;

				if(($1.second=="void"||$3.second=="void")&&$1.second.size()>0&&$3.second.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					$$.second="";
				}
				else if(($1.second!="int"||$3.second!="int")&&$1.second.size()>0&&$3.second.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Wrong operand type for "<<$2.first<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": Wrong operand type for "<<$2.first<<endl<<endl;
					$$.second="";
				}
				if($1.second.size()==0||$3.second.size()==0) $$.second="";

				logout<<$$.first<<endl<<endl;
			} 	
			;
			
rel_expression	: simple_expression 
				{
					$$.first=$1.first;
					$$.second=$1.second;

					logout<<"Line "<<line_count<<": rel_expression : simple_expression"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| simple_expression RELOP simple_expression	
				{
					$$.first=$1.first+$2.first+$3.first;
					$$.second="int";

					if(($1.second=="void"||$3.second=="void")&&$1.second.size()>0&&$3.second.size()>0)
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
						$$.second="";
					}
					if($1.second.size()==0||$3.second.size()==0) $$.second="";

					logout<<"Line "<<line_count<<": rel_expression : simple_expression RELOP simple_expression"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				;
				
simple_expression : term 
			{
				$$.first=$1.first;
				$$.second=$1.second;

				logout<<"Line "<<line_count<<": simple_expression : term"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| simple_expression ADDOP term 
			{
				$$.first=$1.first+$2.first+$3.first;
				logout<<"Line "<<line_count<<": simple_expression : simple_expression ADDOP term"<<endl<<endl;

				if($1.second!="int"&&$1.second!="float"&&$3.second!="int"&&$3.second!="float"&&$1.second.size()>0&&$3.second.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Type mismatch for add/subtract"<<endl;
					errorout<<"Error at line "<<line_count<<": Type mismatch for add/subtract"<<endl;
					$$.second="";
				}
				else if($1.second=="float"||$3.second=="float") $$.second="float";
				else $$.second="int";

				if($1.second.size()==0||$3.second.size()==0) $$.second="";

				logout<<$$.first<<endl<<endl;
			}
			;
					
term :	unary_expression 
			{
				$$.first=$1.first;
				$$.second=$1.second;

				logout<<"Line "<<line_count<<": term : unary_expression"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| term MULOP unary_expression 
			{
				$$.first=$1.first+$2.first+$3.first;
				logout<<"Line "<<line_count<<": term : term MULOP unary_expression"<<endl<<endl;

				if(($3.second=="void"||$1.second=="void")&&$1.second.size()>0&&$3.second.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					$$.second="";
				}
				else if($2.first!="%"){
					if($1.second=="float"||$3.second=="float") $$.second="float";
					else $$.second="int";
				}
				else
				{
					if($1.second!="int"||$3.second!="int")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Non-Integer operand on modulus operator"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Non-Integer operand on modulus operator"<<endl<<endl;
						$$.second="";
					}
					else if($3.first=="0")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Modulus by Zero"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Modulus by Zero"<<endl<<endl;
						$$.second="";
					}
				}
				if($1.second.size()==0||$3.second.size()==0) $$.second="";
				logout<<$$.first<<endl<<endl;
			}
			;

unary_expression : ADDOP unary_expression 
				{
					$$.first=$1.first+$2.first;
					$$.second=$2.second;

					logout<<"Line "<<line_count<<": unary_expression : ADDOP unary_expression"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				} 
				| NOT unary_expression 
				{
					$$.first=$1.first+$2.first;
					logout<<"Line "<<line_count<<": unary_expression : NOT unary_expression"<<endl<<endl;
					$$.second="int";

					if($2.second!="int"&&$2.second.size()>0)
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid type for NOT operator"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid type for NOT operator"<<endl<<endl;
						$$.second="";
					}
					if($2.second.size()==0) $$.second="";
					
					logout<<$$.first<<endl<<endl;
				}
				| factor 
				{
					$$.first=$1.first;
					$$.second=$1.second;

					logout<<"Line "<<line_count<<": unary_expression : factor"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				;
	
factor	: variable 
		{
			$$.first=$1.first;
			$$.second=$1.second;

			logout<<"Line "<<line_count<<": factor : variable"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| ID LPAREN argument_list RPAREN 
		{
			$$.first=$1.first+$2.first+$3.first+$4.first;
			logout<<"Line "<<line_count<<": factor : ID LPAREN argument_list RPAREN"<<endl<<endl;

			SymbolInfo * temp=table->fullLookup($1.first);
			if(temp==NULL)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared function "<<$1.first<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared function "<<$1.first<<endl;
				$$.second="";
			}
			else
			{
				if(temp->getClassType()!="function")
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": "<<$1.first<<" is not a function "<<endl;
					errorout<<"Error at line "<<line_count<<": "<<$1.first<<" is not a function "<<endl;
					$$.second=""; 
				}
				else
				{
					$$.second=temp->getReturnType();
					vector<string>parameter_list = temp->getParameterList();
					vector<string>another=taken_arguments.back();

					if(temp->isDefined()==false)
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Function not defined "<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Function not defined "<<endl<<endl;
						$$.second="";
					}
					else if(parameter_list!=another)
					{
						if(parameter_list.size()!=another.size())
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Total number of arguments mismatch in function "<<$1.first<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Total number of arguments mismatch in function "<<$1.first<<endl<<endl;
							
						}
						else
						{
							for(int i=0;i<parameter_list.size();i++)
							{
								if(parameter_list[i]!=another[i]&&another[i].size()>0&&!(parameter_list[i]=="float"&&another[i]=="int"))
								{
									error_count++;
									logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th argument mismatch in function "<<$1.first<<endl<<endl;
									errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th argument mismatch in function "<<$1.first<<endl<<endl;
									break;
								}
							}
						}
					}
				}
				
				
			}
			taken_arguments.pop_back();

			
			logout<<$$.first<<endl<<endl;
		}
		| LPAREN expression RPAREN 
		{
			$$.first=$1.first+$2.first+$3.first;
			$$.second=$2.second;

			logout<<"Line "<<line_count<<": factor : LPAREN expression RPAREN"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| CONST_INT 
		{
			$$.first=$1.first;
			$$.second="int";

			logout<<"Line "<<line_count<<": factor : CONST_INT"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| CONST_FLOAT 
		{
			$$.first=$1.first;
			$$.second="float";

			logout<<"Line "<<line_count<<": factor : CONST_FLOAT"<<endl<<endl;
			logout<<$$.first<<endl<<endl;
		}
		| variable INCOP 
		{
			$$.first=$1.first+$2.first;
			logout<<"Line "<<line_count<<": factor : variable INCOP"<<endl<<endl;
			$$.second="int";

			if($1.second!="int"&&$1.second.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": "<<$2.first<<": should be used with integer variable"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": "<<$2.first<<": should be used with integer variable"<<endl<<endl;
				$$.second="";
			}
			if($1.second.size()==0) $$.second="";
			logout<<$$.first<<endl<<endl;
		}
		| variable DECOP 
		{
			$$.first=$1.first+$2.first;
			logout<<"Line "<<line_count<<": factor : variable DECOP"<<endl<<endl;
			$$.second="int";

			if($1.second!="int"&&$1.second.size()>0)
			{
				error_count++;
				logout<<"Error at line: "<<line_count<<" "<<$2.first<<" should be used with integer variable"<<endl<<endl;
				errorout<<"Error at line: "<<line_count<<" "<<$2.first<<" should be used with integer variable"<<endl<<endl;
				$$.second="";
			}
			if($1.second.size()==0) $$.second="";
			logout<<$$.first<<endl<<endl;
		}
		;
	
argument_list : arguments 
				{
					$$.first=$1.first;
					logout<<"Line "<<line_count<<": argument_list : arguments"<<endl<<endl;
					logout<<$$.first<<endl<<endl;
				}
				| 
				{
					$$.first="";
					logout<<"Line "<<line_count<<": argument_list : "<<endl<<endl;
					logout<<$$.first<<endl<<endl;
					taken_arguments.emplace_back();
				}
				;
	
arguments : arguments COMMA logic_expression 
			{
				$$.first=$1.first+$2.first+$3.first;
				logout<<"Line "<<line_count<<": arguments : arguments COMMA logic_expression"<<endl<<endl;
				logout<<$$.first<<endl<<endl;

				taken_arguments.back().push_back($3.second);

				//cout<<line_count<<' '<<$3.first<<' '<<$3.second<<endl;
			}
			| logic_expression 
			{
				$$.first=$1.first;
				logout<<"Line "<<line_count<<": arguments : logic_expression"<<endl<<endl;
				logout<<$$.first<<endl<<endl;

				taken_arguments.emplace_back();
				taken_arguments.back().push_back($1.second);

				//cout<<line_count<<' '<<$1.first<<' '<<$1.second<<endl;

			}
			| error
			{
				$$={"",""};
				logout<<"Line "<<line_count<<": arguments : error"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			| arguments error
			{
				$$.first=$1.first;
				logout<<"Line "<<line_count<<": arguments : arguments error"<<endl<<endl;
				logout<<$$.first<<endl<<endl;
			}
			;

%%

int main(int argc,char *argv[])
{
	FILE * fp;
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logout.open(argv[2]);
	errorout.open(argv[3]);

	yyin=fp;
	yyparse();

	table->printAll();
	logout<<"Total lines : "<<line_count<<endl;
	logout<<"Total errors : "<<error_count<<endl;
	

	logout.close();
	errorout.close();
	
	return 0;
}

