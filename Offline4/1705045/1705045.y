
%{
#include<bits/stdc++.h>
using namespace std;

ofstream logout,errorout,asmout,optimized_asmout;
#include "SymbolTable.cpp"

#define YYSTYPE pair<pair<string,string>,pair<string,string>> // first-> full word, second-> int/float/... when necessary

#define word first.first
#define type first.second
#define code second.first
#define ret second.second

string prepare_comment(string s)
{
	for(auto &u:s)
	{
		if(u=='\n')
		{
			u=' ';
		}
	}
	s=";"+s+"\n";
	return s;
}

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

vector<string>cur_saved_params; 		//these 5
int cur_scope_param_size;   			//should be  
vector<vector<string>>cur_saved_args;	//cleared accordingly
set<string>cur_saved_variables;		
string inside_function;

set<string>single_data;
vector<pair<string,string>>array_data;

int label_count;
string new_label()
{
	label_count++;
	string s;
	stringstream ss;  
  	ss << label_count;  
  	ss >> s;
	s="label_"+s;
	return s;
}

set<string>saved_temp;

void tryToRemove(string temp)
{
	if(saved_temp.find(temp)!=saved_temp.end()){
		saved_temp.erase(temp);
		cur_saved_variables.erase(temp);
		logout<<"delete "<<temp<<endl;
	}
}

string new_temp()
{
	for(int i=1;;i++)
	{
		string s;
		stringstream ss;  
		ss << i;  
		ss >> s;
		s="temp_"+s;
		if(saved_temp.find(s)==saved_temp.end())
		{
			single_data.insert(s);
			saved_temp.insert(s);
			cur_saved_variables.insert(s);
			logout<<"create "<<s<<endl;
			return s;
		}
	}
}



void yyerror(char *s)
{
	error_count++;
	logout<<"Error at line "<<line_count<<": syntax error"<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": syntax error"<<endl<<endl;
}

vector<string> split(string s) //splits for comma and space, used in peephole
{
	vector<string>v;
	string cur;
	for(char u:s)
	{
		if(u==' '||u==',')
		{
			if(cur.size())
			{
				v.push_back(cur);
				cur.clear();
			}
		}
		else if(u==':')
		{
			if(cur.size())
			{
				v.push_back(cur);
				cur.clear();
			}
			v.push_back(":");
		}
		else
		{
			cur+=u;
		}
	}
	if(cur.size())
	{
		v.push_back(cur);
	}
	return v;
}

string all(string arg)
{
    return arg;
}
template<typename ...T>
string all(string arg, T... args)
{
    string s=all(arg);
	s+=all(args...);
	return s;
}

%}

%token IF ELSE FOR WHILE INT FLOAT DOUBLE CHAR RETURN VOID PRINTLN ADDOP MULOP ASSIGNOP RELOP LOGICOP NOT SEMICOLON COMMA LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD INCOP DECOP CONST_INT CONST_FLOAT ID
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		logout<<"Line "<<line_count<<": start : program"<<endl<<endl;
		if(error_count==0){
			//Writing to code.asm
			asmout<<".MODEL SMALL"<<endl<<endl;
			asmout<<".STACK 1000H"<<endl<<endl;
			asmout<<".DATA"<<endl;
			for(auto u:single_data)
				asmout<<u<<" DW ?"<<endl;
			for(auto u:array_data)
				asmout<<u.first<<" DW "<<u.second<<" dup(?)"<<endl;
			asmout<<endl;
			asmout<<".CODE"<<endl;
			asmout<<$1.code<<endl;
			asmout<<endl<<endl<<";PRINT LIBRARY"<<endl;
			ifstream print_header;
			print_header.open("asm_header_for_print.txt");
			string x;
			while(getline(print_header,x))
			{
				asmout<<x<<endl;
			}
			print_header.close();
			asmout<<"END MAIN"<<endl;
			
			//Writing to code.asm ended

			//2nd pass, peephole optimization. Writing to optimized_code.asm
			

			ifstream asmin1;
			asmin1.open("code.asm");
			map<string,string>replace;
			string last_line,current_line;
			while(getline(asmin1,current_line))
			{
				vector<string>v1=split(last_line);
				vector<string>v2=split(current_line);

				if(v1.size()==2&&v2.size()==2&&v1[1]==":"&&v2[1]==":")
				{
					//cout<<last_line<<' '<<current_line<<endl;
					replace[v2[0]]=v1[0];
				}
				else
				{
					if(current_line.size())
					{
						last_line=current_line;
					}
				}
				
			}
			asmin1.close();
			
			ifstream asmin2;
			asmin2.open("code.asm");
			last_line.clear();
			current_line.clear(); 
			while(getline(asmin2,current_line))
			{
				vector<string>v1=split(last_line);
				vector<string>v2=split(current_line);
				bool ignoreLine=0;

				

				if(v1.size()==3&&v2.size()==3&&v1[0]=="MOV"&&v2[0]=="MOV"&&v1[1]==v2[2]&&v1[2]==v2[1])
				{
					ignoreLine=1;
				}
				if(v2.size()==2&&(v2[0]=="JMP"||v2[0]=="JLE"||v2[0]=="JL"||v2[0]=="JGE"||v2[0]=="JG"||v2[0]=="JE"||v2[0]=="JNE"))
				{
					if(replace.count(v2[1]))
					{
						optimized_asmout<<v2[0]<<' '<<replace[v2[1]]<<'\n';
						ignoreLine=1;
						last_line=v2[0]+" "+replace[v2[1]];
					}
				}
				if(v2.size()==2&&v2[1]==":"&&replace.count(v2[0]))
				{
					ignoreLine=1;
				}
				if(!ignoreLine)
				{
					optimized_asmout<<current_line<<'\n';
					if(current_line.size())
					{
						last_line=current_line;
					}
				}
			}
			asmin2.close();
		}
	}
	;

program : program unit 
		{
			$$.word=$1.word+"\n"+$2.word;
			logout<<"Line "<<line_count<<": program : program unit"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=all($1.code,$2.code);
		}
		| unit 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": program : unit"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=$1.code;
		}
		| error
		{
			$$={{"",""},{"",""}};
			logout<<"Line "<<line_count<<": program : error"<<endl<<endl;
		}
		| program error
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": program : program error"<<endl<<endl;
			logout<<$1.word<<endl;
			$$.code=$1.code;
		}
	;
	
