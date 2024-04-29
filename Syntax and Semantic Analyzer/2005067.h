#include <iostream>
#include <cstring>
#include <fstream>
#include <sstream>
#include<vector>
using namespace std;

//int scopeId = 1;

class Symbol_Info
{
private:
    string name;
    string type;
    string type_specifier;
    string error_specifier = "NOERROR";

    int start_line;
    int end_line;
    int array_size = 0;
    int function_defined_line = 0;
    string val;

    bool is_leaf = true;
    bool is_array = false;
    bool is_function_declared = false;
    bool is_function_defined = false;


    
    vector<Symbol_Info*> children;
    vector<Symbol_Info*> parameters;

    Symbol_Info *next;
    ofstream *classOutFile;

public:
    Symbol_Info(string name, string type,ofstream &outFile)
    {
        this->name = name;
        this->type = type;
        this->next = NULL;
        this->classOutFile = &outFile;
    }

    Symbol_Info(string name, string type, int start_line = 0, int end_line = 0)
    {
        this->name = name;
        this->type = type;
        this->start_line = start_line;
        this->end_line = end_line;
        this->next = NULL;
    }

    Symbol_Info(string name, string type, string type_specifier, int start_line = 0, int end_line = 0)
    {
        this->name = name;
        this->type = type;
        this->type_specifier = type_specifier;
        this->start_line = start_line;
        this->end_line = end_line;
        this->next = NULL;
        //this->classOutFile = &outFile;
    }

     //for inserting a symbol_info object in the symbol table directly
    Symbol_Info(Symbol_Info* symbol_info)
    {
        this->name = symbol_info->get_name();
        this->type = symbol_info->get_type();
        this->type_specifier = symbol_info->get_type_specifier();
        this->start_line = symbol_info->get_start_line();
        this->end_line = symbol_info->get_end_line();
        this->next = symbol_info->next;
        this->is_leaf - symbol_info->get_is_leaf();
        this->children = symbol_info->get_children();
        this->parameters = symbol_info->get_parameters();
        this->array_size = symbol_info->get_array_size();
        this->is_array = symbol_info->get_is_array();
        this->is_function_declared = symbol_info->get_function_declared();
        this->is_function_defined = symbol_info->get_function_defined();    
    }

    ~Symbol_Info()
    {
        //cout << "destructor called" << endl;
        
        if (next != NULL)
        {
            Symbol_Info *temp = next; // Store the next pointer in a temporary variable
            next = NULL;              // Set the current object's next pointer to NULL
            delete temp;              // Delete the temporary variable, releasing the memory
        }
    }

    string get_name()
    {
        return this->name;
    }

    string get_type()
    {
        return this->type;
    }

    int get_start_line()
    {
        return this->start_line;
    }

    int get_end_line()
    {
        return this->end_line;
    }

    bool get_is_leaf()
    {
        return this->is_leaf;
    }

      bool get_is_array()
    {
        return this->is_array;
    }

     bool get_function_declared()
    {
        return this->is_function_declared;
    }

     string get_type_specifier()
    {
        return this->type_specifier;
    }

    int get_array_size()
    {
        return this->array_size;
    }

    bool get_function_defined()
    {
        return this->is_function_defined;
    }

    int get_function_defined_line()
    {
        return this->function_defined_line;
    }

    vector<Symbol_Info*> get_parameters()
    {
        return this->parameters;
    } 

    vector<Symbol_Info*> get_children()
    {
        return this->children;
    }

    string get_error_specifier()
    {
        return this->error_specifier;
    }

    string get_val()
    {
        return this->val;
    }

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    void set_type_specifier(string type_specifier)
    {
        this->type_specifier = type_specifier;
    }

    Symbol_Info *get_next()
    {
        return this->next;
    }

    void set_next(Symbol_Info *next)
    {
        this->next = next;
    }

    void set_start_line(int start_line)
    {
        this->start_line = start_line;
    }

    void set_end_line(int end_line)
    {
        this->end_line = end_line;
    }

    void set_is_leaf(bool is_leaf)
    {
        this->is_leaf = is_leaf;
    }

    void set_error_specifier(string error_specifier)    
    {
        this->error_specifier = error_specifier;
    }
     void set_array_declared(int array_size)
    {
        this->is_array = true;
        this->array_size = array_size;
    }

    void set_val(string val)
    {
        this->val = val;
    }

     void set_function_declared()
    {
        this->is_function_declared = true;
    }

    void set_function_defined()
    {
        this->is_function_defined = true;
    }

    void set_function_defined_line(int function_defined_line)
    {
        this->function_defined_line = function_defined_line;
    }

    void set_parameter_list(vector<Symbol_Info*> parameters)
    {
        this->parameters = parameters;
    }

