%{
To do python querying from with Matlab, we would have to: 

%(1) call:

pyversion /Users/mark/anaconda/bin/python
sys = py.importlib.import_module('sys');
sys.path.append('/Users/mark/Code/')
sys.path.append('/Users/mark/Code/docdb/')
sys.path.append('/Users/mark/MyCode/mlPython/')
dbi = py.vm_tools.docdb.getclient(pyargs('dbname','strfdb-ml2'));

M = dbi.query_documents(pyargs('type','fMRI_DataSet');

% and format any non-string / integer arguments manually, thus:

M = dbi.query_documents(pyargs('type','FeatureSpace','ppseq',py.list({'preprocColorSpace',py.list({1}),<etc>})));

% This would necessarily involve a shit-ton of special cases, and thus
% bugs. This is not an elegant solution.
%}