unit : var_declaration 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": unit : var_declaration"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
		}
     	| func_declaration 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": unit : func_declaration"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
		}
     	| func_definition 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": unit : func_definition"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=$1.code;
		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 
				{
					$$.word=$1.word+" "+$2.word+$3.word+$4.word+$5.word+$6.word;
					logout<<"Line "<<line_count<<": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl<<endl;
					
					if(!table->fullLookup($2.word))
					{
						SymbolInfo * temp = NULL;
						temp = new functionInfo($2.word,"ID",$1.word);
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
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;
					}
					logout<<$$.word<<endl<<endl;

					if(table->curName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
					}

				}
				| type_specifier ID LPAREN RPAREN SEMICOLON 
				{
					$$.word=$1.word+" "+$2.word+$3.word+$4.word+$5.word;
					logout<<"Line "<<line_count<<": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl<<endl;
					
					if(!table->Lookup($2.word))
					{
						SymbolInfo * temp = NULL;
						temp = new functionInfo($2.word,"ID",$1.word);
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
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;
					}
					logout<<$$.word<<endl<<endl;

					if(table->curName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
					}
				}
				;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 	
				{	
					inside_function=$2.word;

					for(auto u:declared_params)
					{
						cur_saved_params.push_back(u.first+table->curName());
						single_data.insert(u.first+table->curName());
					}
					cur_scope_param_size=cur_saved_params.size();
					
					if(table->fullLookup($2.word)==NULL)
					{
						SymbolInfo * temp = new functionInfo($2.word,"ID",$1.word);
						table->InsertPrev(temp);
						
						for(int i=0;i<declared_params.size();i++)
						{
							if(declared_params[i].first.size()==0)
							{
								error_count++;
								logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
								errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
							}
						}

						for(auto u:declared_params)
						{
							if(!table->Lookup(u.first)&&u.first.size()>0)
							{
								table->Insert(new variableInfo(u.first,"ID",u.second));
							}
						}
						declared_params.clear();
																			
						for(string s:type_of_params)
						{
							temp -> addParameter(s);
						}
						type_of_params.clear();
						temp->setDefined();
					}
					else if(!table->fullLookup($2.word)->isDefined())
					{
						SymbolInfo * temp = table->fullLookup($2.word);
						if(temp->getParameterList().size()!=type_of_params.size())
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.word<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.word<<endl<<endl;

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
						else if(temp->getReturnType()!=$1.word)
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.word<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.word<<endl<<endl;

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
									logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
									errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
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
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;

						for(auto u:declared_params)
						{
								table->Insert(new variableInfo(u.first,"ID",u.second));
						}
						declared_params.clear();
					}

					if(table->parentName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
					}
					type_of_params.clear();
					declared_params.clear();

				} compound_statement 
				{
					$$.word=$1.word+" "+$2.word+$3.word+$4.word+$5.word+$7.word;
										
					logout<<"Line "<<line_count<<": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl<<endl;
					logout<<$$.word<<endl<<endl;

					if(error_count==0){
						int X=14;
						if($1.word!="void") X=16;
						/*
						func_id PROC
						PUSH AX
						PUSH BX
						PUSH CX
						PUSH DX
						PUSH BP
						PUSH SI
						MOV BP, SP
						take all params from stack 
						$7.code
						POP SI
						POP BP
						POP DX
						POP CX
						POP BX
						POP AX
						--RET number of param*2 should come automatically by WORD PTR[BP+X(14 for void, 16 for others) +i*2] as i=0,1.. from back
						--RETURN IN WORD PTR[BP+14]
						func_id ENDP
						*/

						$$.code=all("function_"+$2.word," PROC","\n",
									"PUSH AX","\n",
									"PUSH BX","\n",
									"PUSH CX","\n",
									"PUSH DX","\n",
									"PUSH BP","\n",
									"PUSH SI","\n",
									"MOV BP, SP","\n"
						);
						int i=0;
						for(auto itr=cur_saved_params.rbegin();itr!=cur_saved_params.rend();itr++)
						{
							$$.code+=all("MOV AX,", "WORD PTR[BP+",to_string(X+i*2),"]","\n",
										"MOV ",*itr,", AX","\n");
							i++;
						}
						$$.code+=$7.code;

						if($1.word=="void"){
							$$.code+=all(
										"POP SI","\n",
										"POP BP","\n",
										"POP DX","\n",
										"POP CX","\n",
										"POP BX","\n",
										"POP AX","\n",
										"RET 0","\n");
						}
						$$.code+=all("function_"+$2.word," ENDP","\n","\n","\n");
						cur_saved_params.clear();
						cur_saved_variables.clear();
					}
				}
				| type_specifier ID LPAREN RPAREN
				{
					inside_function=$2.word;

					cur_saved_params.clear();
					cur_scope_param_size=0;
					


					if(table->fullLookup($2.word)==NULL)
					{
						SymbolInfo * temp = new functionInfo($2.word,"ID",$1.word);
						table->InsertPrev(temp);
						
						for(int i=0;i<declared_params.size();i++)
						{
							if(declared_params[i].first.size()==0)
							{
								error_count++;
								logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
								errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
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
					else if(!table->fullLookup($2.word)->isDefined())
					{
						SymbolInfo * temp = table->fullLookup($2.word);

						if(temp->getParameterList().size()!=type_of_params.size())
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.word<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Total number of arguments mismatch with declaration in function "<<$2.word<<endl<<endl;

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
						else if(temp->getReturnType()!=$1.word)
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.word<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Return type mismatch with function declaration in function "<<$2.word<<endl<<endl;

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
									logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
									errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th parameter's name not given in function definition of "<<$2.word<<endl<<endl;
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
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$2.word<<endl<<endl;

						for(auto u:declared_params)
						{
								table->Insert(new variableInfo(u.first,"ID",u.second));
						}
						declared_params.clear();
					}
					if(table->parentName()!="1")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid scoping of function "<<$2.word<<endl<<endl;
					}
					type_of_params.clear();
					declared_params.clear();
				} compound_statement 	
				{
					$$.word=$1.word+" "+$2.word+$3.word+$4.word+$6.word;
					
					logout<<"Line "<<line_count<<": func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					if(error_count==0){
						string label=$2.word;

						
						if(label=="main")
						{
							$$.code=label+" PROC\n"+
									"MOV AX, @DATA\n"+
									"MOV DS, AX\n"+
									$6.code+'\n'+
									";DOS EXIT"+'\n'+
									"MOV AH, 4CH"+'\n'+
									"INT 21H"+'\n'+
									label+" ENDP"+'\n'; 
						}
						else
						{
							$$.code=all("function_"+$2.word," PROC","\n",
									"PUSH AX","\n",
									"PUSH BX","\n",
									"PUSH CX","\n",
									"PUSH DX","\n",
									"PUSH BP","\n",
									"PUSH SI","\n",
									"MOV BP, SP","\n"
								);
							int i=0;
							for(auto itr=cur_saved_params.rbegin();itr!=cur_saved_params.rend();itr++)
							{
								$$.code+=all("MOV AX,", "WORD PTR[BP+",to_string(14+i*2),"]","\n",
											"MOV ",*itr,", AX","\n");
								i++;
							}
							$$.code+=$6.code;
							if($1.word=="void"){
									$$.code+=all(
									"POP SI","\n",
									"POP BP","\n",
									"POP DX","\n",
									"POP CX","\n",
									"POP BX","\n",
									"POP AX","\n",
									"RET 0","\n");
							}
							$$.code+=all("function_"+$2.word," ENDP","\n","\n","\n");
						}

						cur_saved_params.clear();
						cur_saved_variables.clear();
					}
				}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID 
				{
					$$.word=$1.word+$2.word+$3.word+" "+$4.word;
					
					if($3.word=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						type_of_params.push_back($3.word);
						declared_params.push_back({$4.word,$3.word});
					}
					else if(find(declared_params.begin(),declared_params.end(),make_pair($4.word,$3.word))==declared_params.end())
					{
						type_of_params.push_back($3.word);
						declared_params.push_back({$4.word,$3.word});
					}
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$4.word<<" in parameter"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$4.word<<" in parameter"<<endl<<endl;
						type_of_params.push_back($3.word);
						declared_params.push_back({$4.word,$3.word});
					}
					logout<<"Line "<<line_count<<": parameter_list : parameter_list COMMA type_specifier ID"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| parameter_list COMMA type_specifier 
				{
					$$.word=$1.word+$2.word+$3.word;
					logout<<"Line "<<line_count<<": parameter_list : parameter_list COMMA type_specifier"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					if($3.word=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
					}
					type_of_params.push_back($3.word);
					declared_params.push_back({"",$3.word});
					
				}
				| type_specifier ID 
				{
					$$.word=$1.word+" "+$2.word;
					logout<<"Line "<<line_count<<": parameter_list : type_specifier ID"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					type_of_params.clear();
					declared_params.clear();
					if($1.word=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
					}
					type_of_params.push_back($1.word);
					declared_params.push_back({$2.word,$1.word});
				}
				| type_specifier
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": parameter_list : type_specifier"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					type_of_params.clear();
					if($1.word=="void")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable cannot be of void type"<<endl<<endl;
					}
					type_of_params.push_back($1.word);
					declared_params.push_back({"",$1.word});
				}
				| error 
				{
					$$={{"",""},{"",""}};
					logout<<"Line "<<line_count<<": parameter_list : error"<<endl<<endl;
				}
				| parameter_list error
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": parameter_list : error"<<endl<<endl;
					logout<<$1.word<<endl<<endl;
				}
				;

 		
