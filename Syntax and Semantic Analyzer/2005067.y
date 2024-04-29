%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<fstream>
#include "2005067.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

extern int line_count;
extern int total_error;

Symbol_Info* store = NULL;

ofstream parseTreeFile;
ofstream logFile;
ofstream errorFile;

vector<Symbol_Info*> parameterList;
//vector<Symbol_Info*> backupParameterList;//for backing up the paramter list of a function

//vector<Symbol_Info*> argumentList;
vector<Symbol_Info*> declarationList;
Symbol_Info* track_function = NULL;



Symbol_Table *table = new Symbol_Table(11,logFile);


void yyerror(char *s)
{
	//write your code
	cout<<"Syntax error"<<endl;

}

void set_line(Symbol_Info* non_terminal, vector<Symbol_Info*> symbolList)
{
	non_terminal->set_start_line(symbolList[0]->get_start_line());
	non_terminal->set_end_line(symbolList[symbolList.size()-1]->get_end_line());
}

void generate_error(string error_message, int line_no)
{
    errorFile<<"Line# " <<line_no<<": "<<error_message<<endl;
    total_error++;
}

void check_void_datatype_for_variables(string datatype)
{
    if(datatype == "VOID")
    {
        generate_error("Variable or field '" + declarationList[0]->get_name() + "' declared void",declarationList[0]->get_start_line());
    }
}

void manage_void_type_specifier(Symbol_Info* non_terminal, Symbol_Info* symbol1, Symbol_Info* symbol2)
{
    if(symbol1->get_type_specifier() == "VOID" || symbol2->get_type_specifier() == "VOID")
    {
        non_terminal->set_type_specifier("VOID");
    }

}

void add_variables_in_the_declaration_list(Symbol_Info* symbol_info)
{
    declarationList.push_back(symbol_info);
}

void insert_variables_in_symbol_table()
{
    for(int i = 0; i<declarationList.size(); i++)
    {
        bool inserted = table->insert(declarationList[i]);
		//mainly ekhane redeclaration hoche but type different hote pare ejonno conflicting types diyechi
        if(!inserted)
        {
          generate_error("Conflicting types for'" + declarationList[i]->get_name() + "'",declarationList[i]->get_start_line());
        }

    }
}

bool permission_to_insert_in_parameter_list()
{
	for(int i = 0; i< parameterList.size(); i++)
	{
		if(parameterList[i]->get_error_specifier() == "ERROR")
		{
			return false;
		}
	}
	return true;
}


bool check_parameter_related_errors(Symbol_Info* proposed_param)
{
	for(int i = 0; i<parameterList.size(); i++)
	{
		if(parameterList[i]->get_name() == proposed_param->get_name() && parameterList[i]->get_type_specifier() == proposed_param->get_type_specifier())
		{
			generate_error("Redefinition of parameter '" + proposed_param->get_name() + "'",proposed_param->get_start_line());
			parameterList[i]->set_error_specifier("ERROR");
			return true;
		}
	}
	return false;
}

void check_function_related_errors(Symbol_Info* func,string ret_type, bool want_define = false)
{
	Symbol_Info* present_function = table->lookup(func->get_name());//I am getting the function from the symbol tsble if it is already inserted


	if(!present_function->get_function_declared()){
		// already a declared variable error
		generate_error("'" + func->get_name() + "' redeclared as different kind of symbol", func->get_start_line());
		return;
	}

	else if(present_function->get_function_defined()){
		// function already defined error
		generate_error("Function '" + func->get_name() + "' already defined at line " + std::to_string(present_function->get_function_defined_line()), func->get_start_line());
	}

	else if(present_function->get_function_declared() && !want_define) {
		// multiple declaration error
		generate_error("Function '" + func->get_name() + "' already declared at line " + std::to_string(present_function->get_start_line()), func->get_start_line());
	}

	else if(present_function->get_function_declared() && want_define){
			if(present_function->get_type_specifier() != ret_type){
			// return type mismatch error
			generate_error("Conflicting types for '" + present_function->get_name() + "'", func->get_start_line());
		}

		else if(present_function->get_parameters().size() != func->get_parameters().size()){
			// parameter count mismatch error
			generate_error("Conflicting types for '" + present_function->get_name() + "'", func->get_start_line());
		}

		else {

			vector<Symbol_Info*> present_parameters = present_function->get_parameters();
			vector<Symbol_Info*> new_parameters = func->get_parameters();

			for(int i = 0; i < present_parameters.size(); i++){
				if(present_parameters[i]->get_type_specifier() != new_parameters[i]->get_type_specifier()){
					// parameter type mismatch error
					generate_error("Type mismatch for parameter " + std::to_string(i+1) +" of '"  + present_function->get_name() + "'", func->get_start_line());
				}
			}

			present_function->set_parameter_list(new_parameters);
			track_function = func;
		}
	}

	if(want_define && present_function->get_function_declared()) {
		present_function->set_function_defined(); 
		present_function->set_function_defined_line(func->get_start_line());
		}
}

