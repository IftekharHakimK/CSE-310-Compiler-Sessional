#include<bits/stdc++.h>
#define ll long long
#define dbg(x) cout<<#x<<"-->"<<x<<endl;
using namespace std;

int hashFunction(string s,int m)
{
    int ans=0;
    for(char u:s)
    {
        ans=(ans+u)%m;
    }
    return ans;
}

class SymbolInfo
{
    string name,type;
    SymbolInfo * next;
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
    void printFrom()
    {
        cout<<" < "<<name<<" : "<<type<<" >";
        if(next)
            next->printFrom();
        return;
    }
};

class ScopeTable
{
    int N;
    SymbolInfo ** table;
    int (*getHash)(string,int);
    string id;
    ScopeTable * parent;
    int child;
public:
    ScopeTable(int _N, int (*_getHash)(string,int),string _id,ScopeTable * _parent)
    {
        N=_N;
        table=new SymbolInfo*[N];
        for(int i=0; i<N; i++)
            table[i]=NULL;
        getHash=_getHash;
        id=_id;
        parent=_parent;
        child=0;
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
        cout<<"Deleted ScopeTable # "<<id<<'\n';
        delete[] table;
    }

    bool Insert(SymbolInfo * temp)
    {
        int idx=getHash(temp->getName(),N);
        if(table[idx]==NULL)
        {
            table[idx]=temp;
            cout<<"Inserted in ScopeTable # "<<id<<" at position "<<idx<<','<<0<<'\n';
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
                    cout<<"Inserted in ScopeTable # "<<id<<" at position "<<idx<<','<<cnt<<'\n';
                    break;
                }

                if(now->equals(temp->getName()))
                {
                    cout<<"Element already exits in current ScopeTable\n";
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
                cout<<"Deleted entry "<<idx<<','<<cnt<<" from current ScopeTable\n";
                return true;
            }
            last=now;
            now=now->getNext();
            cnt++;
        }
        cout<<"Not found in current ScopeTable\n";
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
                cout<<"Found in ScopeTable # "<<id<<" at position "<<idx<<','<<cnt<<'\n';
                return now;
            }
            now=now->getNext();
            cnt++;
        }
        return NULL;
    }
    void Print()
    {
        cout<<"ScopeTable # "<<id<<'\n';
        for(int i=0;i<N;i++)
        {
            cout<<i<<" --> ";
            if(table[i])
                table[i]->printFrom();
            cout<<'\n';
        }
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

class SymbolTable
{
    ScopeTable * current;
    int n;
public:
    SymbolTable(int _n)
    {
        n=_n;
        current=new ScopeTable(n,hashFunction,"1",NULL);
        cout<<"ScopeTable # "<<1<<" instantiated\n";
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
    void EnterScope()
    {
        if(current==NULL)
            return;
        current->addChild();
        string nxtID=current->getID();
        nxtID+=".";
        nxtID+=toString(current->getChild());
        ScopeTable * temp=new ScopeTable(n,hashFunction,nxtID,current);
        current=temp;
        cout<<"New ScopeTable # "<<nxtID<<" created\n";
        return;
    }
    void ExitScope()
    {
        if(current==NULL)
            return;
        ScopeTable * parent=current->getParent();
        cout<<"Exited ScopeTable # "<<current->getID()<<'\n';
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
        SymbolInfo * temp = current->fullLookup(name);
        if(temp==NULL)
            cout<<"Not found\n";
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
};


int main()
{
    //cout<<"hello"<<endl;
    freopen("input.txt","r",stdin);
    freopen("out.txt","w",stdout);

    
    int n;
    cin>>n;
    SymbolTable * st = new SymbolTable(n);
    char c;
    while(cin>>c)
    {
        cout<<'\n'<<c<<' ';
        if(c=='I')
        {
            string name, type;
            cin>>name>>type;
            cout<<name<<' '<<type<<'\n';
            SymbolInfo * temp = new SymbolInfo(name,type);
            st->Insert(temp);
        }
        else if(c=='L')
        {
            string name;
            cin>>name;
            cout<<name<<'\n';
            st->Lookup(name);
        }
        else if(c=='D')
        {
            string name;
            cin>>name;
            cout<<name<<'\n';
            st->Remove(name);
        }
        else if(c=='P')
        {
            char ac;
            cin>>ac;
            cout<<ac<<'\n';
            if(ac=='A')
                st->printAll();
            else if(ac=='C')
                st->printCurrent();
        }
        else if(c=='S')
        {
            cout<<'\n';
            st->EnterScope();
        }
        else if(c=='E')
        {
            cout<<'\n';
            st->ExitScope();
        }
        cout<<'\n';
    }
    delete st;
}