compound_statement : LCURL statements RCURL 
				{
					$$.word=$1.word+"\n"+$2.word+$3.word;
					logout<<"Line "<<line_count<<": compound_statement : LCURL statements RCURL"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					table->printAll();
					table->ExitScope();

					$$.code=$2.code;
				}
 		    	| LCURL RCURL
				{
					$$.word="{}";
					logout<<"Line "<<line_count<<": compound_statement : LCURL RCURL"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					table->printAll();
					table->ExitScope();
				}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
				{
					$$.word=$1.word+" "+$2.word+$3.word;
					logout<<"Line "<<line_count<<": var_declaration : type_specifier declaration_list SEMICOLON"<<endl<<endl;
					
					if(!($1.word=="int"||$1.word=="char"||$1.word=="float"||$1.word=="double"))
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Variable type cannot be "<<$1.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Variable type cannot be "<<$1.word<<endl<<endl;
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
									table->Insert(new variableInfo(s,"ID",$1.word));
									single_data.insert(s+table->curName());
									cur_saved_variables.insert(s+table->curName());
								}
								else
								{
									table->Insert(new arrayInfo(s,"ID",length,$1.word));
									array_data.push_back({s+table->curName(),length});
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
					logout<<$$.word<<endl<<endl;
				}
 		 ;
 		 
type_specifier : INT 
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": type_specifier : INT"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| FLOAT 
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": type_specifier : FLOAT"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| VOID 
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": type_specifier : VOID"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				;
 		
