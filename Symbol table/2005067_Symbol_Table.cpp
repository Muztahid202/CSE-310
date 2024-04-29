#include <iostream>
#include <cstring>
#include <fstream>
#include <sstream>

using namespace std;

class Symbol_Info
{
private:
    string name;
    string type;
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

    ~Symbol_Info()
    {
        cout << "destructor called" << endl;
        
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

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    Symbol_Info *get_next()
    {
        return this->next;
    }

    void set_next(Symbol_Info *next)
    {
        this->next = next;
    }

    void print()
    {
        cout << "(" << this->name << "," << this->type << ")";
    }

    void printInFile()
    {
        *classOutFile << " --> (" << this->name << "," << this->type << ")";
    }
};

class Scope_Table
{
private:
    Symbol_Info **table;
    Scope_Table *parentScope;
    ofstream *classOutFile;
    string scope_id;
    int size; // no of buckets
public:
    Scope_Table(string scope_id, int size, Scope_Table *parentScope, ofstream &outFile)
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
        cout << "destructor of scopetable called" << endl;
        
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

    string get_scope_id()
    {
        return this->scope_id;
    }

    void set_scope_id(string scope_id)
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
            *classOutFile << "\tInserted  at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
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
            *classOutFile << "\tInserted  at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
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
                *classOutFile << "\t'" << temp->get_name() << "' found at position <" << (index + 1) << ", " << order << "> of ScopeTable# " << scope_id << endl;
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
            *classOutFile << "\tNot found in the current ScopeTable# " << scope_id << endl;
            return false;
        }
        else if (temp->get_name() == name)
        {
            table[index] = temp->get_next();
            temp->set_next(NULL);
            delete temp;
            *classOutFile << "\tDeleted "<< "'" << name << "'"<< " from position "<< "<" << (index + 1) << ", " << order << ">"<< " of ScopeTable# " << scope_id << endl;
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
                    *classOutFile << "\tDeleted "<< "'" << name << "'"<< " from position "<< "<" << (index + 1) << ", " << order << ">"<< " of ScopeTable# " << scope_id << endl;
                    return true;
                }
                temp = temp->get_next();
            }
            *classOutFile << "\tNot found in the current ScopeTable# " << scope_id << endl;
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
        for (int i = 0; i < size; i++)
        {
            *classOutFile << "\t" << i + 1;
            Symbol_Info *temp = table[i];
            while (temp != NULL)
            {
                temp->printInFile();
                temp = temp->get_next();
            }
            *classOutFile << endl;
        }
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
        currentScopeTable = new Scope_Table("1", size, NULL, outFile);
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
            *classOutFile << "\tScopeTable# " << currentScope->get_scope_id() << " deleted" << endl;
            Scope_Table *temp = currentScope;
            currentScope = currentScope->get_parentScope();
            delete temp;

        }
        
    }

    Scope_Table *get_current_scope()
    {
        return currentScopeTable;
    }

    void enter_scope(ofstream &outFile)
    {
        if (isDeleted)
            serialNo++; //it will increate the last number when a scope is deleted
        else
            serialNo = 1;   //it will create a new scope table with 1.1

        isDeleted = false;

        string parentId = currentScopeTable->get_scope_id();
        string scopeId = parentId + "." + to_string(serialNo);
        Scope_Table *newScope = new Scope_Table(scopeId, currentScopeTable->get_size(), currentScopeTable, outFile);
        currentScopeTable = newScope;
        *classOutFile << "\tScopeTable# " << scopeId << " created" << endl;
    }

    void exit_scope()
    {
        if (currentScopeTable->get_parentScope() == nullptr)
        {
            *classOutFile << "\tScopeTable# " << currentScopeTable->get_scope_id() << " cannot be deleted" << endl;
            return;
        }

        string scopeId = currentScopeTable->get_scope_id();
        serialNo = stoi(scopeId.substr(scopeId.find_last_of(".") + 1, scopeId.length() - 1));
        Scope_Table *parentScope = currentScopeTable->get_parentScope();
        delete currentScopeTable;
        isDeleted = true;
        currentScopeTable = parentScope;
        *classOutFile << "\tScopeTable# " << scopeId << " deleted" << endl;
    }

    bool insert(string name, string type)
    {
        return currentScopeTable->insert(name, type);
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
        while (temp != nullptr)
        {
            temp->printInFile();
            temp = temp->get_parentScope();
        }
    }

};

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
