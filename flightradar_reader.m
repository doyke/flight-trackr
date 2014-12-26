function [found, immat, airline, category] = flightradar_reader(adresse)
    
    found = 0;
    immat = [];
    airline = [];
    category = [];
    
    try
        data = loadjson(urlread(['http://www.flightradar24.com/data/_ajaxcalls/autocomplete_airplanes.php?&term=', adresse]));

        if (~isempty(data))
            found = 1;
            struct = data{1};
            immat = struct.id;
            label = struct.label;

            separator = strfind(label, ' - ');
            airline = label(separator(2)+3:separator(3)-1);

            category = label(separator(3)+3:end);
            separator_category = strfind(category, ' (');
            category = category(1:separator_category-1);
        end
    catch
    end
end

function data = loadjson(fname,varargin)
    global pos inStr len  esc index_esc len_esc isoct arraytoken

    if(regexp(fname,'[\{\}\]\[]','once'))
        string=fname;
    elseif(exist(fname,'file'))
        fid = fopen(fname,'rb');
        string = fread(fid,inf,'uint8=>char')';
        fclose(fid);
    else
       error('input file does not exist');
    end

    pos = 1;
    len = length(string);
    inStr = string;
    isoct = exist('OCTAVE_VERSION','builtin');
    arraytoken = find(inStr=='[' | inStr==']' | inStr=='"');
    jstr = regexprep(inStr,'\\\\','  ');
    escquote = regexp(jstr,'\\"');
    arraytoken = sort([arraytoken escquote]);

    esc = find(inStr=='"' | inStr=='\' );
    index_esc = 1; len_esc = length(esc);

    opt=varargin2struct(varargin{:});
    jsoncount = 1;
    while pos <= len
        switch(next_char)
            case '{'
                data{jsoncount} = parse_object(opt);
            case '['
                data{jsoncount} = parse_array(opt);
            otherwise
                error_pos('Outer level structure must be an object or an array');
        end
    jsoncount = jsoncount+1;
    end

    jsoncount=length(data);
    if(jsoncount==1 && iscell(data))
        data=data{1};
    end

    if(~isempty(data))
        if(isstruct(data)) % data can be a struct array
            data=jstruct2array(data);
        elseif(iscell(data))
            data=jcell2array(data);
        end
    end
end

function newdata=jcell2array(data)
    len = length(data);
    newdata = data;
    for i = 1:len
        if(isstruct(data{i}))
            newdata{i}=jstruct2array(data{i});
        elseif(iscell(data{i}))
            newdata{i}=jcell2array(data{i});
        end
    end
end

function newdata=jstruct2array(data)
    m1 = 'x0x5F_ArrayType_';
    m2 = 'x0x5F_ArrayData_';
    m3 = 'x0x5F_ArrayIsComplex_';
    m4 = 'x0x5F_ArrayIsSparse_';
    m5 = 'x0x5F_ArraySize_';
    
    fn = fieldnames(data);
    newdata=data;
    len=length(data);
    for i=1:length(fn)
        for j=1:len
            if(isstruct(data(j).(fn{i})))
                newdata(j).(fn{i}) = jstruct2array(data(j).(fn{i}));
            end
        end
    end
    if(sum(strncmp(m1,fn,length(m1))) && sum(strncmp(m2,fn,length(m2))))
        newdata=cell(len,1);
        for j=1:len
            ndata=cast(data(j).x0x5F_ArrayData_,data(j).x0x5F_ArrayType_);
            iscpx=0;
            if(sum(strncmp(m3,fn,length(m3))))
                if(data(j).x0x5F_ArrayIsComplex_)
                    iscpx=1;
                end
            end
            if(sum(strncmp(m4,fn,length(m4))))
                if(data(j).x0x5F_ArrayIsSparse_)
                    if(sum(strncmp(m5,fn,length(m5))))
                        dim=data(j).x0x5F_ArraySize_;
                        if(iscpx && size(ndata,2)==4-any(dim==1))
                            ndata(:,end-1)=complex(ndata(:,end-1),ndata(:,end));
                        end
                        if isempty(ndata)
                            ndata=sparse(dim(1),prod(dim(2:end)));
                        elseif dim(1)==1
                            ndata=sparse(1,ndata(:,1),ndata(:,2),dim(1),prod(dim(2:end)));
                        elseif dim(2)==1
                            ndata=sparse(ndata(:,1),1,ndata(:,2),dim(1),prod(dim(2:end)));
                        else
                            ndata=sparse(ndata(:,1),ndata(:,2),ndata(:,3),dim(1),prod(dim(2:end)));
                        end
                    else
                        if(iscpx && size(ndata,2)==4)
                            ndata(:,3)=complex(ndata(:,3),ndata(:,4));
                        end
                        ndata=sparse(ndata(:,1),ndata(:,2),ndata(:,3));
                    end
                end
            elseif(sum(strncmp(m5,fn,length(m5))))
                if(iscpx && size(ndata,2)==2)
                    ndata=complex(ndata(:,1),ndata(:,2));
                end
                ndata=reshape(ndata(:),data(j).x0x5F_ArraySize_);
            end
            newdata{j}=ndata;
        end
        if(len==1)
            newdata=newdata{1};
        end
    end
end

function object = parse_object(varargin)
    parse_char('{');
    object = [];
    if next_char ~= '}'
        while 1
            str = parseStr(varargin{:});
            if isempty(str)
                error_pos('Name of value at position %d cannot be empty');
            end
            parse_char(':');
            val = parse_value(varargin{:});
            eval( sprintf( 'object.%s  = val;', valid_field(str) ) );
            if next_char == '}'
                break;
            end
            parse_char(',');
        end
    end
    parse_char('}');
end

function object = parse_array(varargin)
    global pos inStr isoct
    parse_char('[');
    object = cell(0, 1);
    dim2=[];
    if next_char ~= ']'
        [endpos, e1l, e1r, maxlevel]=matching_bracket(inStr,pos);
        arraystr=['[' inStr(pos:endpos)];
        arraystr=regexprep(arraystr,'"_NaN_"','NaN');
        arraystr=regexprep(arraystr,'"([-+]*)_Inf_"','$1Inf');
        arraystr(arraystr==sprintf('\n'))=[];
        arraystr(arraystr==sprintf('\r'))=[];
        if(~isempty(e1l) && ~isempty(e1r))
            astr=inStr((e1l+1):(e1r-1));
            astr=regexprep(astr,'"_NaN_"','NaN');
            astr=regexprep(astr,'"([-+]*)_Inf_"','$1Inf');
            astr(astr==sprintf('\n'))=[];
            astr(astr==sprintf('\r'))=[];
            astr(astr==' ')='';
            if(isempty(find(astr=='[', 1)))
                dim2=length(sscanf(astr,'%f,',[1 inf]));
            end
        else
            astr=arraystr(2:end-1);
            astr(astr==' ')='';
            [obj, count, errmsg, nextidx]=sscanf(astr,'%f,',[1,inf]);
            if(nextidx>=length(astr)-1)
                object=obj;
                pos=endpos;
                parse_char(']');
                return;
            end
        end
        if(~isempty(dim2))
            astr=arraystr;
            astr(astr=='[')='';
            astr(astr==']')='';
            astr(astr==' ')='';
            [obj, count, errmsg, nextidx]=sscanf(astr,'%f,',inf);
            if(nextidx>=length(astr)-1)
                object=reshape(obj,dim2,numel(obj)/dim2)';
                pos=endpos;
                parse_char(']');
                return;
            end
        end
        arraystr=regexprep(arraystr,'\]\s*,','];');
        try
           if(isoct && regexp(arraystr,'"','once'))
                error('Octave eval can produce empty cells for JSON-like input');
           end
           object=eval(arraystr);
           pos=endpos;
        catch
         while 1
            val = parse_value(varargin{:});
            object{end+1} = val;
            if next_char == ']'
                break;
            end
            parse_char(',');
         end
        end
    end
    if(jsonopt('SimplifyCell',0,varargin{:})==1)
      try
        oldobj=object;
        object=cell2mat(object')';
        if(iscell(oldobj) && isstruct(object) && numel(object)>1 && jsonopt('SimplifyCellArray',1,varargin{:})==0)
            object=oldobj;
        elseif(size(object,1)>1 && ndims(object)==2)
            object=object';
        end
      catch
      end
    end
    parse_char(']');
end

function parse_char(c)
    global pos inStr len
    skip_whitespace;
    if pos > len || inStr(pos) ~= c
        error_pos(sprintf('Expected %c at position %%d', c));
    else
        pos = pos + 1;
        skip_whitespace;
    end
end

function c = next_char
    global pos inStr len
    skip_whitespace;
    if pos > len
        c = [];
    else
        c = inStr(pos);
    end
end

function skip_whitespace
    global pos inStr len
    while pos <= len && isspace(inStr(pos))
        pos = pos + 1;
    end
end

function str = parseStr(varargin)
    global pos inStr len  esc index_esc len_esc
 % len, ns = length(inStr), keyboard
    if inStr(pos) ~= '"'
        error_pos('String starting with " expected at position %d');
    else
        pos = pos + 1;
    end
    str = '';
    while pos <= len
        while index_esc <= len_esc && esc(index_esc) < pos
            index_esc = index_esc + 1;
        end
        if index_esc > len_esc
            str = [str inStr(pos:len)];
            pos = len + 1;
            break;
        else
            str = [str inStr(pos:esc(index_esc)-1)];
            pos = esc(index_esc);
        end
        nstr = length(str); switch inStr(pos)
            case '"'
                pos = pos + 1;
                if(~isempty(str))
                    if(strcmp(str,'_Inf_'))
                        str=Inf;
                    elseif(strcmp(str,'-_Inf_'))
                        str=-Inf;
                    elseif(strcmp(str,'_NaN_'))
                        str=NaN;
                    end
                end
                return;
            case '\'
                if pos+1 > len
                    error_pos('End of file reached right after escape character');
                end
                pos = pos + 1;
                switch inStr(pos)
                    case {'"' '\' '/'}
                        str(nstr+1) = inStr(pos);
                        pos = pos + 1;
                    case {'b' 'f' 'n' 'r' 't'}
                        str(nstr+1) = sprintf(['\' inStr(pos)]);
                        pos = pos + 1;
                    case 'u'
                        if pos+4 > len
                            error_pos('End of file reached in escaped unicode character');
                        end
                        str(nstr+(1:6)) = inStr(pos-1:pos+4);
                        pos = pos + 5;
                end
            otherwise % should never happen
                str(nstr+1) = inStr(pos), keyboard
                pos = pos + 1;
        end
    end
    error_pos('End of file while expecting end of inStr');
end

function num = parse_number(varargin)
    global pos inStr len isoct
    currstr=inStr(pos:end);
    numstr=0;
    if(isoct~=0)
        numstr=regexp(currstr,'^\s*-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+\-]?\d+)?','end');
        [num, one] = sscanf(currstr, '%f', 1);
        delta=numstr+1;
    else
        [num, one, err, delta] = sscanf(currstr, '%f', 1);
        if ~isempty(err)
            error_pos('Error reading number at position %d');
        end
    end
    pos = pos + delta-1;
end

function val = parse_value(varargin)
    global pos inStr len
    true = 1; false = 0;
    m6 = 'x0x5F_ArrayType_';
    
    switch(inStr(pos))
        case '"'
            val = parseStr(varargin{:});
            return;
        case '['
            val = parse_array(varargin{:});
            return;
        case '{'
            val = parse_object(varargin{:});
            if isstruct(val)
                if(sum(strncmp(m6,fieldnames(val), length(m6))))
                    val=jstruct2array(val);
                end
            elseif isempty(val)
                val = struct;
            end
            return;
        case {'-','0','1','2','3','4','5','6','7','8','9'}
            val = parse_number(varargin{:});
            return;
        case 't'
            if pos+3 <= len && strcmpi(inStr(pos:pos+3), 'true')
                val = true;
                pos = pos + 4;
                return;
            end
        case 'f'
            if pos+4 <= len && strcmpi(inStr(pos:pos+4), 'false')
                val = false;
                pos = pos + 5;
                return;
            end
        case 'n'
            if pos+3 <= len && strcmpi(inStr(pos:pos+3), 'null')
                val = [];
                pos = pos + 4;
                return;
            end
    end
    error_pos('Value expected at position %d');
end

function error_pos(msg)
    global pos inStr len
    poShow = max(min([pos-15 pos-1 pos pos+20],len),1);
    if poShow(3) == poShow(2)
        poShow(3:4) = poShow(2)+[0 -1];  % display nothing after
    end
    msg = [sprintf(msg, pos) ': ' ...
    inStr(poShow(1):poShow(2)) '<error>' inStr(poShow(3):poShow(4)) ];
    error( ['JSONparser:invalidFormat: ' msg] );
end

function str = valid_field(str)
    global isoct
    pos=regexp(str,'^[^A-Za-z]','once');
    if(~isempty(pos))
        if(~isoct)
            str=regexprep(str,'^([^A-Za-z])','x0x${sprintf(''%X'',unicode2native($1))}_','once');
        else
            str=sprintf('x0x%X_%s',char(str(1)),str(2:end));
        end
    end
    if(isempty(regexp(str,'[^0-9A-Za-z_]', 'once' ))) return;  end
    if(~isoct)
        str=regexprep(str,'([^0-9A-Za-z_])','_0x${sprintf(''%X'',unicode2native($1))}_');
    else
        pos=regexp(str,'[^0-9A-Za-z_]');
        if(isempty(pos)) return; end
        str0=str;
        pos0=[0 pos(:)' length(str)];
        str='';
        for i=1:length(pos)
            str=[str str0(pos0(i)+1:pos(i)-1) sprintf('_0x%X_',str0(pos(i)))];
        end
        if(pos(end)~=length(str))
            str=[str str0(pos0(end-1)+1:pos0(end))];
        end
    end
end

function endpos = matching_quote(str,pos)
    len=length(str);
    while(pos<len)
        if(str(pos)=='"')
            if(~(pos>1 && str(pos-1)=='\'))
                endpos=pos;
                return;
            end        
        end
        pos=pos+1;
    end
    error('unmatched quotation mark');
end

function [endpos, e1l, e1r, maxlevel] = matching_bracket(str,pos)
    global arraytoken
    level=1;
    maxlevel=level;
    endpos=0;
    bpos=arraytoken(arraytoken>=pos);
    tokens=str(bpos);
    len=length(tokens);
    pos=1;
    e1l=[];
    e1r=[];
    while(pos<=len)
        c=tokens(pos);
        if(c==']')
            level=level-1;
            if(isempty(e1r)) e1r=bpos(pos); end
            if(level==0)
                endpos=bpos(pos);
                return
            end
        end
        if(c=='[')
            if(isempty(e1l)) e1l=bpos(pos); end
            level=level+1;
            maxlevel=max(maxlevel,level);
        end
        if(c=='"')
            pos=matching_quote(tokens,pos+1);
        end
        pos=pos+1;
    end
    if(endpos==0) 
        error('unmatched "]"');
    end
end

function val=jsonopt(key,default,varargin)
    val=default;
    if(nargin<=2)
        return;
    end
    opt=varargin{1};
    if(isstruct(opt) && isfield(opt,key))
        val=getfield(opt,key);
    end
end

function opt=varargin2struct(varargin)
    len=length(varargin);
    opt=struct;
    if(len==0)
        return;
    end
    i=1;
    while(i<=len)
        if(isstruct(varargin{i}))
            opt=mergestruct(opt,varargin{i});
        elseif(ischar(varargin{i}) && i<len)
            opt.(varargin{i}) = varargin{i+1};
            i=i+1;
        else
            error('input must be in the form of ...,''name'',value,... pairs or structs');
        end
        i=i+1;
    end
end