    void add_parameters(vector<Symbol_Info*> parameters)
    {
        this->parameters.insert(this->parameters.end(), parameters.begin(), parameters.end());
    }

    void add_single_parameter(Symbol_Info* parameter)
    {
        this->parameters.push_back(parameter);
    }

    void append_children(vector<Symbol_Info*> children)
    {
        this->children.insert(this->children.end(), children.begin(), children.end());
        // cout<<"Kaj hoche"<<endl;
    }

     //this will print the grammar rules when the parsing is being ongoing
    void print_grammar(ofstream &outFile)
    {
        if(!is_leaf)
        {
            outFile << this->name << " : ";
            for(int i = 0; i < children.size(); i++)
            {
                if(!children[i]->is_leaf)    
                    outFile << children[i]->name << " ";
                else
                    if(children[i]->is_function_declared) outFile << "ID ";
                    else outFile << children[i]->type << " ";
                    // outFile << children[i]->type << " ";
            }
            outFile << "\t" << "<Line: " << start_line << "-" << end_line << ">" << endl;
        }

        else
        {
            //cout<<"not entered"<<endl;
            if(this->is_function_declared) outFile<< "ID " << ": "<<this->name<<"\t" << "<Line: " << start_line << ">" << endl;
            else
                outFile << this->type << " : " << this->name << "\t" << "<Line: " << start_line << ">" << endl;
        }
    }

    void print()
    {
        cout << "(" << this->name << "," << this->type << ")";
    }

    void printInFile(ofstream &outFile)
    {
        if(name != "main"){
            if(type == "FUNCTION")  outFile << "<" << this->name << "," <<this->type<<","<<this->type_specifier << "> ";
            else if(is_array) outFile << "<" << this->name << "," << "ARRAY> ";
            else outFile << "<" << this->name << "," << this->type_specifier << "> ";
        }
    }
};

class Scope_Table
{
private:
    Symbol_Info **table;
    Scope_Table *parentScope;
    ofstream *classOutFile;
    int scope_id;
    int size; // no of buckets
public:
    Scope_Table(int scope_id, int size, Scope_Table *parentScope, ofstream &outFile)
    {
        this->scope_id = scope_id;
        this->size = size;
        this->parentScope = parentScope;
        this->classOutFile = &outFile;
        table = new Symbol_Info *[size];
        for (int i = 0; i < size; i++)
        {
            table[i] = NULL;
        }
    }

    ~Scope_Table()
    {
        //cout << "destructor of scopetable called" << endl;
        
        for (int i = 0; i < size; i++)
        {
            if (table[i] != NULL)
            {
                Symbol_Info *temp = table[i];
                table[i] = NULL;
                delete temp;
            }
        }
        delete[] table;
    }

    static unsigned long long sdbm(unsigned char *str)
    {
        unsigned long long hash = 0;
        int c;

        while (c = *str++)
            hash = c + (hash << 6) + (hash << 16) - hash;

        return hash;
    }

    void set_parentScope(Scope_Table *parentScope)
    {
        this->parentScope = parentScope;
    }

    Scope_Table *get_parentScope()
    {
        return this->parentScope;
    }

    int get_scope_id()
    {
        return this->scope_id;
    }

    void set_scope_id(int scope_id)
    {
        this->scope_id = scope_id;
    }

    int get_size()
    {
        return this->size;
    }

    bool insert(string name, string type)
    {
        unsigned long long hash = sdbm((unsigned char *)name.c_str());
        int index = (hash % size);
        Symbol_Info *temp = table[index];
        int order = 1;
        if (temp == NULL)
        {
            table[index] = new Symbol_Info(name, type, *classOutFile);
            //*classOutFile << "\tInserted  at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
            return true;
        }
        else
        {
            while (temp->get_next() != NULL)
            {
                if (temp->get_name() == name)
                {
                    return false;
                }
                temp = temp->get_next();
                order++;
            }
            if (temp->get_name() == name)
            {
                return false;
            }
            order++;
            temp->set_next(new Symbol_Info(name, type, *classOutFile));
            //*classOutFile << "\tInserted  at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
            return true;
        }
    }

     bool insert(Symbol_Info* symbol_info)
    {
        string name = symbol_info->get_name();
        unsigned long long hash = sdbm((unsigned char *)name.c_str());
        int index = (hash % size);
        Symbol_Info *temp = table[index];
        int order = 1;
        if (temp == NULL)
        {
            table[index] = new Symbol_Info(symbol_info);
            //*classOutFile << "\tInserted  at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
            return true;
        }
        else
        {
            while (temp->get_next() != NULL)
            {
                if (temp->get_name() == name)
                {
                    return false;
                }
                temp = temp->get_next();
                order++;
            }
            if (temp->get_name() == name)
            {
                return false;
            }
            order++;
            temp->set_next(new Symbol_Info(symbol_info));
            //*classOutFile << "\tInserted  at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
            return true;
        }
    }


