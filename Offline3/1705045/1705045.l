%x MULT_CMNT
%x MULT_CMNT2
%{
#include<bits/stdc++.h>
#include "SymbolTable.cpp"
#define YYSTYPE pair<string,string>
#include "y.tab.h"


using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *table;
extern SymbolInfo *info;
extern string a,b;
extern vector<pair<string,string>>declared_params;
extern bool flag;
string saved_string;

void yyerror(char *);
int line_count=1;
int error_count=0;

extern ofstream logout,errorout;

%}



digit [0-9]
letter [A-Za-z]
delim [ \t\r\f\v]
newline \n|\r\n
ws [delim]+
id (_|{letter})(_|{letter}|{digit})*
integer {digit}+
number {digit}*(\.{digit}+)?(E[+-]?{digit}+)?
ADDOP [+-] 
MULOP [*/%]
all [^\r\n]

%%

{digit}*"."{digit}*"."({digit}|".")* {
	error_count++;
	string temp="Too many decimal points ";
	temp+=string(yytext);
	logout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;

	yylval.first = yytext;
	return CONST_FLOAT; 
}
{digit}*("."{digit}*)?(E|e)({digit}|(E|e)|".")*"."({digit}|(E|e)|".")* {
	error_count++;
	string temp="Ill formed number ";
	temp+=string(yytext);
	logout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;

	yylval.first = yytext;
	return CONST_FLOAT; 
}
{digit}+[a-zA-Z_][a-zA-Z0-9_]* {
	error_count++;
	string temp="Invalid prefix on ID or invalid suffix on Number ";
	temp+=string(yytext);
	logout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;

	yylval.first = yytext;
	return ID; 
}

{delim}+	{}


"if" {
	yylval.first=yytext;
	return IF;
}
"else" {yylval.first=yytext;yylval.first+="\n";return ELSE;}
"for" {yylval.first=yytext;return FOR;}
"while" {yylval.first=yytext;return WHILE;}
"int" {
	yylval.first=yytext;return INT;
	}
"float" {yylval.first=yytext;return FLOAT;}
"double" {yylval.first=yytext;return DOUBLE;}
"char" {yylval.first=yytext;return CHAR;}
"return" {yylval.first=yytext;yylval.first+=" ";return RETURN;}
"void" {yylval.first=yytext;return VOID;}
"println"	{yylval.first=yytext;return PRINTLN;}
"printf"	{yylval.first=yytext;return PRINTLN;}




{ADDOP} { 
			info= new  SymbolInfo(yytext, (char *)"ADDOP");
			yylval.first=yytext;
			return ADDOP;
		}



{MULOP}	{
			info= new  SymbolInfo(yytext, (char *)"MULOP");
			yylval.first=yytext;
			return MULOP;
		}


"=" 	{yylval.first=yytext;return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		info= new  SymbolInfo(yytext, (char *)"RELOP");
		yylval.first=yytext;
		return RELOP;
	}

"&&"	|
"||"	{
			info= new  SymbolInfo(yytext, (char *)"LOGICOP");
			yylval.first=yytext;
			return LOGICOP;
		}
"!"		{yylval.first=yytext;	return NOT; }


";" 	{yylval.first=yytext; return SEMICOLON;}
"," 	{yylval.first=yytext;return COMMA;}
"(" 	{yylval.first=yytext;return LPAREN;}
")" 	{yylval.first=yytext;return RPAREN;}
"{" 	{
			//logout<<"HERE"<<endl<<endl;
			table->EnterScope();
			yylval.first=yytext;return LCURL;
		}
"}" 	{
			//logout<<"THERE"<<endl<<endl;
			yylval.first="\n";yylval.first+=yytext;yylval.first+="\n";return RCURL;
		}
"[" 	{yylval.first=yytext;return LTHIRD;}
"]" 	{yylval.first=yytext;return RTHIRD;}
"++" 	{yylval.first=yytext;return INCOP;}
"--" 	{yylval.first=yytext;return DECOP;}



{integer}	{
				info= new  SymbolInfo(yytext, (char *)"CONST_INT");
				yylval.first = yytext;
				return CONST_INT;
			}
{number} 	{	
				
				info= new  SymbolInfo(yytext, (char *)"CONST_FLOAT");
				yylval.first = yytext;
				return CONST_FLOAT; 
			}
 
{id} 		{
				info= table->Lookup(yytext);
				if(info==NULL)
				{					
					info= new SymbolInfo(yytext, (char *)"ID");
				}
				yylval.first=yytext;
							
				return ID;
			}
"//"{all}*\\{newline} {
	line_count++;
	saved_string.clear();
	saved_string+=yytext;
	BEGIN MULT_CMNT2;
}
<MULT_CMNT2>{all}*\\{newline} {
	line_count++;
	saved_string+=yytext;
}
<MULT_CMNT2>{all}* {
	saved_string+=yytext;
	BEGIN INITIAL;
}
<MULT_CMNT2><<EOF>> {}



"//"{all}* {}


"/*" {
	saved_string.clear();
	saved_string+=yytext;
	BEGIN MULT_CMNT;
}
<MULT_CMNT>"*/" {
	saved_string+=yytext;
	saved_string.clear();
	BEGIN INITIAL;
}
<MULT_CMNT>{all} {
	saved_string+=yytext;
}


<MULT_CMNT>{newline} {
	line_count++;
	saved_string+=yytext;
}
<MULT_CMNT><<EOF>> {
	
}
{newline} {line_count++;}
. 	{
		error_count++;
		logout<<"Error at line "<<line_count<<": Unrecognized character "<<yytext<<endl;
		errorout<<"Error at line "<<line_count<<": Unrecognized character "<<yytext<<endl;
	}

%%

int yywrap(void)
{
	return 1;
}