void insert_function(Symbol_Info* func, bool want_define = false){

	string ret_type = func->get_type_specifier();

	track_function = func;

	if(want_define){
		
		func->set_function_defined();
		func->set_function_defined_line(func->get_start_line());

		for(int i = 0; i<parameterList.size(); i++)
		{
			if(parameterList[i]->get_name() == "")
			{
				//unnamed parameter error
				generate_error("Unnamed parameter at line " + std::to_string(parameterList[i]->get_start_line()), parameterList[i]->get_start_line());
			}
		}
		
	}
	
	bool inserted = table->insert(func);
	
	if(inserted) {
		track_function = func;
		return;
	} 

	check_function_related_errors(func,ret_type,want_define);
	
}



void include_parameters_in_the_scope(){
	if(track_function == NULL) return;//if there is no function to be declared then there will be no parameters so we don't need to insert paramters in the scope table

	for(int i = 0; i<parameterList.size(); i++)
	{
		if(parameterList[i]->get_name() != "")
		{
			table->insert(parameterList[i]);//inserting the parameters in the scope
		}
	}
	track_function = NULL;
}



Symbol_Info* check_variable_declared(Symbol_Info* symbol_info)
{
   Symbol_Info *temp = table->lookup(symbol_info->get_name());// I am cheching here if the variable is already declared
   return temp;
}

void check_array_index_type(Symbol_Info* symbol_info)
{
    if(symbol_info->get_type_specifier() != "INT")
    {
        generate_error("Array subscript is not an integer",symbol_info->get_start_line());
    }
}

void check_variable_declaration_related_errors(Symbol_Info* symbol_info, bool declared_array = false)
{
    Symbol_Info *temp = table->lookup(symbol_info->get_name());
    if(temp == NULL)
    {
        generate_error("Undeclared variable '" + symbol_info->get_name()+ "'",symbol_info->get_start_line());
    }
    //if the variable has been declared as a function then if it is used as a variable then I will show an error
    else if(temp->get_function_declared())
    {
        generate_error("Function '" + symbol_info->get_name() + "' used as a variable at line " + to_string(symbol_info->get_start_line()),symbol_info->get_start_line());
    }
    //if the variable is  array but when parsing we get that the variabke is not an array then I will show an error
    // else if(temp->get_is_array() && !declared_array)
    // {
    //     generate_error("Array '" + symbol_info->get_name() + "' used as a variable at line " + to_string(symbol_info->get_start_line()),symbol_info->get_start_line());
    // }
    //if the variable is not an array but when parsing we get that the variable is an array then I will show an error
    else if(!temp->get_is_array() && declared_array)
    {
        generate_error("'" + symbol_info->get_name() + "' is not an array",symbol_info->get_start_line());
    }
    
}

void check_assignment_related_errors(Symbol_Info* non_terminal,Symbol_Info* var, Symbol_Info* log_expression)
{
    //we can't assign value to a void datatype variable
    if(var->get_type_specifier() == "VOID")
    {
        generate_error("Void cannot be used in expression ",var->get_start_line());
        non_terminal->set_type_specifier("VOID");
    }
    //we can't assign void to a variable
    else if(log_expression->get_type_specifier() == "VOID")
    {
        generate_error("Void cannot be used in expression ",log_expression->get_start_line());
        non_terminal->set_type_specifier("VOID");
    }
    //we can add more combination later iw ill check it in the grammar rule
    else if(var->get_type_specifier() == "INT" && log_expression->get_type_specifier() == "FLOAT"){
        generate_error("Warning: possible loss of data in assignment of FLOAT to INT",var->get_start_line());
    } 
}

