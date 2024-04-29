%option noyywrap

%x CHECK_INDENTATION
%x CHARACTERS
%x STRINGS
%x SINGLE_LINE_COMMENTS
%x MULTI_LINE_COMMENTS

%{
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<fstream>
#include "2005067.h"
using namespace std;


ofstream tokenFile;
ofstream logFile;

Symbol_Table symbol_table(10,logFile);


int line_count=1;
int total_error = 0;
int total_warning = 0;
int required_tab_count = 0;
int got_tab_count = 0;
int track_line_count = 1;


string string_token = "";
string string_log = "";
string string_variant = "";

string char_token_and_log = "";
string char_error_log = "";


string comment_log = "";

bool read_empty_char = false;
bool space_encounterd = false;



string convert_to_upper_case(string str)
{
	for(int i=0;i<str.length();i++)
	{
		if(str[i]>='a' && str[i]<='z')
		{
			str[i]=str[i]-32;
		}
	}
	return str;
}

void print_token_in_file(string token_name,string token_lexeme)
{
	tokenFile<<"<"<<token_name<<", "<<token_lexeme<<">"<<endl;
}

void print_log_in_file(string token_name,string token_lexeme)
{
	logFile<<"Line# "<<line_count<<": Token <"<<token_name<<"> Lexeme "<<token_lexeme<<" found"<<endl;
}

void print_error_msg(string error_type, string error_lexeme, int line_no = line_count)
{
	logFile<<"Error at line# "<<line_no<<": "<<error_type<<" "<<error_lexeme<<endl;
	total_error++;
}

void print_warning_msg(int req_tab_count,int got_tab_count, int line_no = line_count)
{
	if(got_tab_count > req_tab_count || got_tab_count < req_tab_count){
		logFile<<"Line# "<<line_no<<": warning, "<<req_tab_count<<" of tabs needed but got "<<got_tab_count<<" tabs."<<endl;
		total_warning++;
	}
	if(space_encounterd){
		logFile<<"Line# "<<line_no<<": Warning, tab requrired but got space."<<endl;
		total_warning++;
	}
	
}



%}

DIGIT [0-9]
LETTER [a-zA-Z]
ALPHANUMERIC [a-zA-Z0-9_]
KEYWORDS ("if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue")	
ID [a-zA-Z_]{ALPHANUMERIC}*
INTEGER {DIGIT}+
FLOAT {DIGIT}*(\.{DIGIT}+)?([E][+-]?{DIGIT}+)?
TOO_MANY_DECIMAL_POINTS [0-9]*[\.]+[0-9]+[\.][\.0-9]*([Ee][+-]?[0-9]+)?
ILLFORMED_NUMBER ([0-9]+[\.][Ee][+-]?[0-9]+)|([0-9]*(\.[0-9]+)?[Ee][\.][+-]?[0-9]+)|([0-9]*(\.[0-9]+)?[Ee][+-]?[\.][0-9]+)|([0-9]*(\.[0-9]+)?[Ee][+-]?[0-9]+[\.][0-9]+)
INVALID_ID_SUFFIX_NUM_PREFIX [0-9]{ALPHANUMERIC}+
RELOP ("<"|"<="|">"|">="|"=="|"!=")
BITOP ("&"|"|"|"^"|"<<"|">>")
LOGICOP ("&&"|"||")
INCOP ("++"|"--")
ADDOP("+"|"-")
MULOP("*"|"/"|"%")
WHITESPACE [ \t\r\v\f]+
NEWLINE (\r)?\n

%%

<CHECK_INDENTATION>[ ]*[\t]*{NEWLINE} {
	line_count++;
	got_tab_count = 0;
	space_encounterd = false;
}

<CHECK_INDENTATION>[ ] {
	space_encounterd = true;
}

<CHECK_INDENTATION>\t {
	got_tab_count++;
}

<CHECK_INDENTATION><<EOF>> {
	print_warning_msg(required_tab_count,got_tab_count);
	BEGIN INITIAL;
}