declaration_list : declaration_list COMMA ID 
				{
					$$.word=$1.word+$2.word+$3.word;
					
					if(!table->Lookup($3.word))
						declared_vars.push_back({$3.word,""});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.word<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : declaration_list COMMA ID"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
				{
					$$.word=$1.word+$2.word+$3.word+$4.word+$5.word+$6.word;
					
					if(!table->Lookup($3.word)) declared_vars.push_back({$3.word,$5.word});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$3.word<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| ID 
				{
					$$.word = $1.word;
					
					if(!table->Lookup($1.word)) declared_vars.push_back({$1.word,""});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.word<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : ID"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| ID LTHIRD CONST_INT RTHIRD 
				{
					$$.word=$1.word+$2.word+$3.word+$4.word;

					if(!table->Lookup($1.word)) declared_vars.push_back({$1.word,$3.word});
					else
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.word<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Multiple declaration of "<<$1.word<<endl<<endl;
					}
					logout<<"Line "<<line_count<<": declaration_list : ID LTHIRD CONST_INT RTHIRD"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| error 
				{
					$$={{"",""},{"",""}};
					logout<<"Line "<<line_count<<": declaration_list : error"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				| declaration_list error 
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": declaration_list : declaration_list error"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				;
 		  
statements : statement 
			{
				
				if($1.word.size()){ //recovery
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": statements : statement"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				else
				{
					$$={{"",""},{"",""}};
				}
				$$.code=$1.code;
			}
			| statements statement 
			{
				if($2.word.size()){
					$$.word=$1.word+"\n"+$2.word;
					logout<<"Line "<<line_count<<": statements : statements statement"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
				}
				else
				{
					$$=$1;
				}
				$$.code=$1.code+$2.code;
				
			}
			| statements func_declaration
			{
				$$.word=$1.word+$2.word;
				logout<<"Line "<<line_count<<": statements : statements func_declaration"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			| statements func_definition
			{
				$$.word=$1.word+$2.word;
				logout<<"Line "<<line_count<<": statements : statements func_definition"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			| func_declaration
			{
				$$=$1;
				logout<<"Line "<<line_count<<": statements : func_declaration"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			| func_definition
			{
				$$=$1;
				logout<<"Line "<<line_count<<": statements : func_definition"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			| error
			{
				$$={{"",""},{"",""}};
				logout<<"Line "<<line_count<<": statements : error"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			| statements error
			{
				$$.word=$1.word;
				logout<<"Line "<<line_count<<": statements : statements error"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			;
	   
statement : var_declaration 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": statement : var_declaration"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=$1.code;
		}
		| expression_statement 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": statement : expression_statement"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=$1.code;
			$$.code=prepare_comment($$.word)+$$.code;
		}
		| compound_statement 
		{
			$$.word=$1.word;
			logout<<"Line "<<line_count<<": statement : compound_statement"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=$1.code;
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement 
		{
			$$.word=$1.word+$2.word+$3.word+$4.word+$5.word+$6.word+$7.word;
			logout<<"Line "<<line_count<<": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			
			/*
			$3.code
			label1:
			$4.code
			CMP $4.ret, 0
			JE label2
			$7.code
			$5.code
			JMP label1
			label2:
			*/
			string label1=new_label();
			string label2=new_label();
			$$.code=all($3.code,

						label1,": ","\n",
						$4.code,
						"CMP ",$4.ret,", 0","\n",
						"JE ",label2,"\n",
						$7.code,"\n",
						$5.code,"\n",
						"JMP ",label1,"\n",
						label2,": ","\n"
						);
			$$.code=prepare_comment($$.word)+$$.code;
		
		}
		| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		{
			$$.word=$1.word+$2.word+$3.word+$4.word+$5.word;
			logout<<"Line "<<line_count<<": statement : IF LPAREN expression RPAREN statement"<<endl<<endl;
			logout<<$$.word<<endl<<endl;

			string label=new_label();
			/*
			$3.code
			CMP $3.ret, 0
			JE label
			$5.code
			label:
			*/
			$$.code=all($3.code,
						"CMP ",$3.ret,", 0","\n",
						"JE ",label,"\n",
						$5.code,"\n",
						label,":\n"
					);
		}
		| IF LPAREN expression RPAREN statement ELSE statement 
		{
			$$.word=$1.word+$2.word+$3.word+$4.word+$5.word+$6.word+$7.word;
			logout<<"Line "<<line_count<<": statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl<<endl;
			logout<<$$.word<<endl<<endl;

			string label1=new_label();
			string label2=new_label();
			/*
			$3.code
			CMP $3.ret, 0
			JE label2
			$5.code
			j label1
			label2:
			$7.code
			label1:
			*/
			$$.code=all($3.code,

						"CMP ",$3.ret,", 0","\n",
						"JE ",label2,"\n",
						$5.code,"\n",
						"JMP ",label1,"\n",
						label2,": ","\n",
						$7.code,"\n",
						label1,": ","\n"
					);

			$$.code=prepare_comment($$.word)+$$.code;
		
		}
		| WHILE LPAREN expression RPAREN statement 
		{
			$$.word=$1.word+$2.word+$3.word+$4.word+$5.word;
			logout<<"Line "<<line_count<<": statement : WHILE LPAREN expression RPAREN statement"<<endl<<endl;
			logout<<$$.word<<endl<<endl;

			/*
			label1:
			$3.code
			CMP $3.ret, 0
			JE label2
			$5.code
			JMP label1
			label2:
			*/
			string label1=new_label();
			string label2=new_label();
			$$.code=all(
					label1,":","\n",
					$3.code,"\n",
					"CMP ",$3.ret,", 0","\n",
					"JE ",label2,"\n",
					$5.code,"\n",
					"JMP ",label1,"\n",
					label2,":","\n"
			);
			$$.code=prepare_comment($$.word)+$$.code;
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON 
		{
			$$.word=$1.word+$2.word+$3.word+$4.word+$5.word;
			logout<<"Line "<<line_count<<": statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl<<endl;
			

			SymbolInfo * temp = table->fullLookup($3.word);
			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$3.word<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable"<<$3.word<<endl<<endl;
			}
			else if(temp->getClassType()!="variable")
			{
				error_count++;
				logout<<"Error at line no "<<line_count<<": "<<$3.word<<" cannot be printed"<<endl<<endl;
				errorout<<"Error at line no "<<line_count<<": "<<$3.word<<" cannot be printed"<<endl<<endl;
			}
			if(error_count==0){
				string id=temp->symbol;
				logout<<$$.word<<endl<<endl;
				$$.code=all($3.code,
						"PUSH ", id,"\n",
						"CALL PRINT","\n",
						"POP ", id,"\n");
				$$.code=prepare_comment($$.word)+$$.code;
			}
		}
		| RETURN expression SEMICOLON 
		{
			$$.word=$1.word+$2.word+$3.word;
			logout<<"Line "<<line_count<<": statement : RETURN expression SEMICOLON"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			
			if(inside_function=="main")
			{
				;
			}
			else
			{
				$$.code=all($2.code,
						"MOV BP, SP","\n",
						"MOV AX, ",$2.ret,"\n",
						"MOV WORD PTR[BP+14], AX","\n",
						"POP SI","\n",
						"POP BP","\n",
						"POP DX","\n",
						"POP CX","\n",
						"POP BX","\n",
						"POP AX","\n",
						"RET 0","\n");
			}
			tryToRemove($2.ret);
		}
		;
	  
expression_statement 	: SEMICOLON 
						{
							$$.word=$1.word;
							logout<<"Line "<<line_count<<": expression : SEMICOLON"<<endl<<endl;
							logout<<$$.word<<endl<<endl;
						}
						| expression SEMICOLON  
						{
							$$.word=$1.word+$2.word;
							logout<<"Line "<<line_count<<": expression_statement : expression SEMICOLON"<<endl<<endl;
							logout<<$$.word<<endl<<endl;

							$$.code=$1.code;
							$$.ret=$1.ret;
						}
						;
	  
variable : ID 
		{			
			$$.word=$1.word;

			logout<<"Line "<<line_count<<": variable : ID"<<endl<<endl;
			

			SymbolInfo * temp =table->fullLookup($1.word);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					$$.type="";
				}
				else if(temp->getClassType()!="array")
				{
					$$.type=temp->getSpecifier();
				}
				else
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.word<<" is an array"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.word<<" is an array"<<endl<<endl;
					$$.type="";
				}
			}
			logout<<$$.word<<endl<<endl;
			
			if(error_count==0){
				$$.ret=temp->symbol;
			}
		}
		| ID LTHIRD expression RTHIRD 
		{
			$$.word=$1.word+$2.word+$3.word+$4.word;
			logout<<"Line "<<line_count<<": variable : ID LTHIRD expression RTHIRD"<<endl<<endl;

			if($3.type!="int"&&$3.type.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				$$.type="";
			}

			SymbolInfo * temp =table->fullLookup($1.word);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					$$.type="";
				}
				if(temp->getClassType()!="array")
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" not an array"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" not an array"<<endl<<endl;

					$$.type="";
				}
				else
				{
					$$.type=temp->getSpecifier();
				}
			}
			
			logout<<$$.word<<endl<<endl;
			if(error_count==0){
				/*
				LEA SI, temp->symbol
				ADD SI, $3.ret
				ADD SI, $3.ret
				*/
				string temp_=new_temp();
				$$.code=all($3.code,
							"LEA SI, ",temp->symbol,"\n",
							"ADD SI, ",$3.ret,"\n",
							"ADD SI, ",$3.ret,"\n",
							"MOV AX",",[SI]","\n",
							"MOV ",temp_,", AX","\n"
							);
				$$.ret=temp_;

				tryToRemove($3.ret);
			}
		}
		;


expression : logic_expression 
		{
			$$.word=$1.word;
			$$.type=$1.type;

			logout<<"Line "<<line_count<<": expression : logic expression"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
			$$.code=$1.code;
			$$.ret=$1.ret;
		}
		| ID ASSIGNOP logic_expression 
		{
			$$.word=$1.word+$2.word+$3.word;
			$$.type=$3.type;
			logout<<"Line "<<line_count<<": expression : ID ASSIGNOP logic_expression"<<endl<<endl;	
			SymbolInfo * temp =table->fullLookup($1.word);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					$$.type="";
				}
				else if(temp->getClassType()!="array")
				{
					$$.type=temp->getSpecifier();
				}
				else
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.word<<" is an array"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.word<<" is an array"<<endl<<endl;
					$$.type="";
				}
			}	   	
			logout<<$$.word<<endl<<endl;
			
			
			temp =table->fullLookup($1.word);
			
			if(temp!=NULL){
				$$.code=$3.code+
						"MOV DX, "+$3.ret+"\n"+
						"MOV " + temp->symbol + ", DX\n";
				$$.ret=temp->symbol;
				tryToRemove($3.ret);
			}
		}
		| ID LTHIRD expression RTHIRD ASSIGNOP logic_expression
		{
			$$.word=$1.word+$2.word+$3.word+$4.word+$5.word+$6.word;
			$$.type=$6.type;
			logout<<"Line "<<line_count<<": expression : ID LTHIRD expression RTHIRD ASSIGNOP logic_expression"<<endl<<endl;
			if($3.type!="int"&&$3.type.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				$$.type="";
			}

			SymbolInfo * temp =table->fullLookup($1.word);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					$$.type="";
				}
				if(temp->getClassType()!="array")
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" not an array"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" not an array"<<endl<<endl;

					$$.type="";
				}
				else
				{
					$$.type=temp->getSpecifier();
				}
			}		   	
			logout<<$$.word<<endl<<endl;
			temp =table->fullLookup($1.word);
			
			if(temp!=NULL){
				$$.code=all($3.code,
							$6.code,
							"LEA SI, ",temp->symbol,"\n",
							"ADD SI, ",$3.ret,"\n",
							"ADD SI, ",$3.ret,"\n",
							"MOV CX, ",$6.ret,"\n",
							"MOV [SI], CX","\n"
							);
				$$.ret="[SI]";
				tryToRemove($3.ret);
				tryToRemove($6.ret);
			}
		}
	   ;
			