bool check_MULOP_errors(Symbol_Info* non_terminal, Symbol_Info* symbol1, Symbol_Info* symbol2, Symbol_Info* symbol3)
{
    if((symbol2->get_name() == "/" || symbol2->get_name() == "%") && symbol3->get_val() == "0")//here 0 division handeled
    {
        generate_error("Warning: division by zero i=0f=1Const=0", symbol3->get_start_line());
		non_terminal->set_type_specifier("ERROR");
		return true;
    }
    else if((symbol1->get_type_specifier() != "INT" || symbol3->get_type_specifier() != "INT") && symbol2->get_name() == "%")
    {
        generate_error("Operands of modulus must be integers ",symbol3->get_start_line());
        non_terminal->set_type_specifier("ERROR");
		return true;
    }
	return false;
}

void check_argument_related_errors(Symbol_Info* non_terminal, Symbol_Info* id, Symbol_Info* arg_list)
{   
    Symbol_Info *symbol= table->lookup(id->get_name());
		

		if(!symbol){
			generate_error("Undeclared function '" + id->get_name() + "'", id->get_start_line());
			non_terminal->set_type_specifier("ERROR");
		}
		
		else{
			
			non_terminal->set_type_specifier(symbol->get_type_specifier());
			// if not function
			if(!symbol->get_function_declared()){
				generate_error(id->get_name() + " is not a function", id->get_start_line());
			}

			// else if paramater size not equal
			else if(symbol->get_parameters().size() > arg_list->get_parameters().size()){
				generate_error("Too few arguments to function '" + id->get_name() + "'", id->get_start_line());
				
			}

			else if(symbol->get_parameters().size() < arg_list->get_parameters().size()){
				generate_error("Too many arguments to function '" + id->get_name() + "'", id->get_start_line());
			}

			// else if parameter type mismatch
			else{
				vector<Symbol_Info*> params_list = symbol->get_parameters();
				vector<Symbol_Info*> args_list = arg_list->get_parameters();

				for(int i=0; i<params_list.size(); i++){

					if(params_list[i]->get_type_specifier() != args_list[i]->get_type_specifier()){
							generate_error("Type mismatch for argument " + std::to_string(i+1) +" of '"  + symbol->get_name() + "'", id->get_start_line());
						
					}
				}
			} 
		}

}



string type_casting(string left_side_datatype, string right_side_datatype)
{
    if(left_side_datatype == "FLOAT" || right_side_datatype == "FLOAT")
        return "FLOAT";
    else if(left_side_datatype == "DOUBLE" || right_side_datatype == "DOUBLE")
        return "DOUBLE";
    else if(left_side_datatype == "VOID" || right_side_datatype == "VOID")
        return "VOID";
    else return "INT";
}

void print_parse_tree_in_file(Symbol_Info* symbol_info, int num_of_spaces)
{
    int i = 0;
    while(i<num_of_spaces)
    {
        parseTreeFile<<" ";
        i++;
    }

    symbol_info->print_grammar(parseTreeFile);
    vector<Symbol_Info*> temp_children = symbol_info->get_children();

    for(int j = 0; j<temp_children.size(); j++)
    {
        print_parse_tree_in_file(temp_children[j], num_of_spaces+1);
    }
}


%}

%union{
    Symbol_Info* symbol_info;
}

%token<symbol_info> IF ELSE FOR WHILE DO BREAK  INT CHAR  FLOAT DOUBLE  VOID RETURN SWITCH CASE DEFAULT CONTINUE ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP  NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON  CONST_INT CONST_FLOAT ID PRINTLN
%type<symbol_info> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement argument_list arguments variable factor term unary_expression simple_expression rel_expression logic_expression expression

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		//write your code in this block in all the similar blocks below
		logFile<<"start : program "<<endl;
		$$ = new Symbol_Info("start","non-leaf");
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
		print_parse_tree_in_file($$,0);
		
	}
	;

program : program unit {
	logFile<<"program : program unit "<<endl;
    $$ = new Symbol_Info("program","non-leaf");
    $$->append_children({$1,$2});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2});
} 
	| unit {
		 logFile<<"program : unit "<<endl;
		$$ = new Symbol_Info("program","non-leaf");
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
	}
	;
	