    Symbol_Info *lookup(string name)
    {
        unsigned long long hash = sdbm((unsigned char *)name.c_str());
        int index = hash % size;
        Symbol_Info *temp = table[index];
        int order = 1;
        while (temp != NULL)
        {
            if (temp->get_name() == name)
            {
                //*classOutFile << "\t'" << temp->get_name() << "' found at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
                return temp;
            }
            temp = temp->get_next();
            order++;
        }
        return NULL;
    }

    bool delete_symbol(string name)
    {
        unsigned long long hash = sdbm((unsigned char *)name.c_str());
        int index = hash % size;
        Symbol_Info *temp = table[index];
        int order = 1;
        if (temp == NULL)
        {
            //*classOutFile << "\tNot found in the current ScopeTable# " << scope_id << endl;
            return false;
        }
        else if (temp->get_name() == name)
        {
            table[index] = temp->get_next();
            temp->set_next(NULL);
            delete temp;
           // *classOutFile << "\tDeleted "<< "'" << name << "'"<< " from position "<< "<" << (index + 1) << ", " << order << ">"<< " of ScopeTable# " << scope_id << endl;
            return true;
        }
        else
        {
            while (temp->get_next() != NULL)
            {
                order++;
                if (temp->get_next()->get_name() == name)
                {
                    Symbol_Info *temp2 = temp->get_next();
                    temp->set_next(temp2->get_next());
                    temp2->set_next(NULL);
                    delete temp2;
                   // *classOutFile << "\tDeleted "<< "'" << name << "'"<< " from position "<< "<" << (index + 1) << ", " << order << ">"<< " of ScopeTable# " << scope_id << endl;
                    return true;
                }
                temp = temp->get_next();
            }
           // *classOutFile << "\tNot found in the current ScopeTable# " << scope_id << endl;
            return false;
        }
    }

    void print()
    {
        cout << "ScopeTable # " << this->scope_id << endl;
        for (int i = 0; i < size; i++)
        {
            cout << i << " --> ";
            Symbol_Info *temp = table[i];
            while (temp != NULL)
            {
                temp->print();
                temp = temp->get_next();
            }
            cout << endl;
        }
    }

    void printInFile()
    {
        *classOutFile << "\tScopeTable# " << this->scope_id << endl;
        //cout<<"ami ki asi"<<endl;
        for (int i = 0; i < size; i++)
        {
            
            Symbol_Info *temp = table[i];
            Symbol_Info* prev = NULL;
            // if(temp!=NULL && i!=0)
            // {
            //     *classOutFile<<endl;
            // }
            if(temp!=NULL)
            {
                *classOutFile << "\t" << i+1<<"--> ";
            }
            //cout<<"hehe"<<endl;
            while (temp != NULL)
            {
               
                temp->printInFile(*classOutFile);
                //cout<<"loop er vitore"<<endl;
                prev = temp;
                temp = temp->get_next();
            }
            if(prev!=NULL)
                *classOutFile << endl;
           
        }
           // *classOutFile << endl;
    }
};

class Symbol_Table
{
private:
    Scope_Table *currentScopeTable;
    ofstream *classOutFile;
    int serialNo;
    bool isDeleted;

public:
    // will create a main scope table when a symbol table class is going to be created
    Symbol_Table(int size, ofstream &outFile)
    {
        currentScopeTable = new Scope_Table(1, size, NULL, outFile);
        this->serialNo = 1;
        this->isDeleted = false;
        this->classOutFile = &outFile;
        *classOutFile << "\tScopeTable# " << currentScopeTable->get_scope_id() << " created" << endl;
    }

    ~Symbol_Table()
    {

        // Start deleting from the head of the list
        Scope_Table *currentScope = currentScopeTable;
        while (currentScope != nullptr)
        {
           // *classOutFile << "\tScopeTable# " << currentScope->get_scope_id() << " deleted" << endl;
            Scope_Table *temp = currentScope;
            currentScope = currentScope->get_parentScope();
            delete temp;

        }
        //cout<<"destructor of symbol table called"<<endl;
        
    }

    Scope_Table *get_current_scope()
    {
        return currentScopeTable;
    }

    void enter_scope(ofstream &outFile)
    {
        // if (isDeleted)
        //     serialNo++; //it will increase the last number when a scope is deleted
        // else
        //     serialNo = 1;   //it will create a new scope table with 1.1

        // isDeleted = false;

        // string parentId = currentScopeTable->get_scope_id();
        // string scopeId = parentId + "." + to_string(serialNo);
         serialNo++;

        Scope_Table *newScope = new Scope_Table(serialNo, currentScopeTable->get_size(), currentScopeTable, outFile);
        cout<<newScope->get_scope_id()<<endl;
        currentScopeTable = newScope;
       // *classOutFile << "\tScopeTable# " << scopeId << " created" << endl;
    }