logic_expression : rel_expression 
			{
				$$.word=$1.word;
				$$.type=$1.type;

				logout<<"Line "<<line_count<<": logic_expression : rel_expression"<<endl<<endl;
				logout<<$$.word<<endl<<endl;

				$$.code=$1.code;
				$$.ret=$1.ret;
			}	
			| rel_expression LOGICOP rel_expression 
			{
				$$.word=$1.word+$2.word+$3.word;
				$$.type="int";

				logout<<"Line "<<line_count<<": logic_expression : rel_expression LOGICOP rel_expression"<<endl<<endl;

				if(($1.type=="void"||$3.type=="void")&&$1.type.size()>0&&$3.type.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					$$.type="";
				}
				else if(($1.type!="int"||$3.type!="int")&&$1.type.size()>0&&$3.type.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Wrong operand type for "<<$2.word<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": Wrong operand type for "<<$2.word<<endl<<endl;
					$$.type="";
				}
				if($1.type.size()==0||$3.type.size()==0) $$.type="";

				logout<<$$.word<<endl<<endl;

				if($2.word=="&&")
				{
					string label=new_label();
					string temp=new_temp();
					/*
						MOV temp, 0
						CMP $1.ret, 0
						JE label
						CMP $3.ret, 0
						JE label
						MOV temp, 1
						label:
					*/
					$$.code=all($1.code,$3.code,
								"MOV ",temp,", 0","\n",
								"CMP ",$1.ret,", 0", "\n",
								"JE ",label,"\n",
								"CMP ",$3.ret,", 0","\n",
								"JE ",label,"\n",
								"MOV ",temp,", 1","\n",
								label,":","\n");
					$$.ret=temp;
				}
				else if($2.word=="||")
				{
					string label=new_label();
					string temp=new_temp();
					/*
						MOV temp, 1
						CMP $1.ret, 0
						JNE label
						CMP $3.ret, 0
						JNE label
						MOV temp, 0
						label:
					*/
					$$.code=all($1.code,$3.code,
								"MOV ",temp,", 1","\n",
								"CMP ",$1.ret,", 0", "\n",
								"JNE ",label,"\n",
								"CMP ",$3.ret,", 0","\n",
								"JNE ",label,"\n",
								"MOV ",temp,", 0","\n",
								label,":","\n");
					$$.ret=temp;
				}
				tryToRemove($1.ret);
				tryToRemove($3.ret);
			} 	
			;
			