unit : var_declaration {
	logFile<<"unit : var_declaration  "<<endl;
    $$ = new Symbol_Info("unit","non-leaf");
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}
     | func_declaration {
		logFile<<"unit : func_declaration "<<endl;
		$$ = new Symbol_Info("unit","non-leaf");
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
	 }
     | func_definition {
		 logFile<<"unit : func_definition  "<<endl;
		$$ = new Symbol_Info("unit","non-leaf");
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
	 logFile<<"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON "<<endl;
    $$ = new Symbol_Info("func_declaration","non-leaf",$1->get_type());
   // $$->set_type_specifier($1->get_type());//basically the return type
	$2->set_type_specifier($1->get_type());//this will set the type of the function
	$2->set_type("FUNCTION");
	$2->set_function_declared();
	$2->add_parameters(parameterList);
	parameterList.clear();
    insert_function($2);//,$1->get_type());//need to work with this function
    $$->append_children({$1,$2,$3,$4,$5,$6});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3,$4,$5,$6});
}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
			logFile<<"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON "<<endl;
			$$ = new Symbol_Info("func_declaration","non_leaf",$1->get_type());
			//$$->set_type_specifier($1->get_type());//return type(here type specifier is linke int a where int is the type specifier of a variable)
			$2->set_type_specifier($1->get_type());//this will set the type of the function
			$2->set_type("FUNCTION");
			$2->set_function_declared();
			insert_function($2);//,$1->get_type());
			$$->append_children({$1,$2,$3,$4,$5});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3,$4,$5});
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN{$2->set_type_specifier($1->get_type());$2->set_type("FUNCTION");} compound_statement {
	 logFile<<"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl;
    $$ = new Symbol_Info("func_definition","non-leaf",$1->get_type());
	//$$->set_type_specifier($1->get_type());//return type(here type specifier is linke int a where int is the type specifier of a variable)
	$2->add_parameters(parameterList);
	parameterList.clear();
	$2->set_function_declared();
	store = $2;
    $$->append_children({$1,$2,$3,$4,$5,$7});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3,$4,$5,$7}); 
}
		| type_specifier ID LPAREN RPAREN{$2->set_type_specifier($1->get_type());$2->set_type("FUNCTION");} compound_statement {
			 logFile<<"func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl;
			$$ = new Symbol_Info("func_definition","non-leaf",$1->get_type());
			//$$->set_type_specifier($1->get_type());//return type(here type specifier is linke int a where int is the type specifier of a variable)
			$2->set_function_declared();
			store = $2;
			$$->append_children({$1,$2,$3,$4,$6});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3,$4,$6});
		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID {
	 logFile<<"parameter_list  : parameter_list COMMA type_specifier ID"<<endl;
    $$ = new Symbol_Info("parameter_list","non-leaf");
    $4->set_type_specifier($3->get_type());//int a,here int is the type_specifier for iD a
	if(! check_parameter_related_errors($4) && permission_to_insert_in_parameter_list()){
   	 parameterList.push_back($4); //here i have to check redeclaration part
	
	}
    $$->append_children({$1,$2,$3,$4});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3,$4});
}
		| parameter_list COMMA type_specifier {
			logFile<<"parameter_list : parameter_list COMMA type_specifier "<<endl;
			$$ = new Symbol_Info("parameter_list","non-leaf");
			Symbol_Info* demo_id = new Symbol_Info("","ID",$3->get_type());
			parameterList.push_back(demo_id);
			$$->append_children({$1,$2,$3});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3});
		}
 		| type_specifier ID {
			logFile<<"parameter_list  : type_specifier ID"<<endl;
			$$ = new Symbol_Info("parameter_list","non-leaf");
			$2->set_type_specifier($1->get_type());//int a,here int is the type_specifier for iD a
			if(!check_parameter_related_errors($2) && permission_to_insert_in_parameter_list()){
				parameterList.push_back($2);//here i have to check redeclaration part
			}
			$$->append_children({$1,$2});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2});
		}
		| type_specifier {
				 logFile<<"parameter_list : type_specifier "<<endl;
				$$ = new Symbol_Info("parameter_list","non-leaf");
				Symbol_Info* demo_id = new Symbol_Info("","ID",$1->get_type());
				parameterList.push_back(demo_id);
				$$->append_children({$1});
				$$->set_is_leaf(false);
				set_line($$,{$1});
		}
 		;

 		
