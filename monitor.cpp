#include <iostream>
#include <cassert>
#include <cstdio>
#include <unistd.h>

#include <sstream>
#include <cctype>

#include <vector>
#include <map>

using namespace std;

const string WHITESPACE = " \n\r\t\f\v";
string ltrim(const string& s) {
    size_t start = s.find_first_not_of(WHITESPACE);
    return (start == string::npos) ? "" : s.substr(start);
}
string rtrim(const string& s) {
    size_t end = s.find_last_not_of(WHITESPACE);
    return (end == string::npos) ? "" : s.substr(0, end + 1);
}
string trim(const string& s) { return rtrim(ltrim(s)); }

void split_comma(string &s, vector<string> &l);
void sort_names(vector<string> &l, vector<int> &order, int &num);
int max_len(vector<string> &l);

int main(int argc,char *argv[]) {
    string name_line, value_line;
    getline(cin, name_line);
    // cout<<name_line<<endl;

    int num; int name_length_max;
    vector<int> orders;
    vector<string> names, values;
    vector<double> raw_values;

    split_comma(name_line, names);
    num = names.size();
    sort_names(names, orders, num);
    name_length_max = max_len(names);

    for(int i=0;i<num;++i) {
        int space_num = name_length_max + 2 - names[orders[i]].size();
        cout<<names[orders[i]];
        for(int j=0;j<space_num;++j) cout<<" ";
        cout<<"|  "<<endl;
    }
    // cout<<num<<endl;
    // for(int i=0;i<num;++i) cout<<" "<<endl;
    cout<<"\x1b[100D"<<"\x1b["<<num<<"A"<<flush;
    // ANSI Escape sequences http://ascii-table.com/ansi-escape-sequences.php
    // https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#progress-indicator

    while(getline(cin, value_line)) {
        // cout<<"\x1b[1000D"<<value_line<<flush;
        split_comma(value_line, values);
        assert(values.size() == num);

        for(int i=0;i<names.size();++i) {
            cout<<"\x1b["<<name_length_max + 4<<"C"<<flush;
            cout<<values[orders[i]]<<endl;
        }
        // cout<<num<<"=="<<endl;
        cout<<"\x1b[100D"<<"\x1b["<<num<<"A"<<flush;
        usleep(500000); // sleep(1); https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/usleep.3.html
    }
    cout<<endl;

    return 0;
}

void split_comma(string &s, vector<string> &l) {
    l.clear();
    stringstream s_stream(s);
    while(s_stream.good()) {
        string w;
        getline(s_stream, w, ','); //get first string delimited by comma
        w=trim(w);
        if(!w.empty())
            l.push_back(w);
   }
}

void sort_names(vector<string> &l, vector<int> &order, int &num) {
    vector< pair<string, int> > l_id;
    for(int i=0;i<num;++i) l_id.push_back(make_pair(l[i], i));
    sort(l_id.begin(), l_id.end());

    order.clear();
    for(int i=0;i<num;++i) order.push_back(l_id[i].second);
}

int max_len(vector<string> &l) {
    int res = 0;
    for(int i=0;i<l.size();++i)
        if(l[i].size() > res)
            res = l[i].size();
    return res;
}





/*
    cout << "\r%1"<<flush;
    sleep(1);
    cout << "\r%2"<<flush;
    sleep(1);
    cout << "\r%3"<<flush;
    cout << endl;
*/