rel_expression	: simple_expression 
				{
					$$.word=$1.word;
					$$.type=$1.type;

					logout<<"Line "<<line_count<<": rel_expression : simple_expression"<<endl<<endl;
					logout<<$$.word<<endl<<endl;

					$$.code=$1.code;
					$$.ret=$1.ret;
				}
				| simple_expression RELOP simple_expression	
				{
					$$.word=$1.word+$2.word+$3.word;
					$$.type="int";

					if(($1.type=="void"||$3.type=="void")&&$1.type.size()>0&&$3.type.size()>0)
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
						$$.type="";
					}
					if($1.type.size()==0||$3.type.size()==0) $$.type="";

					logout<<"Line "<<line_count<<": rel_expression : simple_expression RELOP simple_expression"<<endl<<endl;
					logout<<$$.word<<endl<<endl;

					string label=new_label();
					string temp=new_temp();

					if($2.word==">")
					{
						/*
							MOV temp, 0
							MOV AX, $3.ret
							CMP $1.ret, AX
							JG label
							MOV temp, 1
							label:
						*/
						$$.code=all($1.code,$3.code,
									"MOV ",temp,",1","\n",
									"MOV AX",", ",$3.ret,"\n",
									"CMP ",$1.ret,", AX","\n",
									"JG ",label,"\n",
									"MOV ",temp,",0","\n",
									label,":","\n"
									);
						$$.ret=temp;
					}
					else if($2.word==">=")
					{
						/*
							MOV temp, 0
							MOV AX, $3.ret
							CMP $1.ret, AX
							JGE label
							MOV temp, 1
							label:
						*/
						$$.code=all($1.code,$3.code,
									"MOV ",temp,",1","\n",
									"MOV AX",", ",$3.ret,"\n",
									"CMP ",$1.ret,", AX","\n",
									"JGE ",label,"\n",
									"MOV ",temp,", 0","\n",
									label,":","\n"
									);
						$$.ret=temp;
					}
					else if($2.word=="<")
					{
						/*
							MOV temp, 0
							MOV AX, $3.ret
							CMP $1.ret, AX
							JL label
							MOV temp, 1
							label:
						*/
						$$.code=all($1.code,$3.code,
									"MOV ",temp,",1","\n",
									"MOV AX",", ",$3.ret,"\n",
									"CMP ",$1.ret,", AX","\n",
									"JL ",label,"\n",
									"MOV ",temp,",0","\n",
									label,":","\n"
									);
						$$.ret=temp;
					}
					else if($2.word=="<=")
					{
						/*
							MOV temp, 0
							MOV AX, $3.ret
							CMP $1.ret, AX
							JLE label
							MOV temp, 1
							label:
						*/
						$$.code=all($1.code,$3.code,
									"MOV ",temp,",1","\n",
									"MOV AX",", ",$3.ret,"\n",
									"CMP ",$1.ret,", AX","\n",
									"JLE ",label,"\n",
									"MOV ",temp,",0","\n",
									label,":","\n"
									);
						$$.ret=temp;
					}
					else if($2.word=="==")
					{
						/*
							MOV temp, 0
							MOV AX, $3.ret
							CMP $1.ret, AX
							JE label
							MOV temp, 1
							label:
						*/
						$$.code=all($1.code,$3.code,
									"MOV ",temp,",1","\n",
									"MOV AX",", ",$3.ret,"\n",
									"CMP ",$1.ret,", AX","\n",
									"JE ",label,"\n",
									"MOV ",temp,",0","\n",
									label,":","\n"
									);
						$$.ret=temp;
					}
					else if($2.word=="!=")
					{
						/*
							MOV temp, 0
							MOV AX, $3.ret
							CMP $1.ret, AX
							JNE label
							MOV temp, 1
							label:
						*/
						$$.code=all($1.code,$3.code,
									"MOV ",temp,",1","\n",
									"MOV AX",", ",$3.ret,"\n",
									"CMP ",$1.ret,", AX","\n",
									"JNE ",label,"\n",
									"MOV ",temp,",0","\n",
									label,":","\n"
									);
						$$.ret=temp;
					}
					tryToRemove($1.ret);
					tryToRemove($3.ret);
				}
				;
				
simple_expression : term 
			{
				$$.word=$1.word;
				$$.type=$1.type;

				logout<<"Line "<<line_count<<": simple_expression : term"<<endl<<endl;
				logout<<$$.word<<endl<<endl;

				$$.code=$1.code;
				$$.ret=$1.ret;
			}
			| simple_expression ADDOP term 
			{
				$$.word=$1.word+$2.word+$3.word;
				logout<<"Line "<<line_count<<": simple_expression : simple_expression ADDOP term"<<endl<<endl;

				if($1.type!="int"&&$1.type!="float"&&$3.type!="int"&&$3.type!="float"&&$1.type.size()>0&&$3.type.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Type mismatch for add/subtract"<<endl;
					errorout<<"Error at line "<<line_count<<": Type mismatch for add/subtract"<<endl;
					$$.type="";
				}
				else if($1.type=="float"||$3.type=="float") $$.type="float";
				else $$.type="int";

				if($1.type.size()==0||$3.type.size()==0) $$.type="";

				logout<<$$.word<<endl<<endl;

				if($2.word=="+")
				{
					/*
						MOV AX, 0
						MOV AX, $1.ret
						ADD AX, $3.ret
						MOV temp, AX
					*/
					string temp=new_temp();
					$$.code=all($1.code,
								$3.code,
							"MOV AX, ", $1.ret,"\n",
							"MOV ",temp,", AX","\n",
							"MOV AX, ",$3.ret,"\n",
							"ADD ",temp,", AX","\n");
					$$.ret=temp;
				}
				else
				{
					/*
						MOV AX, 0
						MOV AX, $1.ret
						SUB AX, $3.ret
						MOV temp, AX
					*/
					string temp=new_temp();
					$$.code=all($1.code,
								$3.code,
							"MOV AX, ", $1.ret,"\n",
							"MOV ",temp,", AX","\n",
							"MOV AX, ",$3.ret,"\n",
							"SUB ",temp,", AX","\n");
					$$.ret=temp;
				}
				tryToRemove($1.ret);
				tryToRemove($3.ret);
			}
			;
					
term :	unary_expression 
			{
				$$.word=$1.word;
				$$.type=$1.type;

				logout<<"Line "<<line_count<<": term : unary_expression"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
				
				$$.code=$1.code;
				$$.ret=$1.ret;
			}
			| term MULOP unary_expression 
			{
				$$.word=$1.word+$2.word+$3.word;
				logout<<"Line "<<line_count<<": term : term MULOP unary_expression"<<endl<<endl;

				if(($3.type=="void"||$1.type=="void")&&$1.type.size()>0&&$3.type.size()>0)
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
					$$.type="";
				}
				else if($2.word!="%"){
					if($1.type=="float"||$3.type=="float") $$.type="float";
					else $$.type="int";
				}
				else
				{
					if($1.type!="int"||$3.type!="int")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Non-Integer operand on modulus operator"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Non-Integer operand on modulus operator"<<endl<<endl;
						$$.type="";
					}
					else if($3.word=="0")
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Modulus by Zero"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Modulus by Zero"<<endl<<endl;
						$$.type="";
					}
				}
				if($1.type.size()==0||$3.type.size()==0) $$.type="";
				logout<<$$.word<<endl<<endl;

				if($2.word=="*"){
					/*
					MOV AX, $3.ret
					IMUL $1.ret
					MOV temp, AX
					*/
					string temp=new_temp();
					$$.code=all($1.code,$3.code,
								"MOV AX, ",$3.ret,"\n",
								"IMUL ",$1.ret,"\n",
								"MOV ",temp,", AX","\n");
					$$.ret=temp;
				}
				else if($2.word=="/")
				{
					/*
					MOV AX, $1.ret
					CWD
					IDIV $3.ret
					MOV temp, AX
					*/
					string temp=new_temp();
					$$.code=all($1.code,$3.code,
								"MOV AX, ",$1.ret,"\n",
								"CWD","\n",
								"IDIV ",$3.ret,"\n",
								"MOV ",temp,", AX","\n");
					$$.ret=temp;
				}
				else if($2.word=="%")
				{
					/*
					MOV AX, $1.ret
					CWD
					IDIV $3.ret
					MOV temp, DX
					*/
					string temp=new_temp();
					$$.code=all($1.code,$3.code,
								"MOV AX, ",$1.ret,"\n",
								"CWD","\n",
								"IDIV ",$3.ret,"\n",
								"MOV ",temp,", DX","\n");
					$$.ret=temp;
				}
				tryToRemove($1.ret);
				tryToRemove($3.ret);
			}
			;