compound_statement : LCURL{if(store != NULL)
	{
		insert_function(store,true);
	}table->enter_scope(logFile);include_parameters_in_the_scope();} statements RCURL 
{
	 logFile<<"compound_statement : LCURL statements RCURL  "<<endl;
    $$ = new Symbol_Info("compound_statement","non-leaf");
    $$->append_children({$1,$3,$4});
    $$->set_is_leaf(false);
    set_line($$,{$1,$3,$4});
	if(table == NULL)
					cout<<"table is null"<<endl;
    table->print_all_scope_in_file();//when I am getting Rcurl that means my scope has been ended and so I have to print the scope tables and exit scope
    table->exit_scope();
	
	store = NULL;
}
 		    | LCURL{if(store != NULL)
				{
					insert_function(store,true);
				}table->enter_scope(logFile);include_parameters_in_the_scope();} RCURL {
				logFile<<"compound_statement : LCURL RCURL "<<endl;
				$$ = new Symbol_Info("compound_statement","non-leaf");
				$$->append_children({$1,$3});
				$$->set_is_leaf(false);
				set_line($$,{$1,$3});
				if(table == NULL)
					cout<<"table is null"<<endl;
				table->print_all_scope_in_file();//when I am getting Rcurl that means my scope has been ended and so I have to print the scope tables and exit scope
				table->exit_scope();
				
				store = NULL;
			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
	logFile<<"var_declaration : type_specifier declaration_list SEMICOLON  "<<endl;
    $$ = new Symbol_Info("var_declaration","non-leaf");
    for(int i = 0; i<declarationList.size(); i++)
    {
		if(declarationList[i]->get_is_array())	declarationList[i]->set_type_specifier($1->get_type());//array handeling
        else declarationList[i]->set_type_specifier($1->get_type());//I am specifying the datatype of the variable here
    }
    $$->append_children({$1,$2,$3});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3});
	if($1->get_type() != "VOID")
    	insert_variables_in_symbol_table();
    check_void_datatype_for_variables($1->get_type());
}
 		 ;
 		 
type_specifier	: INT {
	logFile<<"type_specifier	: INT "<<endl;
	$$ = new Symbol_Info("type_specifier","INT");
	$$->append_children({$1});
	$$->set_is_leaf(false);
	set_line($$, {$1});

}
 		| FLOAT {
			logFile<<"type_specifier	: FLOAT "<<endl;
			$$ = new Symbol_Info("type_specifier","FLOAT");
			$$->append_children({$1});
			$$->set_is_leaf(false);
			set_line($$, {$1});
		}
 		| VOID{
			logFile<<"type_specifier	: VOID"<<endl;
			$$ = new Symbol_Info("type_specifier","VOID");
			$$->append_children({$1});
			$$->set_is_leaf(false);
			set_line($$, {$1});
		}
 		;
 		
declaration_list : declaration_list COMMA ID {
	logFile<<"declaration_list : declaration_list COMMA ID  "<<endl;
    $$ = new Symbol_Info("declaration_list","non-leaf");
    add_variables_in_the_declaration_list($3);
    $$->append_children({$1,$2,$3});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3});
}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
			logFile<<"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE "<<endl;
			$$ = new Symbol_Info("declaration_list","non-leaf");
			$3->set_array_declared(stoi($5->get_name()));
			add_variables_in_the_declaration_list($3);
			$$->append_children({$1,$2,$3,$4,$5,$6});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3,$4,$5,$6});
		  }
 		  | ID {
			declarationList.clear();
			logFile<<"declaration_list : ID "<<endl;
			$$ = new Symbol_Info("declaration_list","non-leaf");
			add_variables_in_the_declaration_list($1);
			$$->append_children({$1});
			$$->set_is_leaf(false);
			set_line($$,{$1});
		  }
 		  | ID LTHIRD CONST_INT RTHIRD {
			declarationList.clear();
			logFile<<"declaration_list : ID LSQUARE CONST_INT RSQUARE "<<endl;
			$$ = new Symbol_Info("declaration_list","non-leaf");
			$1->set_array_declared(stoi($3->get_name()));//this will indicate that the array is located with the size of const_int
			add_variables_in_the_declaration_list($1);
			$$->append_children({$1,$2,$3,$4});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3,$4});
		  }
 		  ;
 		  