<CHECK_INDENTATION>. {
	if(strcmp(yytext,"}") == 0)
	{
		required_tab_count--;
		print_warning_msg(required_tab_count,got_tab_count);
		required_tab_count++;
	}
	else
	{
		print_warning_msg(required_tab_count,got_tab_count);
	}
	unput(yytext[0]);
	space_encounterd = false;
	got_tab_count = 0;
	BEGIN INITIAL;
}

{NEWLINE} {
	line_count++;
	BEGIN CHECK_INDENTATION;
}

{WHITESPACE} {/*do nothing*/}




{KEYWORDS} {
	tokenFile<<"<"<<convert_to_upper_case(yytext)<<", "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <"<<convert_to_upper_case(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
}


{ADDOP} {
	tokenFile<<"<ADDOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <ADDOP> Lexeme "<<yytext<<" found"<<endl;
	}

{MULOP} {
	tokenFile<<"<MULOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <MULOP> Lexeme "<<yytext<<" found"<<endl;
	}

{INCOP} {
	tokenFile<<"<INCOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <INCOP> Lexeme "<<yytext<<" found"<<endl;
	}

{RELOP} {
	tokenFile<<"<RELOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <RELOP> Lexeme "<<yytext<<" found"<<endl;
	}

"=" {
	tokenFile<<"<ASSIGNOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found"<<endl;
	}

{LOGICOP} {
	tokenFile<<"<LOGICOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <LOGICOP> Lexeme "<<yytext<<" found"<<endl;
	}

{BITOP} {
	tokenFile<<"<BITOP, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <BITOP> Lexeme "<<yytext<<" found"<<endl;
	}

"!" {
	tokenFile<<"<NOT, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <NOT> Lexeme "<<yytext<<" found"<<endl;
	}

"(" {
	tokenFile<<"<LPAREN, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <LPAREN> Lexeme "<<yytext<<" found"<<endl;
	}

")" {
	tokenFile<<"<RPAREN, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <RPAREN> Lexeme "<<yytext<<" found"<<endl;
	}

"{" {
	symbol_table.enter_scope(logFile);
	required_tab_count++;
	tokenFile<<"<LCURL, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <LCURL> Lexeme "<<yytext<<" found"<<endl;
	}

"}" {
	symbol_table.exit_scope();
	required_tab_count--;
	tokenFile<<"<RCURL, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <RCURL> Lexeme "<<yytext<<" found"<<endl;
	}

"[" {
	tokenFile<<"<LSQUARE, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <LSQUARE> Lexeme "<<yytext<<" found"<<endl;
	}

"]" {
	tokenFile<<"<RSQUARE, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <RSQUARE> Lexeme "<<yytext<<" found"<<endl;
	}

"," {
	tokenFile<<"<COMMA, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <COMMA> Lexeme "<<yytext<<" found"<<endl;
	}

";" {
	tokenFile<<"<SEMICOLON, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found"<<endl;
	}


{ID} {
	
	if(symbol_table.get_current_scope()->insert(yytext,"ID") == true)
	{
		tokenFile<<"<ID, "<<yytext<<">"<<endl;
		logFile<<"Line# "<<line_count<<": Token <ID> Lexeme "<<yytext<<" found"<<endl;
		symbol_table.print_all_scope_in_file();
	}
	else
	{
		tokenFile<<"<ID, "<<yytext<<">"<<endl;
		logFile<<"Line# "<<line_count<<": Token <ID> Lexeme "<<yytext<<" found"<<endl;
		logFile<<"\t"<<yytext<<" already exists in the current ScopeTable"<<endl;
	}
}




{INTEGER} {
	tokenFile<<"<CONST_INT, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <CONST_INT> Lexeme "<<yytext<<" found"<<endl;
	}

{FLOAT} {
	tokenFile<<"<CONST_FLOAT, "<<yytext<<">"<<endl;
	logFile<<"Line# "<<line_count<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found"<<endl;
	}