unary_expression : ADDOP unary_expression 
				{
					$$.word=$1.word+$2.word;
					$$.type=$2.type;

					logout<<"Line "<<line_count<<": unary_expression : ADDOP unary_expression"<<endl<<endl;
					logout<<$$.word<<endl<<endl;

					string temp=new_temp();

					if($1.word=="+")
					{
						/*
						MOV AX, $2.ret
						MOV temp, AX
						*/
						$$.code=all($2.code,
									"MOV AX, ",$2.ret,"\n",
									"MOV ",temp,", AX","\n");
						$$.ret=temp;
					}
					else if($1.word=="-")
					{
						/*
						MOV AX, $2.ret
						MOV temp, AX
						NEG $2.ret
						*/
						$$.code=all($2.code,
									"MOV AX, ",$2.ret,"\n",
									"MOV ",temp,", AX","\n",
									"NEG ",temp,"\n");
						$$.ret=temp;
					}
					tryToRemove($2.ret);
				} 
				| NOT unary_expression 
				{
					$$.word=$1.word+$2.word;
					logout<<"Line "<<line_count<<": unary_expression : NOT unary_expression"<<endl<<endl;
					$$.type="int";

					if($2.type!="int"&&$2.type.size()>0)
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Invalid type for NOT operator"<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Invalid type for NOT operator"<<endl<<endl;
						$$.type="";
					}
					if($2.type.size()==0) $$.type="";
					
					logout<<$$.word<<endl<<endl;

					/*
						CMP $2.ret, 0
						MOV temp, 0
						JNE label
						MOV temp, 1
						label:
					*/


					string temp=new_temp(),label=new_label();
					$$.code=all($2.code,"\n",
								"CMP ",$2.ret,", 0","\n",
								"MOV ",temp, ", 0","\n",
								"JNE ", label,"\n",
								"MOV ",temp,", 1","\n",
								label,": ","\n"
								);
					$$.ret=temp;

					tryToRemove($2.ret);
				}
				| factor 
				{
					$$.word=$1.word;
					$$.type=$1.type;

					logout<<"Line "<<line_count<<": unary_expression : factor"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					
					$$.code=$1.code;
					$$.ret=$1.ret;
				}
				;
	

l_variable_incop_decop : ID 
		{			
			$$.word=$1.word;

			logout<<"Line "<<line_count<<": l_variable_incop_decop : ID"<<endl<<endl;

			SymbolInfo * temp =table->fullLookup($1.word);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					$$.type="";
				}
				else if(temp->getClassType()!="array")
				{
					$$.type=temp->getSpecifier();
				}
				else
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.word<<" is an array"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": Type mismatch, "<<$1.word<<" is an array"<<endl<<endl;
					$$.type="";
				}
			}
			logout<<$$.word<<endl<<endl;
			if(error_count==0){
				$$.ret=temp->symbol;
			}
		}
		| ID LTHIRD expression RTHIRD 
		{
			$$.word=$1.word+$2.word+$3.word+$4.word;
			logout<<"Line "<<line_count<<": l_variable_incop_decop : ID LTHIRD expression RTHIRD"<<endl<<endl;

			if($3.type!="int"&&$3.type.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
				$$.type="";
			}

			SymbolInfo * temp =table->fullLookup($1.word);

			if(!temp)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared variable "<<$1.word<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()=="function")
				{
					error_count++;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is a function"<<endl<<endl;
					$$.type="";
				}
				if(temp->getClassType()!="array")
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" not an array"<<endl<<endl;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" not an array"<<endl<<endl;

					$$.type="";
				}
				else
				{
					$$.type=temp->getSpecifier();
				}
			}
			
			logout<<$$.word<<endl<<endl;
			
			if(error_count==0){
				/*
				LEA SI, temp->symbol
				ADD SI, $3.ret
				ADD SI, $3.ret
				*/
				$$.code=all($3.code,
							"LEA SI, ",temp->symbol,"\n",
							"ADD SI, ",$3.ret,"\n",
							"ADD SI, ",$3.ret,"\n"
							);
				$$.ret="[SI]";
			}
		}
		;