statements : statement {
	logFile<<"statements : statement  "<<endl;
    $$ = new Symbol_Info("statements","non-leaf");
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}
	   | statements statement {
		logFile<<"statements : statements statement  "<<endl;
		$$ = new Symbol_Info("statements","non-leaf");
		$$->append_children({$1,$2});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2});
	   }
	   ;
	   
statement : var_declaration {
	 logFile<<"statement : var_declaration "<<endl;
    $$ = new Symbol_Info("statement","non-leaf");
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}
	  | expression_statement {
		logFile<<"statement : expression_statement  "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
	  }
	  | compound_statement {
		 logFile<<"statement : compound_statement "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
		 logFile<<"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		$$->append_children({$1,$2,$3,$4,$5,$6,$7});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4,$5,$6,$7});
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
		logFile<<"statement : IF LPAREN expression RPAREN statement "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		$$->append_children({$1,$2,$3,$4,$5});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4,$5});

	  } 
	  | IF LPAREN expression RPAREN statement ELSE statement {
		 logFile<<"statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		$$->append_children({$1,$2,$3,$4,$5,$6,$7});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4,$5,$6,$7});
	  }
	  | WHILE LPAREN expression RPAREN statement {
		logFile<<"statement : WHILE LPAREN expression RPAREN statement "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		$$->append_children({$1,$2,$3,$4,$5});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4,$5});
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
		logFile<<"statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl;
		$$ = new Symbol_Info("statement","non-leaf");
		check_variable_declared($3);
		$$->append_children({$1,$2,$3,$4,$5});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4,$5});
	  }
	  | RETURN expression SEMICOLON {
			 logFile<<"statement : RETURN expression SEMICOLON"<<endl;
			$$ = new Symbol_Info("statement","non-leaf");
			$$->append_children({$1,$2,$3});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3});
	  }
	  ;
	  
expression_statement 	: SEMICOLON {
	logFile<<"expression_statement : SEMICOLON "<<endl;
    $$ = new Symbol_Info("expression_statement","non-leaf");
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}			
			| expression SEMICOLON {
				logFile<<"expression_statement : expression SEMICOLON 		 "<<endl;
				$$ = new Symbol_Info("expression_statement","non-leaf");
				$$->append_children({$1,$2});
				$$->set_is_leaf(false);
				set_line($$,{$1,$2});
			}
			;
	  
variable : ID {
	logFile<<"variable : ID 	 "<<endl;
    $$ = new Symbol_Info("variable","non-leaf");

    //I have to check whether the variable is declared or not
    if(check_variable_declared($1))
        $$->set_type_specifier((check_variable_declared($1)->get_type_specifier()));//it will set the type specifier of variable to track down the variable
    else $$->set_type_specifier("NULL");
    check_variable_declaration_related_errors($1);
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}		
	 | ID LTHIRD expression RTHIRD {
		logFile<<"variable : ID LSQUARE expression RSQUARE  	 "<<endl;
		$$ = new Symbol_Info("variable","non-leaf");
		$1->set_array_declared(0);//this will indicate that the array is located with the size of const_int
		//I have to check whether the variable is declared or not
		if(check_variable_declared($1))
			$$->set_type_specifier((check_variable_declared($1)->get_type_specifier()));//it will set the type specifier of variable to track down the variable
		else $$->set_type_specifier("ERROR");
		check_variable_declaration_related_errors($1,true);
		check_array_index_type($3);
		$$->append_children({$1,$2,$3,$4});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4});
	 }
	 ;
	 
 expression : logic_expression {
	logFile<<"expression 	: logic_expression	 "<<endl;
    $$ = new Symbol_Info("expression","non-leaf", $1->get_type_specifier());
    //$$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
 }	
	   | variable ASSIGNOP logic_expression {
		 logFile<<"expression 	: variable ASSIGNOP logic_expression 		 "<<endl;
		$$ = new Symbol_Info("expression","non-leaf", $1->get_type_specifier());
		//$$->set_type_specifier($1->get_type_specifier());
		check_assignment_related_errors($$,$1,$3);//this will check assignment related errors
		$$->append_children({$1,$2,$3});    
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3});
	   } 	
	   ;
			