{INVALID_ID_SUFFIX_NUM_PREFIX} {
	print_error_msg("INVALID_ID_SUFFIX_NUM_PREFIX",yytext);
	}

{TOO_MANY_DECIMAL_POINTS} {
	print_error_msg("TOO_MANY_DECIMAL_POINTS",yytext);
	}

{ILLFORMED_NUMBER} {
	print_error_msg("ILLFORMED_NUMBER",yytext);
	}

\' {
	BEGIN CHARACTERS;
	char_token_and_log = "";
	char_error_log = "\'";
	read_empty_char = false;
}


<CHARACTERS>{NEWLINE} {
	if(char_token_and_log.length() > 1)
	{
		for(int i = char_error_log.length()-1; i>1; i--)
		{
			unput(char_error_log[i]);
		}
		char_error_log = char_error_log.substr(0,2);
	}
	print_error_msg("UNFINISHED_CONST_CHAR",char_error_log);
	line_count++;
	BEGIN CHECK_INDENTATION;
}

<CHARACTERS><<EOF>> {
	print_error_msg("UNFINISHED_CONST_CHAR",char_error_log);
	BEGIN INITIAL;
}

<CHARACTERS>\\\" {
	char_token_and_log += "\"";
	char_error_log += yytext;	
}

<CHARACTERS>\\\' {
	char_token_and_log += "\'";
	char_error_log += yytext;
}

<CHARACTERS>\\n {
	char_token_and_log += "\n";
	char_error_log += yytext;
	
}

<CHARACTERS>\\t {
	char_token_and_log += "\t";
	char_error_log += yytext;
}

<CHARACTERS>\\r {
	char_token_and_log += "\r";
	char_error_log += yytext;
}

<CHARACTERS>\\v {
	char_token_and_log += "\v";
	char_error_log += yytext;
}

<CHARACTERS>\\f {
	char_token_and_log += "\f";
	char_error_log += yytext;
}

<CHARACTERS>\\a {
	char_token_and_log += "\a";
	char_error_log += yytext;
}

<CHARACTERS>\\b {
	char_token_and_log += "\b";
	char_error_log += yytext;
}

<CHARACTERS>\\\\ {
	char_token_and_log += "\\";
	char_error_log += yytext;
}

<CHARACTERS>\\0 {
	char_token_and_log += "\0";
	char_error_log += yytext;
	read_empty_char = true;
}



<CHARACTERS>\' {
	char_error_log += yytext;

	if(char_token_and_log.length() > 1)
	{
		print_error_msg("MULTICHAR_CONST_CHAR",char_error_log);
	}	
	else if(char_token_and_log.length() == 0)
	{
		if(read_empty_char)
		{
			print_token_in_file("CONST_CHAR",char_token_and_log);
			print_log_in_file("CONST_CHAR",char_token_and_log);
		}
		else
			print_error_msg("EMPTY_CONST_CHAR",char_error_log);
	}
	else if(char_token_and_log.length() == 1)
	{	
			print_token_in_file("CONST_CHAR",char_token_and_log);
			print_log_in_file("CONST_CHAR",char_token_and_log);
		
		
	}
	BEGIN INITIAL;
}

<CHARACTERS>; {
	if(char_token_and_log.length() == 0)
	{
		char_token_and_log += yytext;
		char_error_log += yytext;
	}

	else
	{
		print_error_msg("UNFINISHED_CONST_CHAR",char_error_log);
		tokenFile<<"<SEMICOLON, "<<yytext<<">"<<endl;
		logFile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found"<<endl;
		BEGIN INITIAL;
	
	}
}

<CHARACTERS>. {
	char_token_and_log += yytext;
	char_error_log += yytext;
}

\" {
	string_token = "";
	string_log = "\"";
	track_line_count = 0;
	string_variant = "SINGLE LINE STRING";
	BEGIN STRINGS;
}

<STRINGS>\\\" {
	string_log += yytext;
	string_token += "\"";
}

