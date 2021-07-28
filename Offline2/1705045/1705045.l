%option noyywrap
%x TAKE_CHAR
%x TAKE_STRING
%x MULT_CMNT
%x MULT_CMNT2
%{
#include<bits/stdc++.h>
using namespace std;

int line_count=1;
int temp=0;
int error_count=0;

string s1,s2,saved_string;

ofstream logout;
ofstream tokenout;

#include "SymbolTable.cpp"
SymbolTable table(7);

string strupr(string s)
{
	string temp;
	for(auto u:s)
	{
		if(u>='a'&&u<='z') u=u-'a'+'A';
		temp+=u;
	}
	return temp;
}

void error_to_log(int line_count, string s)
{	
	error_count++;
	logout<<"\nError at line no "<<line_count<<": "<<s<<'\n';
	return;
}

void new_token(int line_count, string a, string c)
{
	if(a=="CONST_CHAR")
	{
		logout<<"\nLine no "<<line_count<<": Token <"<<a<<"> Lexeme "<<c<<" found";
		logout<<" --> "<<"<CHAR_CONST, "<<s2<<"> \n";
		return;	
	}
	else if(a=="STRING")
	{
		logout<<"\nLine no "<<line_count<<": Token <"<<a<<"> Lexeme "<<c<<" found";
		logout<<" --> "<<"<STRING, \""<<s2<<"\"> \n";
		return;
	}
	logout<<"\nLine no "<<line_count<<": Token <"<<a<<"> Lexeme "<<c<<" found\n";
}

void add_token(string a,string b)
{
	tokenout<<"<"<<a<<", "<<b<<"> ";
}
void add_token(string a)
{
	tokenout<<"<"<<a<<"> ";
}

%}

Letter [a-zA-Z]
Digit [0-9]
all [^\r\n]
newline \r\n|\n


%%

{Digit}*"."{Digit}*"."({Digit}|".")* {
	error_to_log(line_count,"Too many decimal points "+string(yytext));
}
{Digit}*("."{Digit}*)?E({Digit}|E|".")*"."({Digit}|E|".")* {
	error_to_log(line_count,"Ill formed number "+string(yytext));
}

{Digit}*"."?{Digit}+E-?{Digit}+ {
	new_token(line_count,"CONST_FLOAT",yytext);
	table.Insert(new SymbolInfo(yytext,"CONST_FLOAT"));
	add_token("CONST_FLOAT",yytext);
}

{Digit}+[a-zA-Z_][a-zA-Z0-9_]* {
	error_to_log(line_count,"Invalid prefix on ID or invalid suffix on Number "+string(yytext));
}
if|for|do|int|float|void|switch|default|else|while|break|char|double|return|case|continue {
	new_token(line_count,strupr(yytext),yytext);
	add_token(strupr(yytext));
}

{Digit}+ {
	new_token(line_count,"CONST_INT",yytext);
	table.Insert(new SymbolInfo(yytext,"CONST_INT"));
	add_token("CONST_INT",yytext);
}

{Digit}*"."{Digit}+ {
	new_token(line_count,"CONST_FLOAT",yytext);
	table.Insert(new SymbolInfo(yytext,"CONST_FLOAT"));
	add_token("CONST_FLOAT",yytext);
}

\' {
	s1.clear();
	s2.clear();
	s1+=yytext;
	BEGIN TAKE_CHAR;
}
<TAKE_CHAR>\\n {
	s1+=yytext;
	s2+='\n';
}
<TAKE_CHAR>\\t {
	s1+=yytext;
	s2+='\t';
}
<TAKE_CHAR>\\\\ {
	s1+=yytext;
	s2+='\\';
}
<TAKE_CHAR>\\\' {
	s1+=yytext;
	s2+='\'';
}
<TAKE_CHAR>\\a {
	s1+=yytext;
	s2+='\a';
}
<TAKE_CHAR>\\f {
	s1+=yytext;
	s2+='\f';
}
<TAKE_CHAR>\\r {
	s1+=yytext;
	s2+='\r';
}
<TAKE_CHAR>\\b {
	s1+=yytext;
	s2+='\b';
}
<TAKE_CHAR>\\v {
	s1+=yytext;
	s2+='\v';
}
<TAKE_CHAR>\\0 {
	s1+=yytext;
	s2+='\0';
}


<TAKE_CHAR>\' {
	s1+=yytext;
	if(s2.size()==1)
	{
		new_token(line_count,"CONST_CHAR",s1);
		table.Insert(new SymbolInfo(s1,"CONST_CHAR"));
		add_token("CHAR_CONST",s2);
	}
	else if(s2.size()==0)
	{
		error_to_log(line_count,"Empty character constant error \'\'");
	}
	else if(s2.size()>1)
	{
		error_to_log(line_count,"Multi character constant error \'"+s2+"\'\n");
	}
	s1.clear();
	s2.clear();
	BEGIN INITIAL;
}
<TAKE_CHAR>{all} {
	s1+=yytext;
	s2+=yytext;
}
<TAKE_CHAR>{newline} {
	error_to_log(line_count,"Unterminated character "+s1);
	line_count++;
	s1.clear();
	s2.clear();
	BEGIN INITIAL;
}

<TAKE_CHAR><<EOF>> {
	error_to_log(line_count,"Unterminated character "+s1);
	table.printAll(); 
	logout<<"\nTotal lines: "<<line_count<<'\n';
	logout<<"Total errors: "<<error_count<<'\n';
	return 0;
}