logic_expression : rel_expression {
	logFile<<"logic_expression : rel_expression 	 "<<endl;
    $$ = new Symbol_Info("logic_expression","non-leaf", $1->get_type_specifier());
    //$$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1}); 
}	
		 | rel_expression LOGICOP rel_expression {
			 logFile<<"logic_expression : rel_expression LOGICOP rel_expression 	 	 "<<endl;
			$$ = new Symbol_Info("logic_expression","non-leaf", "INT");
			//$$->set_type_specifier("INT");
			//if any datatype of rel-expression is void then I have to handle the case.I will take care of it later
			manage_void_type_specifier($$,$1,$3);
			$$->append_children({$1,$2,$3});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3});
		 }	
		 ;
			
rel_expression	: simple_expression {
	 logFile<<"rel_expression	: simple_expression "<<endl;
    $$ = new Symbol_Info("rel_expression","non-leaf", $1->get_type_specifier());
   // $$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1});
	$$->set_is_leaf(false);
	set_line($$,{$1});
} 
		| simple_expression RELOP simple_expression {
			logFile<<"rel_expression	: simple_expression RELOP simple_expression	  "<<endl;
			$$ = new Symbol_Info("rel_expression","non-leaf","INT");//we will do Symbol_Info("rel_expression","non-leaf","INT");
			//$$->set_type_specifier("INT");//this line can be omitted
			//if any datatype of simple-expression is void then I have to handle the case.I will take care of it later
			manage_void_type_specifier($$,$1,$3);
			$$->append_children({$1,$2,$3});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3});
		}	
		;
				
simple_expression : term {
	logFile<<"simple_expression : term "<<endl;
    $$ = new Symbol_Info("simple_expression","non-leaf", $1->get_type_specifier());
    //$$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
} 
		  | simple_expression ADDOP term {
			 logFile<<"simple_expression : simple_expression ADDOP term  "<<endl;
			$$ = new Symbol_Info("simple_expression","non-leaf",type_casting($1->get_type_specifier(),$3->get_type_specifier()));
			//$$->set_type_specifier(type_casting($1->get_type_specifier(),$3->get_type_specifier()));
			$$->append_children({$1,$2,$3});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2,$3});
		  } 
		  ;
					
term :	unary_expression {
	logFile<<"term :	unary_expression "<<endl;
    $$ = new Symbol_Info("term","non-leaf", $1->get_type_specifier());
    //$$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}
     |  term MULOP unary_expression {
		logFile<<"term :	term MULOP unary_expression "<<endl;
    $$ = new Symbol_Info("term","non-leaf");
    if(!check_MULOP_errors($$,$1,$2,$3))
    	$$->set_type_specifier(type_casting($1->get_type_specifier(),$3->get_type_specifier()));
    $$->append_children({$1,$2,$3});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3});
	 }
     ;

unary_expression : ADDOP unary_expression {
	  logFile<<"unary_expression : NOT unary_expression "<<endl;
    	$$ = new Symbol_Info("unary_expression","non-leaf", "INT");
    	//$$->set_type_specifier("INT");
    	$$->append_children({$1,$2});
    	$$->set_is_leaf(false);
    	set_line($$,{$1,$2});
} 
		 | NOT unary_expression {
			 logFile<<"unary_expression : NOT unary_expression "<<endl;
			$$ = new Symbol_Info("unary_expression","non-leaf", "INT");
			//$$->set_type_specifier("INT");
			$$->append_children({$1,$2});
			$$->set_is_leaf(false);
			set_line($$,{$1,$2});
		 } 
		 | factor {
			logFile<<"unary_expression : factor "<<endl;
		$$ = new Symbol_Info("unary_expression","non-leaf", $1->get_type_specifier());
		$$->set_val($1->get_val());
		//$$->set_type_specifier($1->get_type_specifier());
		$$->append_children({$1});
		$$->set_is_leaf(false);
		set_line($$,{$1});
		 }
		 ;
	