<STRINGS>\\\' {
	string_log += yytext;
	string_token += "\'";
}

<STRINGS>\\n {
	string_log += yytext;
	string_token += "\n";
	
}

<STRINGS>\\t {
	string_log += yytext;
	string_token += "\t";
}

<STRINGS>\\r {
	string_log += yytext;
	string_token += "\r";
}

<STRINGS>\\v {
	string_log += yytext;
	string_token += "\v";
}

<STRINGS>\\f {
	string_log += yytext;
	string_token += "\f";
}

<STRINGS>\\a {
	string_log += yytext;
	string_token += "\a";
}

<STRINGS>\\b {
	string_log += yytext;
	string_token += "\b";
}

<STRINGS>\\\\ {
	string_log += yytext;
	string_token += "\\";
}

<STRINGS>\\0 {
	string_log += yytext;
	string_token += "\0";
}

<STRINGS>\\{NEWLINE} {
	string_log += yytext;
	string_variant = "MULTI LINE STRING";
	track_line_count++;
}

<STRINGS>\" {
	string_log += yytext;
	print_token_in_file(string_variant,string_token);
	print_log_in_file(string_variant,string_log);
	line_count += track_line_count;
	BEGIN INITIAL;
}

<STRINGS>{NEWLINE} {
	print_error_msg("UNFINISHED_STRING",string_log,track_line_count+line_count);
	track_line_count++;
	line_count += track_line_count;
	BEGIN CHECK_INDENTATION;
}

<STRINGS><<EOF>> {
	print_error_msg("UNFINISHED_STRING",string_log);
	line_count += track_line_count;
	BEGIN INITIAL;
}

<STRINGS>. {
	string_log += yytext;
	string_token += yytext;
}

"//" {
	BEGIN SINGLE_LINE_COMMENTS;
	track_line_count = 1;
	comment_log = "//";

}

<SINGLE_LINE_COMMENTS>\\{NEWLINE} {
	comment_log += yytext;
	track_line_count++;//ase
}

<SINGLE_LINE_COMMENTS>{NEWLINE} {
	print_log_in_file("SINGLE LINE COMMENT",comment_log);
	line_count += track_line_count;//ase
	BEGIN CHECK_INDENTATION;
}

<SINGLE_LINE_COMMENTS><<EOF>> {
	print_log_in_file("SINGLE LINE COMMENT",comment_log);
	line_count += track_line_count;//ase
	BEGIN INITIAL;
}

<SINGLE_LINE_COMMENTS>. {
	comment_log += yytext;
}

"/*" {
	BEGIN MULTI_LINE_COMMENTS;
	track_line_count = 0;
	comment_log = "/*";
}

<MULTI_LINE_COMMENTS>{NEWLINE} {
	comment_log += yytext;
	track_line_count++;//ase
}

<MULTI_LINE_COMMENTS>"*/" {
	comment_log += yytext;
	print_log_in_file("MULTI LINE COMMENT",comment_log);
	line_count += track_line_count;//ase
	BEGIN INITIAL;
}

<MULTI_LINE_COMMENTS><<EOF>> {
	line_count += track_line_count;//ase
	print_error_msg("UNFINISHED_COMMENT",comment_log);
	BEGIN INITIAL;
}

<MULTI_LINE_COMMENTS>. {
	comment_log += yytext;
}

. {
	print_error_msg("UNRECOGNIZED_CHAR",yytext);
}



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

	tokenFile.open("2005067_token.txt");
	logFile.open("2005067_log.txt");
	

	yyin= fin;
	BEGIN CHECK_INDENTATION;
	yylex();
	fclose(yyin);

	symbol_table.print_all_scope_in_file();
	logFile<<"Total lines: "<<line_count<<endl;
	logFile<<"Total errors: "<<total_error<<endl;
	logFile<<"Total warnings: "<<total_warning<<endl;
	tokenFile.close();
	logFile.close();
	cout<<"work done"<<endl;
	return 0;
}