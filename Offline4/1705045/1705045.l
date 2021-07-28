%x MULT_CMNT
%x MULT_CMNT2
%{
#include<bits/stdc++.h>
#include "SymbolTable.cpp"
#define YYSTYPE pair<pair<string,string>,pair<string,string>>
#include "y.tab.h"
#define word first.first
#define type first.second
#define code second.first
#define ret second.second


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

	yylval.word = yytext;
	return CONST_FLOAT; 
}
{digit}*("."{digit}*)?(E|e)({digit}|(E|e)|".")*"."({digit}|(E|e)|".")* {
	error_count++;
	string temp="Ill formed number ";
	temp+=string(yytext);
	logout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;

	yylval.word = yytext;
	return CONST_FLOAT; 
}
{digit}+[a-zA-Z_][a-zA-Z0-9_]* {
	error_count++;
	string temp="Invalid prefix on ID or invalid suffix on Number ";
	temp+=string(yytext);
	logout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;
	errorout<<"Error at line "<<line_count<<": "<<temp<<endl<<endl;

	yylval.word = yytext;
	return ID; 
}

{delim}+	{}


"if" {
	yylval.word=yytext;
	return IF;
}
"else" {yylval.word=yytext;yylval.word+="\n";return ELSE;}
"for" {yylval.word=yytext;return FOR;}
"while" {yylval.word=yytext;return WHILE;}
"int" {
	yylval.word=yytext;return INT;
	}
"float" {yylval.word=yytext;return FLOAT;}
"double" {yylval.word=yytext;return DOUBLE;}
"char" {yylval.word=yytext;return CHAR;}
"return" {yylval.word=yytext;yylval.word+=" ";return RETURN;}
"void" {yylval.word=yytext;return VOID;}
"println"	{yylval.word=yytext;return PRINTLN;}
"printf"	{yylval.word=yytext;return PRINTLN;}




{ADDOP} { 
			info= new  SymbolInfo(yytext, (char *)"ADDOP");
			yylval.word=yytext;
			return ADDOP;
		}



{MULOP}	{
			info= new  SymbolInfo(yytext, (char *)"MULOP");
			yylval.word=yytext;
			return MULOP;
		}


"=" 	{yylval.word=yytext;return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		info= new  SymbolInfo(yytext, (char *)"RELOP");
		yylval.word=yytext;
		return RELOP;
	}

"&&"	|
"||"	{
			info= new  SymbolInfo(yytext, (char *)"LOGICOP");
			yylval.word=yytext;
			return LOGICOP;
		}
"!"		{yylval.word=yytext;	return NOT; }


";" 	{yylval.word=yytext; return SEMICOLON;}
"," 	{yylval.word=yytext;return COMMA;}
"(" 	{yylval.word=yytext;return LPAREN;}
")" 	{yylval.word=yytext;return RPAREN;}
"{" 	{
			//logout<<"HERE"<<endl<<endl;
			table->EnterScope();
			yylval.word=yytext;return LCURL;
		}
"}" 	{
			//logout<<"THERE"<<endl<<endl;
			yylval.word="\n";yylval.word+=yytext;yylval.word+="\n";return RCURL;
		}
"[" 	{yylval.word=yytext;return LTHIRD;}
"]" 	{yylval.word=yytext;return RTHIRD;}
"++" 	{yylval.word=yytext;return INCOP;}
"--" 	{yylval.word=yytext;return DECOP;}



{integer}	{
				info= new  SymbolInfo(yytext, (char *)"CONST_INT");
				yylval.word = yytext;
				return CONST_INT;
			}
{number} 	{	
				
				info= new  SymbolInfo(yytext, (char *)"CONST_FLOAT");
				yylval.word = yytext;
				return CONST_FLOAT; 
			}
 
{id} 		{
				info= table->Lookup(yytext);
				if(info==NULL)
				{					
					info= new SymbolInfo(yytext, (char *)"ID");
				}
				yylval.word=yytext;
							
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