    void exit_scope()
    {
        if (currentScopeTable->get_parentScope() == nullptr)
        {
            *classOutFile << "\tScopeTable# " << currentScopeTable->get_scope_id() << " cannot be deleted" << endl;
            return;
        }

        // string scopeId = currentScopeTable->get_scope_id();
        // serialNo = stoi(scopeId.substr(scopeId.find_last_of(".") + 1, scopeId.length() - 1));
        Scope_Table *parentScope = currentScopeTable->get_parentScope();
        delete currentScopeTable;
        //isDeleted = true;
        currentScopeTable = parentScope;
        //*classOutFile << "\tScopeTable# " << scopeId << " deleted" << endl;
    }

    bool insert(string name, string type)
    {
        return currentScopeTable->insert(name, type);
    }

    bool insert(Symbol_Info* symbol_info)
    {
        return currentScopeTable->insert(symbol_info);
    }

    bool remove(string name)
    {
        return currentScopeTable->delete_symbol(name);
    }

    Symbol_Info *lookup(string name)
    {
        Scope_Table *temp = currentScopeTable;
        while (temp != nullptr)
        {
            Symbol_Info *symbol = temp->lookup(name);
            if (symbol != nullptr)
                return symbol;
            temp = temp->get_parentScope();
        }
        return nullptr;
    }

    void print_current_scope()
    {
        currentScopeTable->print();
    }

    void print_current_scope_in_file()
    {
        currentScopeTable->printInFile();
    }

    void print_all_scope()
    {
        Scope_Table *temp = currentScopeTable;
        while (temp != nullptr)
        {
            temp->print();
            temp = temp->get_parentScope();
        }
    }
    void print_all_scope_in_file()
    {
        Scope_Table *temp = currentScopeTable;
        //cout<<"Vai"<<endl;
        while (temp != nullptr)
        {
            temp->printInFile();
            temp = temp->get_parentScope();
        }
    }

};

/*
int main()
{
    ifstream inFile;
    ofstream outFile;

    inFile.open("input.txt");
    if (!inFile.is_open())
    {
        cout << "Error in opening the input file" << endl;
        return 0;
    }

    outFile.open("output.txt");
    if (!outFile.is_open())
    {
        cout << "Error in opening the output file" << endl;
    }

    int numberOfBuckets;
    inFile >> numberOfBuckets;

    inFile.ignore();

    {

        Symbol_Table symbolTable(numberOfBuckets, outFile);

        string line;
        int commandNumber = 1;

        while (getline(inFile, line))
        {
            istringstream iss(line);
            // cout << "commandnumber" << commandNumber << endl;
            outFile << "Cmd " << commandNumber++ << ": " << line << endl;

            string command;
            iss >> command;

            if (command == "I")
            {
                string name, type;
                if (!(iss >> name >> type) || !iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command I" << endl;
                    continue;
                }

                bool result = symbolTable.insert(name, type);
                if (!result)
                    outFile << "\t'" << name << "' already exists in the current ScopeTable# " << symbolTable.get_current_scope()->get_scope_id() << endl;
            }

            else if (command == "L")
            {
                string name;
                if (!(iss >> name) || !iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command L" << endl;
                    continue;
                }

                Symbol_Info *symbol = symbolTable.lookup(name);
                if (symbol == nullptr)
                    outFile << "\t'" << name << "' not found in any of the ScopeTables" << endl;
            }

            else if (command == "D")
            {
                string name;
                if (!(iss >> name) || !iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command D" << endl;
                    continue;
                }

                bool result = symbolTable.remove(name);
            }

            else if (command == "P")
            {
                string scope;
                if (!(iss >> scope) || !iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command P" << endl;
                    continue;
                }

                if (scope == "A")
                    symbolTable.print_all_scope_in_file();
                else if (scope == "C")
                    symbolTable.print_current_scope_in_file();
                else
                    outFile << "\tInvalid argument for the command P" << endl;
            }

            else if (command == "S")
            {
                // Check for extra arugments
                if (!iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command S" << endl;
                    continue;
                }
                symbolTable.enter_scope(outFile);
            }

            else if (command == "E")
            {
                // Check for extra arugments
                if (!iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command E" << endl;
                    continue;
                }
                symbolTable.exit_scope();
            }

            else if (command == "Q")
            {
                // Check for extra arugments
                if (!iss.eof())
                {
                    outFile << "\tWrong number of arugments for the command Q" << endl;
                    continue;
                }
                break;
            }
            else
                outFile << "\tWrong command" << endl;
        }
    }

    cout << "work done" << endl;

    inFile.close();
    outFile.close();

    return 0;
}
*/