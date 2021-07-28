#include<bits/stdc++.h>
#define ll long long
#define dbg(x) logout<<#x<<"-->"<<x<<endl;
using namespace std;

extern ofstream logout;

class SymbolInfo
{
    string name,type;
    SymbolInfo * next;
    string classType;
public:
    SymbolInfo()
    {
        ;
    }
    SymbolInfo(string _name,string _type)
    {
        name=_name;
        type=_type;
        next=NULL;
    }
    ~SymbolInfo()
    {
        name.clear();
        type.clear();
    }
    string getName()
    {
        return name;
    }
    string getType()
    {
        return type;
    }
    bool equals(string _name)
    {
        return name==_name;
    }
    void setNext(SymbolInfo * _next)
    {
        next=_next;
        return;
    }
    SymbolInfo * getNext()
    {
        return next;
    }

    string getClassType()
    {
        return classType;
    }
    void setClassType(string _classType)
    {
        classType=_classType;
    }

    void printFrom()
    {
        logout<<"< "<<name<<" , "<<type<<"> ";
        if(next)
            next->printFrom();
        return;
    }
    virtual void setSpecifier(string _specifier)
    {

    }
    virtual string getSpecifier()
    {
        return "";
    }
    virtual void setLength(string _length)
    {
        return;
    }
    virtual string getLength()
    {
        return "";
    }
    virtual void addParameter(string s)
    {
        return;
    }
    virtual vector<string> getParameterList()
    {

    }
    virtual void setDefined()
    {
        return;
    }
    virtual bool isDefined()
    {
        return 1;
    }
    virtual string getReturnType()
    {
        return "";
    }
};

class variableInfo:public SymbolInfo
{
    string specifier;
public:
    variableInfo(string _name, string _type, string _specifier):SymbolInfo(_name,_type)
    {
        specifier=_specifier;
        setClassType("variable");
    }
    void setSpecifier(string _specifier)
    {
        specifier=_specifier;
    }
    string getSpecifier()
    {
        return specifier;
    }
    void printFrom()
    {
        logout<<"< "<<getName()<<" , "<<getType()<<"> "<<specifier<<' ';
        if(getNext())
            getNext()->printFrom();
        return;
    }
};

class arrayInfo:public SymbolInfo
{
    string length;
    string specifier;
public:
    arrayInfo(string _name,string _type,string _length,string _specifier):SymbolInfo(_name,_type)
    {
        length=_length;
        specifier=_specifier;
        setClassType("array");
    }
    void setSpecifier(string _specifier)
    {
        specifier=_specifier;
    }
    string getSpecifier()
    {
        return specifier;
    }
    void setLength(string _length)
    {
        length=_length;
    }
    string getLength()
    {
        return length;
    }
    void printFrom()
    {
        logout<<"< "<<getName()<<" , "<<getType()<<"> "<<length<<' '<<specifier<<' ';
        if(getNext())
            getNext()->printFrom();
        return;
    }
};
class functionInfo:public SymbolInfo
{
    vector<string>parameterList;
    bool defined=false;
    string returnType;
public:
    functionInfo(string _name,string _type,string _returnType):SymbolInfo(_name,_type)
    {
        returnType=_returnType;
        setClassType("function");
    }
    void addParameter(string s)
    {
        parameterList.push_back(s);
    }
    vector<string> getParameterList()
    {
        return parameterList;
    }
    void setDefined()
    {
        defined=true;
    }
    bool isDefined()
    {
        return defined;
    }
    void printFrom()
    {
        logout<<"< "<<getName()<<" , "<<getType()<<"> "<<returnType;
        for(auto u:parameterList)
            logout<<u<<' ';
        if(getNext())
            getNext()->printFrom();
        return;
    }
    string getReturnType()
    {
        return returnType;
    }
};


class ScopeTable
{
    int N;
    SymbolInfo ** table;
    string id;
    ScopeTable * parent;
    int child;
public:
    ScopeTable(int _N,string _id,ScopeTable * _parent)
    {
        N=_N;
        table=new SymbolInfo*[N];
        for(int i=0; i<N; i++)
            table[i]=NULL;
        id=_id;
        parent=_parent;
        child=0;
        //logout<<" New ScopeTable with id "<<_id<<" created"<<endl;
    }
    ~ScopeTable()
    {
        for(int i=0; i<N; i++)
        {
            if(table[i]!=NULL)
            {
                SymbolInfo * temp=table[i];
                while(temp!=NULL)
                {
                    SymbolInfo * temp2=temp->getNext();
                    delete temp;
                    temp=temp2;
                }
            }
        }
        //logout<<" ScopeTable with id "<<id<<" removed"<<endl;
        //logout<<"Deleted ScopeTable # "<<id<<'\n';
        delete[] table;
    }

    int getHash(string s,int m)
    {
        while(s.back()==' ')
            s.pop_back();
        int ans=0;
        for(char u:s)
        {
            ans=(ans+u)%m;
        }
        return ans;
    }