factor	: variable 
		{
			$$.code=$1.code;
			$$.word=$1.word;
			$$.type=$1.type;
			$$.ret=$1.ret;

			logout<<"Line "<<line_count<<": factor : variable"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
		}
		| ID LPAREN argument_list RPAREN 
		{
			
			$$.word=$1.word+$2.word+$3.word+$4.word;
			logout<<"Line "<<line_count<<": factor : ID LPAREN argument_list RPAREN"<<endl<<endl;

			SymbolInfo * temp=table->fullLookup($1.word);
			if(temp==NULL)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": Undeclared function "<<$1.word<<endl;
				errorout<<"Error at line "<<line_count<<": Undeclared function "<<$1.word<<endl;
				$$.type="";
			}
			else
			{
				if(temp->getClassType()!="function")
				{
					error_count++;
					logout<<"Error at line "<<line_count<<": "<<$1.word<<" is not a function "<<endl;
					errorout<<"Error at line "<<line_count<<": "<<$1.word<<" is not a function "<<endl;
					$$.type=""; 
				}
				else
				{
					$$.type=temp->getReturnType();
					vector<string>parameter_list = temp->getParameterList();
					vector<string>another=taken_arguments.back();

					if(temp->isDefined()==false)
					{
						error_count++;
						logout<<"Error at line "<<line_count<<": Function not defined "<<endl<<endl;
						errorout<<"Error at line "<<line_count<<": Function not defined "<<endl<<endl;
						$$.type="";
					}
					else if(parameter_list!=another)
					{
						if(parameter_list.size()!=another.size())
						{
							error_count++;
							logout<<"Error at line "<<line_count<<": Total number of arguments mismatch in function "<<$1.word<<endl<<endl;
							errorout<<"Error at line "<<line_count<<": Total number of arguments mismatch in function "<<$1.word<<endl<<endl;
							
						}
						else
						{
							for(int i=0;i<parameter_list.size();i++)
							{
								if(parameter_list[i]!=another[i]&&another[i].size()>0&&!(parameter_list[i]=="float"&&another[i]=="int"))
								{
									error_count++;
									logout<<"Error at line "<<line_count<<": "<<(i+1)<<"th argument mismatch in function "<<$1.word<<endl<<endl;
									errorout<<"Error at line "<<line_count<<": "<<(i+1)<<"th argument mismatch in function "<<$1.word<<endl<<endl;
									break;
								}
							}
						}
					}
				}
			}
			taken_arguments.pop_back();

			
			logout<<$$.word<<endl<<endl;
			
			if(error_count==0)
			{
				$$.code+=$3.code;

				for(auto u:cur_saved_params)
				{
					$$.code+=all("PUSH ",u,"\n");
				}
				for(auto u:cur_saved_variables)
				{
					$$.code+=all("PUSH ",u,"\n");
				}
				for(auto u:cur_saved_args.back())
				{
					$$.code+=all("PUSH ",u,"\n");
				}
				if(temp->getReturnType()!="void"){
					$$.code+=all("PUSH 0\n"); //return value will be saved here
				}
				
				$$.code+=all("CALL ","function_"+$1.word,"\n");
				string temp_;
				
				if(temp->getReturnType()!="void"){
					temp_=new_temp();
					$$.code+=all("POP ",temp_,"\n");
					$$.ret=temp_;
				}
				
				int cnt=cur_saved_args.back().size();
				$$.code+=all("ADD SP, ",to_string(cnt*2),"\n");

				
				for(auto itr=cur_saved_variables.rbegin();itr!=cur_saved_variables.rend();itr++)
				{
					if(*itr!=temp_)
					{
						$$.code+=all("POP ",*itr,"\n");
					}
				}
				for(auto itr=cur_saved_params.rbegin();itr!=cur_saved_params.rend();itr++)
				{
					$$.code+=all("POP ",*itr,"\n");
				}
				cur_saved_args.pop_back();
			}
		
		}
		| LPAREN expression RPAREN 
		{
			$$.code=$2.code;
			$$.word=$1.word+$2.word+$3.word;
			$$.type=$2.type;
			$$.ret=$2.ret;

			logout<<"Line "<<line_count<<": factor : LPAREN expression RPAREN"<<endl<<endl;
			logout<<$$.word<<endl<<endl;
		}
		| CONST_INT 
		{
			$$.word=$1.word;
			$$.type="int";

			logout<<"Line "<<line_count<<": factor : CONST_INT"<<endl<<endl;
			logout<<$$.word<<endl<<endl;

			string temp=new_temp();
			$$.code=all("MOV ",temp,", ",$1.word,"\n");
			$$.ret=temp;
			
		}
		| CONST_FLOAT 
		{
			$$.word=$1.word;
			$$.type="float";

			logout<<"Line "<<line_count<<": factor : CONST_FLOAT"<<endl<<endl;
			logout<<$$.word<<endl<<endl;

			$$.code="";
			$$.ret=$1.word;
		}
		| l_variable_incop_decop INCOP 
		{
			$$.word=$1.word+$2.word;
			logout<<"Line "<<line_count<<": factor : variable INCOP"<<endl<<endl;
			$$.type="int";

			if($1.type!="int"&&$1.type.size()>0)
			{
				error_count++;
				logout<<"Error at line "<<line_count<<": "<<$2.word<<": should be used with integer variable"<<endl<<endl;
				errorout<<"Error at line "<<line_count<<": "<<$2.word<<": should be used with integer variable"<<endl<<endl;
				$$.type="";
			}
			if($1.type.size()==0) $$.type="";
			logout<<$$.word<<endl<<endl;

			string temp=new_temp();

			$$.code=all($1.code,
						"MOV AX, ",$1.ret,"\n",
						"MOV ",temp,", AX","\n",
						"ADD ",$1.ret,", 1\n");
			$$.ret=temp;
		}
		| l_variable_incop_decop DECOP
		{
			$$.word=$1.word+$2.word;
			logout<<"Line "<<line_count<<": factor : variable DECOP"<<endl<<endl;
			$$.type="int";

			if($1.type!="int"&&$1.type.size()>0)
			{
				error_count++;
				logout<<"Error at line: "<<line_count<<" "<<$2.word<<" should be used with integer variable"<<endl<<endl;
				errorout<<"Error at line: "<<line_count<<" "<<$2.word<<" should be used with integer variable"<<endl<<endl;
				$$.type="";
			}
			if($1.type.size()==0) $$.type="";
			logout<<$$.word<<endl<<endl;

			string temp=new_temp();

			$$.code=all($1.code,
						"MOV AX, ",$1.ret,"\n",
						"MOV ",temp,", AX","\n",
						"SUB ",$1.ret,", 1\n");
			$$.ret=temp;
		}
		;
	
argument_list : arguments 
				{
					$$.word=$1.word;
					logout<<"Line "<<line_count<<": argument_list : arguments"<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					$$.code=$1.code;
					$$.ret=$1.ret;
				}
				| 
				{
					$$.word="";
					logout<<"Line "<<line_count<<": argument_list : "<<endl<<endl;
					logout<<$$.word<<endl<<endl;
					taken_arguments.emplace_back();
					cur_saved_args.emplace_back();
				}
				;
	
arguments : arguments COMMA logic_expression 
			{
				$$.word=$1.word+$2.word+$3.word;
				logout<<"Line "<<line_count<<": arguments : arguments COMMA logic_expression"<<endl<<endl;
				logout<<$$.word<<endl<<endl;

				taken_arguments.back().push_back($3.type);
				cur_saved_args.back().push_back($3.ret);
				$$.code=all($1.code,$3.code);
			}
			| logic_expression 
			{
				$$.word=$1.word;
				logout<<"Line "<<line_count<<": arguments : logic_expression"<<endl<<endl;
				logout<<$$.word<<endl<<endl;

				taken_arguments.emplace_back();
				taken_arguments.back().push_back($1.type);

				cur_saved_args.emplace_back();
				cur_saved_args.back().push_back($1.ret);
				$$.code=$1.code;
			}
			| error
			{
				$$={{"",""},{"",""}};
				logout<<"Line "<<line_count<<": arguments : error"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
			}
			| arguments error
			{
				$$.word=$1.word;
				logout<<"Line "<<line_count<<": arguments : arguments error"<<endl<<endl;
				logout<<$$.word<<endl<<endl;
				$$.code=$1.code;
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
	asmout.open("code.asm");
	optimized_asmout.open("optimized_code.asm");

	yyin=fp;
	yyparse();

	table->printAll();
	logout<<"Total lines : "<<line_count<<endl;
	logout<<"Total errors : "<<error_count<<endl;
	

	logout.close();
	errorout.close();
	asmout.close();
	optimized_asmout.close();

	return 0;
}