"+"|"-" {
	new_token(line_count,"ADDOP",yytext);
	add_token("ADDOP",yytext);
}
"*"|"/"|"%" {
	new_token(line_count,"MULOP",yytext);
	add_token("MULOP",yytext);
}
"++"|"--" {
	new_token(line_count,"INCOP",yytext);
	add_token("INCOP",yytext);
}
"<"|"<="|">"|">="|"=="|"!=" {
	new_token(line_count,"RELOP",yytext);
	add_token("RELOP",yytext);
}
"=" {
	new_token(line_count,"ASSIGNOP",yytext);
	add_token("ASSIGNOP",yytext);
}
"&&"|"||" {
	new_token(line_count,"LOGICOP",yytext);
	add_token("LOGICOP",yytext);
}
"!" {
	new_token(line_count,"NOT",yytext);
	add_token("NOT",yytext);
}
"(" {
	new_token(line_count,"LPAREN",yytext);
	add_token("LPAREN",yytext);
}
")" {
	new_token(line_count,"RPAREN",yytext);
	add_token("RPAREN",yytext);
}
"{" {
	new_token(line_count,"LCURL",yytext);
	table.EnterScope();
	add_token("LCURL",yytext);
}
"}" {
	new_token(line_count,"RCURL",yytext);
	table.ExitScope();
	add_token("RCURL",yytext);
}
"[" {
	new_token(line_count,"LTHIRD",yytext);
	add_token("LTHIRD",yytext);
}
"]" {
	new_token(line_count,"RTHIRD",yytext);
	add_token("RTHIRD",yytext);
}
"," {
	new_token(line_count,"COMMA",yytext);
	add_token("COMMA",yytext);
}
";" {
	new_token(line_count,"SEMICOLON",yytext);
	add_token("SEMICOLON",yytext);
}
[a-zA-Z_][a-zA-Z0-9_]* {
	new_token(line_count,"ID",yytext);
	table.Insert(new SymbolInfo(yytext,"ID"));
	add_token("ID",yytext);
}

\"\\\" {
	error_to_log(line_count,"Unterminated String "+string(yytext));
}

\" {
	s1.clear();
	s2.clear();
	s1+=yytext;
	temp=line_count;
	BEGIN TAKE_STRING;
}

<TAKE_STRING>\\n {
	s1+=yytext;
	s2+='\n';
}
<TAKE_STRING>\\t {
	s1+=yytext;
	s2+='\t';
}
<TAKE_STRING>\\\\ {
	s1+=yytext;
	s2+='\\';
}
<TAKE_STRING>\\\' {
	s1+=yytext;
	s2+='\'';
}
<TAKE_STRING>\\a {
	s1+=yytext;
	s2+='\a';
}
<TAKE_STRING>\\f {
	s1+=yytext;
	s2+='\f';
}
<TAKE_STRING>\\r {
	s1+=yytext;
	s2+='\r';
}
<TAKE_STRING>\\b {
	s1+=yytext;
	s2+='\b';
}
<TAKE_STRING>\\v {
	s1+=yytext;
	s2+='\v';
}
<TAKE_STRING>\\0 {
	s1+=yytext;
	s2+='\0';
}
<TAKE_STRING>\\{newline} {
	line_count++;
	s1+=yytext;
}
<TAKE_STRING>"\\\"" {
	s1+=yytext;
	s2+='\"';
}
<TAKE_STRING>\" {
	s1+=yytext;
	
	new_token(temp,"STRING",s1);
	add_token("STRING","\""+s2+"\"");
	
	s1.clear();
	s2.clear();
	
	BEGIN INITIAL;
}
<TAKE_STRING>{all} {
	s1+=yytext;
	s2+=yytext;
}
<TAKE_STRING>{newline} {
	error_to_log(temp,"Unterminated String "+s1);
	line_count++;
	s1.clear();
	s2.clear();
	BEGIN INITIAL;
}
<TAKE_STRING><<EOF>> {
	error_to_log(temp,"Unterminated String "+s1);
	table.printAll(); 
	logout<<"\nTotal lines: "<<line_count<<'\n';
	logout<<"Total errors: "<<error_count<<'\n';
	return 0;
}


"//"{all}*\\{newline} {
	temp=line_count;
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
	new_token(temp,"COMMENT",saved_string);
	BEGIN INITIAL;
}
<MULT_CMNT2><<EOF>> {
	new_token(temp,"COMMENT",saved_string);
	table.printAll(); 
	logout<<"\nTotal lines: "<<line_count<<'\n';
	logout<<"Total errors: "<<error_count<<'\n';
	return 0;
}



"//"{all}* {
	new_token(line_count,"COMMENT",yytext);
}


"/*" {
	temp=line_count;
	saved_string.clear();
	saved_string+=yytext;
	BEGIN MULT_CMNT;
}
<MULT_CMNT>"*/" {
	saved_string+=yytext;
	new_token(temp,"COMMENT",saved_string);
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
	error_to_log(temp,"Unterminated Comment "+saved_string);
	table.printAll(); 
	logout<<"\nTotal lines: "<<line_count<<'\n';
	logout<<"Total errors: "<<error_count<<'\n';
	return 0;
}


		

[ \t\v]+ {}
{newline} {line_count++;}



<<EOF>> {
table.printAll(); 
logout<<"\nTotal lines: "<<line_count<<'\n';
logout<<"Total errors: "<<error_count<<'\n';
return 0;
}
. { error_to_log(line_count,"Unrecognized character "+string(yytext)); }
%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	logout.open("1705045_log.txt");
	tokenout.open("1705045_token.txt");

	yyin= fin;
	yylineno=1;
	yylex();
	fclose(yyin);
	logout.close();
	tokenout.close();
	return 0;
}