factor	: variable {
	logFile<<"factor	: variable "<<endl;
    $$ = new Symbol_Info("factor","non-leaf", $1->get_type_specifier());
    //$$->set_type_specifier($1->get_type_specifier());
    if($1->get_is_array())
    {
        $$->set_array_declared($1->get_array_size());
    }
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}
	| ID LPAREN argument_list RPAREN {
		 logFile<<"factor	: ID LPAREN argument_list RPAREN  "<<endl;
		$$ = new Symbol_Info("factor","non-leaf");
		check_argument_related_errors($$,$1,$3);
		//if there is no argument in the function call then I will not consider argument list as children
		if($3->get_children().size()>0)           
			$$->append_children({$1,$2,$3,$4});
		else $$->append_children({$1,$2,$4});
		$$->set_is_leaf(false);
		set_line($$,{$1,$2,$3,$4});
	}
	| LPAREN expression RPAREN {
		logFile<<"factor	: LPAREN expression RPAREN   "<<endl;
        $$ = new Symbol_Info("factor","non-leaf", $2->get_type_specifier());
        //$$->set_type_specifier($2->get_type_specifier());
        $$->append_children({$1,$2,$3});
        $$->set_is_leaf(false);
        set_line($$,{$1,$2,$3});
	}
	| CONST_INT {
		 logFile<<"factor	: CONST_INT   "<<endl;
    $$ = new Symbol_Info("factor","non-leaf", "INT");
    //$$->set_type_specifier("INT");
	$$->set_val($1->get_name());
    $$->append_children({$1});  
    $$->set_is_leaf(false);
    set_line($$,{$1}); 
	}
	| CONST_FLOAT {
		logFile<<"factor	: CONST_FLOAT   "<<endl;
    $$ = new Symbol_Info("factor","non-leaf", "FLOAT");
    //$$->set_type_specifier("FLOAT");
	$$->set_val($1->get_name());
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
	}
	| variable INCOP {
		 logFile<<"factor : variable INCOP "<<endl;
    $$ = new Symbol_Info("factor","non-leaf", $1->get_type_specifier());
    //$$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1,$2});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2});
    if($1->get_is_array())
        generate_error("Array can't be incremented", $1->get_start_line());//array can not be incremented
	}
	| variable DECOP {
		logFile<<"factor : variable DECOP "<<endl;
    $$ = new Symbol_Info("factor","non-leaf", $1->get_type_specifier());
   // $$->set_type_specifier($1->get_type_specifier());
    $$->append_children({$1,$2});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2});
    if($1->get_is_array())
        generate_error("Array can't be decremented", $1->get_start_line());//array can not be decremented   
	}
	;
	
argument_list : arguments {
	logFile<<"argument_list : arguments  "<<endl;
    $$ = new Symbol_Info("argument_list","non-leaf");
    $$->set_parameter_list($1->get_parameters());
    $$->append_children({$1});
    $$->set_is_leaf(false);
    set_line($$,{$1});
}
			  | {
				logFile<<"argument_list : "<<endl;
        		$$ = new Symbol_Info("argument_list","non-leaf"); 
			  }
			  ;
	
arguments : arguments COMMA logic_expression {
	 logFile<<"arguments : arguments COMMA logic_expression "<<endl;
    $$ = new Symbol_Info("arguments","non-leaf");
    $$->set_parameter_list($1->get_parameters()); 
	$$->add_single_parameter($3);  
	//cout<<"ss er argument list size : "<<$$->get_parameters().size()<<endl;
    $$->append_children({$1,$2,$3});
    $$->set_is_leaf(false);
    set_line($$,{$1,$2,$3});
}
	      | logic_expression {
			logFile<<"arguments : logic_expression"<<endl;
			$$ = new Symbol_Info("arguments","non-leaf");
			$$->add_single_parameter($1);
			//cout<<"Vai ami j ki kri "<<$$->get_parameters().size()<<endl;
			$$->append_children({$1});
			$$->set_is_leaf(false);
			set_line($$,{$1});
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{
    //print();
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

	parseTreeFile.open("2005067_parseTree.txt");
	logFile.open("2005067_log.txt");
    errorFile.open("2005067_error.txt");
	

	yyin=fin;
	yyparse();
	

	fclose(fin);

	
	logFile<<"Total Lines: "<<line_count<<endl;
	logFile<<"Total Errors: "<<total_error<<endl;

	logFile.close();
    parseTreeFile.close();
    errorFile.close();
	
	return 0;
}