    bool Insert(SymbolInfo * temp)
    {
        int idx=getHash(temp->getName(),N);
        if(table[idx]==NULL)
        {
            table[idx]=temp;
            //logout<<"Inserted in ScopeTable # "<<id<<" at position "<<idx<<','<<0<<'\n';
        }
        else
        {
            SymbolInfo * now=table[idx];
            SymbolInfo * last=NULL;
            int cnt=0;
            while(true)
            {
                if(now==NULL)
                {
                    now=temp;
                    last->setNext(now);
                    //logout<<"Inserted in ScopeTable # "<<id<<" at position "<<idx<<','<<cnt<<'\n';
                    break;
                }

                if(now->equals(temp->getName()))
                {
                    return false;
                }

                last=now;
                now=now->getNext();
                cnt++;
            }
        }
        return true;
    }

    bool Delete(string name)
    {
        int idx=getHash(name,N);
        SymbolInfo * now = table[idx];
        SymbolInfo * last = NULL;
        int cnt=0;
        while(now!=NULL)
        {
            if(now->equals(name))
            {
                if(last==NULL)
                    table[idx]=now->getNext();
                else
                    last->setNext(now->getNext());
                delete now;
                logout<<"Deleted entry "<<idx<<','<<cnt<<" from current ScopeTable\n";
                return true;
            }
            last=now;
            now=now->getNext();
            cnt++;
        }
        //logout<<"Not found in current ScopeTable\n";
        return false;
    }

    SymbolInfo * Lookup(string name)
    {
        int idx=getHash(name,N);

        SymbolInfo * now=table[idx];
        int cnt=0;
        while(now!=NULL)
        {
            if(now->equals(name))
            {
                //logout<<"Found in ScopeTable # "<<id<<" at position "<<idx<<','<<cnt<<'\n';
                return now;
            }
            now=now->getNext();
            cnt++;
        }
        return NULL;
    }
    void Print()
    {
        logout<<" ScopeTable # "<<id<<'\n';
        for(int i=0; i<N; i++)
        {
            if(table[i]==NULL) continue;
            logout<<' '<<i<<" --> ";
            if(table[i])
                table[i]->printFrom();
            logout<<'\n';
        }
        logout<<'\n';
    }
    int getChild()
    {
        return child;
    }
    void addChild()
    {
        child+=1;
        return;
    }
    string getID()
    {
        return id;
    }
    ScopeTable * getParent()
    {
        return parent;
    }
    SymbolInfo * fullLookup(string name)
    {
        SymbolInfo * temp=Lookup(name);
        if(temp==NULL)
        {
            if(parent==NULL)
            {
                return NULL;
            }
            else
            {
                return parent->fullLookup(name);
            }
        }
        else
            return temp;
    }
    void fullPrint()
    {
        Print();
        if(parent)
            parent->fullPrint();
        return;
    }
};



class SymbolTable
{
    ScopeTable * current;
    int n;
public:
    SymbolTable(int _n)
    {
        n=_n;
        current=new ScopeTable(n,"1",NULL);
    }
    ~SymbolTable()
    {
        while(current!=NULL)
        {
            ScopeTable * parent=current->getParent();
            delete current;
            current=parent;
        }
        n=0;
    }
    string toString(int x)
    {
        string s;
        while(x!=0)
        {
            s+=(char)(x%10+'0');
            x/=10;
        }
        reverse(s.begin(),s.end());
        return s;
    }
    void EnterScope()
    {
        if(current==NULL)
            return;
        current->addChild();
        string nxtID=current->getID();
        nxtID+=".";
        nxtID+=toString(current->getChild());
        ScopeTable * temp=new ScopeTable(n,nxtID,current);
        current=temp;
        //logout<<"New ScopeTable # "<<nxtID<<" created\n";
        return;
    }
    void ExitScope()
    {
        if(current==NULL)
            return;
        ScopeTable * parent=current->getParent();
        //logout<<"Exited ScopeTable # "<<current->getID()<<'\n';
        delete current;
        current=parent;
        return;
    }
    bool Insert(SymbolInfo * temp)
    {
        if(current==NULL)
            return false;
        return current->Insert(temp);
    }
    bool InsertPrev(SymbolInfo * temp)
    {
        if(current==NULL)
            return false;
        ScopeTable * ex = current->getParent();
        if(ex==NULL)
            return false;
        return ex->Insert(temp);
    }

    bool Remove(string name)
    {
        if(current==NULL)
            return false;
        return current->Delete(name);
    }
    SymbolInfo * Lookup(string name)
    {
        if(current==NULL)
            return NULL;
        SymbolInfo * temp = current->Lookup(name);
        return temp;
    }
    SymbolInfo * fullLookup(string name)
    {
        if(current==NULL)
            return NULL;
        SymbolInfo * temp = current->fullLookup(name);
        return temp;
    }
    void printCurrent()
    {
        if(current==NULL)
            return;
        current->Print();
        return;
    }
    void printAll()
    {
        if(current==NULL)
            return;
        current->fullPrint();
        return;
    }
    string curName()
    {
        return current->getID();
    }
    string parentName()
    {
        if(current->getParent()!=NULL)
            return current->getParent()->getID();
        else return "";
    }
};

