function [registre] = update_plots(registre)

    if (~isempty(registre.immatriculation))
        id = registre.immatriculation;
    else
        id = registre.adresse;
    end

    longitudes = registre.trajectoire(1,:);
    latitudes = registre.trajectoire(2,:);
    altitudes = registre.trajectoire(3,:);
    
    longitude = longitudes(end);    % Longitude de l'avion
    latitude = latitudes(end);     % Latitude de l'avion
    altitude = altitudes(end);
    
    if (~isempty(registre.plot1) && ~isempty(registre.plot2) && ~isempty(registre.plot3))
        % on enlève ce qui a déjà été tracé
        delete(registre.plot1);
        delete(registre.plot2);
        delete(registre.plot3);
    end
    
    points = fnplt(cscvn([longitudes;latitudes;altitudes]));
    
    registre.plot1 = plot3(points(1,:),points(2,:), points(3,:), 'b:');
    registre.plot2 = plot3(longitude, latitude,  altitude,'*b', 'MarkerSize', 8);
    registre.plot3 = text(longitude+0.05, latitude, altitude, id,'color','b');
end

function [x,y,sizeval,w,origint,p,tolred] = chckxywp(x,y,nmin,w,p,adjtol)
    if iscell(x)||length(find(size(x)>1))>1
       error(message('SPLINES:CHCKXYWP:Xnotvec')), end

    if ~all(isreal(x))
       x = real(x);
       warning(message('SPLINES:CHCKXYWP:Xnotreal'))
    end
    
    nanx = find(~isfinite(x));
    if ~isempty(nanx)
       x(nanx) = [];
       warning(message('SPLINES:CHCKXYWP:NaNs'))
    end

    n = length(x);
    if nargin>2&&nmin>0, minn = nmin; else minn = 2; end
    if n<minn
       error(message('SPLINES:CHCKXYWP:toofewpoints', sprintf( '%g', minn )))
    end

    tosort = false;
    if any(diff(x)<0), tosort = true; [x,ind] = sort(x); end

    nstart = n+length(nanx);
    sizeval = size(y);
    yn = sizeval(end); sizeval(end) = []; yd = prod(sizeval);
    if length(sizeval)>1
       y = reshape(y,yd,yn);
    else
       if yn==1&&yd==nstart
          yn = yd; y = reshape(y,1,yn); yd = 1; sizeval = yd;
       end
    end
    y = y.'; x = reshape(x,n,1);

    if nargin>2&&~nmin
       switch yn
       case nstart+2, w = y([1 end],:); y([1 end],:) = [];
          if ~all(isfinite(w)),
             error(message('SPLINES:CHCKXYWP:InfY'))
          end
       case nstart, w = [];
       otherwise
          error(message('SPLINES:CHCKXYWP:XdontmatchY', sprintf( '%g', nstart ), sprintf( '%g', yn )))
       end
    else
       if yn~=nstart
          error(message('SPLINES:CHCKXYWP:XdontmatchY', sprintf( '%g', nstart ), sprintf( '%g', yn )))
       end
    end

    nonemptyw = nargin>3&&~isempty(w);
    if nonemptyw
       if length(w)~=nstart
          error(message('SPLINES:CHCKXYWP:weightsdontmatchX', sprintf( '%g', length( w ) ), sprintf( '%g', nstart )))
       else
          w = reshape(w,1,nstart);
       end
    end

    roughnessw = exist('p','var')&&length(p)>1;
    if roughnessw
       if tosort
          warning(message('SPLINES:CHCKXYWP:cantreorderrough'))
          p = p(1);
       else
          if length(p)~=nstart
             error(message('SPLINES:CHCKXYWP:rweightsdontmatchX', sprintf( '%g', nstart )))
          end
       end
    end

    if ~isempty(nanx), y(nanx,:) = []; if nonemptyw, w(nanx) = []; end
       if roughnessw
          p(max(nanx,2)) = [];
       end
    end
    if tosort, y = y(ind,:); if nonemptyw, w = w(ind); end, end

    nany = find(sum(~isfinite(y),2));
    if ~isempty(nany)
       y(nany,:) = []; x(nany) = []; if nonemptyw, w(nany) = []; end
       warning(message('SPLINES:CHCKXYWP:NaNs'))
       n = length(x);
       if n<minn
          error(message('SPLINES:CHCKXYWP:toofewX', sprintf( '%g', minn ))), end
       if roughnessw
          p(max(nany,2)) = [];
       end
    end

    if nargin==3&&nmin, return, end

    if nargin>3&&isempty(w)
       dx = diff(x);
       if any(dx), w = ([dx;0]+[0;dx]).'/2;
       else        w = ones(1,n);
       end
       nonemptyw = ~nonemptyw;
    end

    tolred = 0;
    if ~all(diff(x))
       mults = knt2mlt(x);
       for j=find(diff([mults;0])<0).'
            if nonemptyw
                temp = sum(w(j-mults(j):j));
                if nargin>5
                    tolred = tolred + w(j-mults(j):j)*sum(y(j-mults(j):j,:).^2,2); 
                end
                y(j-mults(j),:) = (w(j-mults(j):j)*y(j-mults(j):j,:))/temp;
                w(j-mults(j)) = temp;

                if nargin>5
                    tolred = tolred - temp*sum(y(j-mults(j),:).^2);
                end
            else
                 y(j-mults(j),:) = mean(y(j-mults(j):j,:),1);
            end
       end

       repeats = find(mults);
       x(repeats) = []; y(repeats,:) = []; if nonemptyw, w(repeats) = []; end
       if roughnessw
          p(max(repeats,2)) = [];
       end
       n = length(x);
       if n<minn, error(message('SPLINES:CHCKXYWP:toofewX', sprintf( '%g', minn ))), end
    end

    if nargin<4, return, end

    origint = [];
    if nonemptyw
        ignorep = find( w <= (1e-13)*max(abs(w)) );
        if ~isempty(ignorep)
            if ignorep(1)==1||ignorep(end)==n, origint = x([1 end]).'; end
            x(ignorep) = []; y(ignorep,:) = []; w(ignorep) = []; 
            if roughnessw
                p(max(ignorep,2)) = [];
            end
            n = length(x);
            if n<minn
                error(message('SPLINES:CHCKXYWP:toofewposW', sprintf( '%g', minn )))
            end
        end
    end
end

function pp = csape(x,y,conds,valconds)
    if nargin<3, conds = [1 1]; end

    if iscell(x)

        m = length(x);
        sizey = size(y);
        if length(sizey) < m
            error(message('SPLINES:CSAPE:toofewdims'))
        end

        if length(sizey) == m
            if issparse(y)
                y = full(y);
            end
            sizey = [1 sizey];
        end

        sizeval = sizey(1:end-m); sizey = [prod(sizeval), sizey(end-m+(1:m))];
        y = reshape(y, sizey); 

        if ~iscell(conds), conds = num2cell(repmat(conds,m,1),2); end

        v = y; sizev = sizey;

        for i=m:-1:1
            [b,v,l,k] = ppbrk(csape1(x{i}, ...
                       reshape(v,prod(sizev(1:m)),sizev(m+1)),conds{i}));
            breaks{i} = b;
            sizev(m+1) = l*k; v = reshape(v,sizev);
            if m>1
                v = permute(v,[1,m+1,2:m]); sizev(2:m+1) = sizev([m+1,2:m]);
            end
        end

        pp = ppmak(breaks, v);
        if length(sizeval)>1, pp = fnchg(pp,'dz',sizeval); end

    else
        if nargin<4
            pp = csape1(x,y,conds);
        else
            pp = csape1(x,y,conds,valconds);
        end
    end
end

function pp = csape1(x,y,conds,valconds)
    [xi,yi,sizeval,endvals] = chckxywp(x,y,0);
    
    if ~isempty(endvals), valconds = endvals.'; end
    
    [yn,yd] = size(yi);
    dd = ones(1,yd);
    dx = diff(xi);
    divdif = diff(yi)./dx(:,dd);

    [n,yd] = size(yi); dd = ones(1,yd);

    valsnotgiven=0;
    if ~exist('valconds','var'), valsnotgiven=1;  valconds = zeros(yd,2); end

    if ischar(conds)
       if     conds(1)=='c', conds = [1 1];
       elseif conds(1)=='n', pp = csapi(x,y); return
       elseif conds(1)=='p', conds = [0 0];
       elseif conds(1)=='s', conds = [2 2];
       elseif conds(1)=='v', conds = [2 2]; valconds = zeros(yd,2);
       else   error(message('SPLINES:CSAPE:unknownends', conds))
       end
    end

    dx = diff(xi); divdif = diff(yi)./dx(:,dd);
    c = spdiags([ [dx(2:n-1,1);0;0] ...
            2*[0;dx(2:n-1,1)+dx(1:n-2,1);0] ...
              [0;0;dx(1:n-2,1)] ], [-1 0 1], n, n);
    b = zeros(n,yd);
    b(2:n-1,:)=3*(dx(2:n-1,dd).*divdif(1:n-2,:)+dx(1:n-2,dd).*divdif(2:n-1,:));
    
    if ~any(conds)
        c(1,1)=1;
        c(1,n)=-1;
    elseif conds(1)==2
        c(1,1:2)=[2 1]; b(1,:)=3*divdif(1,:)-(dx(1)/2)*valconds(:,1).';
    else
        c(1,1:2) = [1 0]; b(1,:) = valconds(:,1).';
        if (valsnotgiven||conds(1) ~= 1)
            b(1,:)=divdif(1,:);
            if n>2
                ddf=(divdif(2,:)-divdif(1,:))/(xi(3)-xi(1));
                b(1,:) = b(1,:)-ddf*dx(1);
            end
            
            if n>3
                ddf2=(divdif(3,:)-divdif(2,:))/(xi(4)-xi(2));
                b(1,:)=b(1,:)+(ddf2-ddf)*(dx(1)*(xi(3)-xi(1)))/(xi(4)-xi(1));
            end
        end
    end
    
    if ~any(conds)
        c(n,1:2)=dx(n-1)*[2 1]; c(n,n-1:n)= c(n,n-1:n)+dx(1)*[1 2];
        b(n,:) = 3*(dx(n-1)*divdif(1,:) + dx(1)*divdif(n-1,:));
    elseif conds(2)==2
        c(n,n-1:n)=[1 2]; b(n,:)=3*divdif(n-1,:)+(dx(n-1)/2)*valconds(:,2).';
    else
        c(n,n-1:n) = [0 1]; b(n,:) = valconds(:,2).';
        if (valsnotgiven||conds(2)~=1)
            b(n,:)=divdif(n-1,:);
            
            if n>2
                ddf=(divdif(n-1,:)-divdif(n-2,:))/(xi(n)-xi(n-2));
                b(n,:) = b(n,:)+ddf*dx(n-1);
            end
            
            if n>3
                ddf2=(divdif(n-2,:)-divdif(n-3,:))/(xi(n-1)-xi(n-3));
                b(n,:)=b(n,:)+(ddf-ddf2)*(dx(n-1)*(xi(n)-xi(n-2)))/(xi(n)-xi(n-3));
            end
        end
    end

    mmdflag = spparms('autommd');
    spparms('autommd',0);
    s=c\b;
    spparms('autommd',mmdflag);

    c4 = (s(1:n-1,:)+s(2:n,:)-2*divdif(1:n-1,:))./dx(:,dd);
    c3 = (divdif(1:n-1,:)-s(1:n-1,:))./dx(:,dd) - c4;
    pp = ppmak(xi.', ...
        reshape([(c4./dx(:,dd)).' c3.' s(1:n-1,:).' yi(1:n-1,:).'],(n-1)*yd,4),yd);
    
    if length(sizeval)>1
        pp = fnchg(pp,'dz',sizeval);
    end
end

function cs = cscvn(points)
    if points(:,1)==points(:,end)  endconds = 'periodic';
    else                           endconds = 'variational';
    end

    if length(points(1,:))==1 dt = 0;
    else dt = sum((diff(points.').^2).');
    end
    
    t = cumsum([0,dt.^(1/4)]);

    if all(dt>0)
        cs = csape(t,points,endconds);
    else
        dtp = find(dt>0);
        if isempty(dtp)
            cs = csape([0 1],points(:,[1 1]),endconds);
        elseif length(dtp)==1
            cs = csape([0 t(dtp+1)],points(:,dtp+[0 1]),endconds);
        else
            dtpbig = find(diff(dtp)>1);
            if isempty(dtpbig)
                temp = dtp(1):(dtp(end)+1); cs = csape(t(temp),points(:,temp),endconds);
            else
                dtpbig = [dtpbig,length(dtp)];
                temp = dtp(1):(dtp(dtpbig(1))+1);
                coefs = ppbrk(csape(t(temp),points(:,temp),'variatonal'),'c');

                for j=2:length(dtpbig)
                    temp = dtp(dtpbig(j-1)+1):(dtp(dtpbig(j))+1);
                    coefs = [coefs;ppbrk(csape(t(temp),points(:,temp),'variational'),'c')];
                end
                cs = ppmak(t([dtp(1) dtp+1]),coefs,length(points(:,1)));
            end
        end
    end
end

function varargout = fnbrk(fn, varargin)
    if nargin>1
        np = max(1,nargout);
        if np <= length(varargin)
            varargout = cell(1,np);
        else
            error(message('SPLINES:FNBRK:moreoutthanin'))
        end
    end

    if ~isstruct(fn)
        switch fn(1)
            case 10, fnform = getString(message('SPLINES:resources:PpformUnivariate'));
            case 11, fnform = getString(message('SPLINES:resources:BformUnivariate'));
            case 12, fnform = getString(message('SPLINES:resources:BBformUnivariate'));
            case 20, fnform = getString(message('SPLINES:resources:PpformTensor'));
            case 21, fnform = getString(message('SPLINES:resources:BformTensor'));
            case 22, fnform = getString(message('SPLINES:resources:BBformBivariate'));
            case 24, fnform = getString(message('SPLINES:resources:PolynomialShiftedPowerForm'));
            case 25, fnform = getString(message('SPLINES:resources:ThinplateSpline'));
            case 40, fnform = getString(message('SPLINES:resources:BlockDiagonalForm'));
            case 41, fnform = getString(message('SPLINES:resources:BlockDiagonalFormSplineVersion'));
            case 94, fnform = ...
                      getString(message('SPLINES:resources:PolynomialNormalizedPowerForm'));
            otherwise
                error(message('SPLINES:FNBRK:unknownform'))
        end
   
        if nargin>1
            switch fn(1)
                case 10, [varargout{:}] = ppbrk(fn,varargin{:});
                case {11,12}, [varargout{:}] = spbrk(fn,varargin{:});
                otherwise
                    error(message('SPLINES:FNBRK:unknownpart', fnform))
            end
        else
            if nargout
                error(message('SPLINES:FNBRK:partneeded'))
            else
                fprintf( '%s\n\n', getString(message('SPLINES:resources:DisplayFunctionInput', fnform)) ) 
                switch fn(1)
                    case 10, ppbrk(fn);
                    case {11,12}, spbrk(fn);
                    otherwise
                        fprintf( '%s\n', getString(message('SPLINES:resources:NotAvailablePartsOfFunction')) )
                end
            end
        end
        return
    end

    switch fn.form(1:2) 
    case 'pp',        ffbrk = @ppbrk;
    case 'rp',        ffbrk = @rpbrk;
    case 'st',        ffbrk = @stbrk;
    case {'B-','BB'}, ffbrk = @spbrk;
    case 'rB',        ffbrk = @rsbrk;
    otherwise
        error(message('SPLINES:FNBRK:unknownform'))
    end

    if nargin>1
        [varargout{:}] = ffbrk(fn,varargin{:});
    else
        if nargout
            error(message('SPLINES:FNBRK:partneeded'))
        else
            fprintf( '%s\n\n', getString(message('SPLINES:resources:DisplayFormInput', fn.form(1:2))) ) 
            ffbrk(fn)
        end
    end
end

function [points,t] = fnplt(f,varargin)
    symbol='';
    interv=[];
    linewidth=[];
    jumps=0;
    
    for j=2:nargin
        arg = varargin{j-1};
        if ~isempty(arg)
            if ischar(arg)
                if arg(1)=='j',
                    jumps = 1;
                else
                    symbol = arg;
                end
            else
                [ignore,d] = size(arg);
                if ignore~=1
                    error(message('SPLINES:FNPLT:wrongarg', num2str( j )))
                end
                if d==1
                    linewidth = arg;
                else
                    interv = arg;
                end
            end
        end
    end

    if ~isstruct(f),
        f = fn2fm(f);
    end

    d = fnbrk(f,'dz');
    
    if length(d)>1,
    	f = fnchg(f,'dim',prod(d));
    end

    switch f.form(1:2)
        case 'st'
            if ~isempty(interv),
                f = stbrk(f,interv);
            else
                interv = stbrk(f,'interv');
            end
            npoints = 51;
            d = stbrk(f,'dim');
            switch fnbrk(f,'var')
                case 1
                    x = linspace(interv{1}(1),interv{1}(2),npoints);
                    v = stval(f,x);
                case 2
                    x = {linspace(interv{1}(1),interv{1}(2),npoints), ...
                        linspace(interv{2}(1),interv{2}(2),npoints)};
                    [xx,yy] = ndgrid(x{1},x{2});
                    v = reshape(stval(f,[xx(:),yy(:)].'),[d,size(xx)]);
                otherwise
                    error(message('SPLINES:FNPLT:atmostbivar'))
            end
        otherwise
            if ~strcmp(f.form([1 2]),'pp')
                givenform = f.form;
                f = fn2fm(f,'pp');
                basicint = ppbrk(f,'interval');
            end

            if ~isempty(interv),
                f = ppbrk(f,interv);
            end

            [breaks,l,d] = ppbrk(f,'b','l','d');
            if iscell(breaks)
                m = length(breaks);
                for i=m:-1:3
                    x{i} = (breaks{i}(1)+breaks{i}(end))/2;
                end
                npoints = 51;
                ii = 1;
                if m>1,
                    ii = [2 1];
                end
                for i=ii
                    x{i}= linspace(breaks{i}(1),breaks{i}(end),npoints);
                end
                v = ppual(f,x);
                if exist('basicint','var')
                    for i=ii
                        temp = find(x{i}<basicint{i}(1)|x{i}>basicint{i}(2));
                        if d==1
                            if ~isempty(temp),
                                v(:,temp,:) = 0;
                            end
                            v = permute(v,[2,1]);
                        else
                            if ~isempty(temp),
                                v(:,:,temp,:) = 0;
                            end
                            v = permute(v,[1,3,2]);
                        end
                    end
                end
            else
                npoints = 101;
                x = [breaks(2:l) linspace(breaks(1),breaks(l+1),npoints)];
                v = ppual(f,x);
                if l>1
                    if jumps
                        tx = breaks(2:l);
                        temp = NaN(d,l-1);
                    else
                        tx = [];
                        temp = zeros(d,0);
                    end
                    x = [breaks(2:l) tx x];
                    v = [ppual(f,breaks(2:l),'left') temp v];
                end
                [x,inx] = sort(x);
                v = v(:,inx);

                if exist('basicint','var')
                    if jumps
                        extrap = NaN(d,1);
                    else
                        extrap = zeros(d,1);

                    end
                    temp = find(x<basicint(1));
                    ltp = length(temp);
                    if ltp
                        x = [x(temp),basicint([1 1]), x(ltp+1:end)];
                        v = [zeros(d,ltp+1),extrap,v(:,ltp+1:end)];
                    end
                    temp = find(x>basicint(2));
                    ltp = length(temp);
                    if ltp
                        x = [x(1:temp(1)-1),basicint([2 2]),x(temp)];
                        v = [v(:,1:temp(1)-1),extrap,zeros(d,ltp+1)];
                    end
                end
            end

            if exist('givenform','var')&&givenform(1)=='r'
                d = d-1;
                sizev = size(v);
                sizev(1) = d;
                v(d+1,v(d+1,:)==0) = 1;
                v = reshape(v(1:d,:)./repmat(v(d+1,:),d,1),sizev);
            end
    end

    if nargout==0
        if iscell(x)
            switch d
                case 1
                    [yy,xx] = meshgrid(x{2},x{1});
                    surf(xx,yy,reshape(v,length(x{1}),length(x{2})))
                case 2
                    v = squeeze(v);
                    roughp = 1+(npoints-1)/5;
                    vv = reshape(cat(1,...
                        permute(v(:,1:5:npoints,:),[3,2,1]),...
                        NaN([1,roughp,2]),...
                        permute(v(:,:,1:5:npoints),[2,3,1]),...
                        NaN([1,roughp,2])), ...
                        [2*roughp*(npoints+1),2]);
                    plot(vv(:,1),vv(:,2))
                case 3
                    v = permute(reshape(v,[3,length(x{1}),length(x{2})]),[2 3 1]);
                    surf(v(:,:,1),v(:,:,2),v(:,:,3))
                otherwise
            end
        else
            if isempty(symbol),
                symbol = '-';
            end
            if isempty(linewidth),
                linewidth = 2;
            end
            switch d
                case 1,
                    plot(x,v,symbol,'LineWidth',linewidth)
                case 2,
                    plot(v(1,:),v(2,:),symbol,'LineWidth',linewidth)
                otherwise
                    plot3(v(1,:),v(2,:),v(3,:),symbol,'LineWidth',linewidth)
            end
        end
    else
        if iscell(x)
            switch d
                case 1
                    [yy,xx] = meshgrid(x{2},x{1});
                    points = {xx,yy,reshape(v,length(x{1}),length(x{2}))};
                    iErrorSecondOutputForVectorValued( nargout );
                case 2
                    [yy,xx] = meshgrid(x{2},x{1});
                    points = {xx,yy,reshape(v,[2,length(x{1}),length(x{2})])};
                    iErrorSecondOutputForVectorValued( nargout );
                case 3
                    points = {squeeze(v(1,:)),squeeze(v(2,:)),squeeze(v(3,:))};
                    t = {x{1:2}};
                otherwise
                    iErrorSecondOutputForVectorValued( nargout );
            end
        else
            if d==1,
                points = [x;v];
                iErrorSecondOutputForVectorValued( nargout );
            else
                t = x;
                points = v(1:min([d,3]),:);
            end
        end
    end
end

function iErrorSecondOutputForVectorValued( numArgOut )
    if numArgOut >= 2
        exception = MException( 'SPLINES:FNPLT:SecondOutputForVectorValued', ...
            'Second output argument only supported for vector-valued F.' );
        throwAsCaller( exception );
    end
end

function varargout = ppbrk(pp,varargin)
    if ~isstruct(pp)
        if pp(1)~=10
            error(message('SPLINES:PPBRK:unknownfn'))
        else
            ppi = pp;
            di=ppi(2);
            li=ppi(3);
            ki=ppi(5+li);

            pp = struct('breaks',reshape(ppi(3+(1:li+1)),1,li+1), ...
                'coefs',reshape(ppi(5+li+(1:di*li*ki)),di*li,ki), ...
                'form','pp', 'dim',di, 'pieces',li, 'order',ki);
        end
    end 

    if ~strcmp(pp.form,'pp')
        error(message('SPLINES:PPBRK:notpp'))
    end
    
    if nargin>1 % we have to hand back one or more parts
        np = max(1,nargout);
        if np>length(varargin)
            error(message('SPLINES:PPBRK:moreoutthanin'))
        end
        varargout = cell(1,np);
        for jp=1:np
            part = varargin{jp};

            if ischar(part)
                if isempty(part)
                    error(message('SPLINES:PPBRK:partemptystr'))
                end
                switch part(1)
                    case 'f',       out1 = [pp.form,'form'];
                    case 'd',       out1 = pp.dim;
                    case {'l','p'}, out1 = pp.pieces;
                    case 'b',       out1 = pp.breaks;
                    case 'o',       out1 = pp.order;
                    case 'c',       out1 = pp.coefs;
                    case 'v',       out1 = length(pp.order);
                    case 'g'
                        if length(pp.dim)>1||pp.dim>1||iscell(pp.order)
                            error(message('SPLINES:PPBRK:onlyuniscalar', part))
                        else
                            k = pp.order;
                            out1 = (pp.coefs(:,k:-1:1).').* ...
                            repmat(cumprod([1 1:k-1].'),1,pp.pieces);
                        end
                    case 'i'
                        if iscell(pp.breaks)
                            for i=length(pp.order):-1:1
                                out1{i} = pp.breaks{i}([1 end]);
                            end
                        else
                            out1 = pp.breaks([1 end]);
                        end
                    otherwise
                        error(message('SPLINES:PPBRK:unknownpart', part))
                end
            elseif isempty(part)
                out1 = pp;
            else
                sizeval = pp.dim;
                if length(sizeval)>1
                    pp.dim = prod(sizeval);
                end
                if iscell(part)
                    [breaks,c,l,k,d] = ppbrk(pp);
                    m = length(breaks);
                    sizec = [d,l.*k];
                    if length(sizec)~=m+1
                        error(message('SPLINES:PPBRK:inconsistentfn')),
                    end
                    for i=m:-1:1
                        dd = prod(sizec(1:m));
                        ppi = ppbrk1(ppmak(breaks{i},reshape(c,dd*l(i),k(i)),dd),...
                        part{i}) ;
                        breaks{i} = ppi.breaks; sizec(m+1) = ppi.pieces*k(i);
                        c = reshape(ppi.coefs,sizec);
                        if m>1
                            c = permute(c,[1,m+1,2:m]);
                            sizec(2:m+1) = sizec([m+1,2:m]);
                        end
                    end
                    out1 = ppmak(breaks,c, sizec);
                else
                    out1 = ppbrk1(pp,part);
                end
                if length(sizeval)>1
                    out1 = fnchg(out1,'dz',sizeval);
                end
            end
            varargout{jp} = out1;
        end
    else
        if nargout==0
            if iscell(pp.breaks)
                disp(pp)
            else
                disp('breaks(1:l+1)')
                disp(pp.breaks)
                disp('coefficients(d*l,k)')
                disp(pp.coefs)
                disp(getString(message('SPLINES:resources:PiecesNumber')))
                disp(pp.pieces)
                disp(getString(message('SPLINES:resources:OrderK')))
                disp(pp.order)
                disp(getString(message('SPLINES:resources:DimensionOfTarget')))
                disp(pp.dim)
            end
        else
            varargout = {pp.breaks, pp.coefs, pp.pieces, pp.order, pp.dim};
        end
    end
end

function pppart = ppbrk1(pp,part)
    if isempty(part)||ischar(part)
        pppart = pp;
        return;
    end
    
    if size(part,2) > 1
        pppart = ppcut(pp,part(1,1:2));
    else
       pppart = pppce(pp,part(1));
    end
end

function ppcut = ppcut(pp,interv)
    xl = interv(1); xr = interv(2);

    if xl>xr
        xl = xr;
        xr = interv(1);
    end
    
    if xl==xr
        warning(message('SPLINES:PPBRK:PPCUT:trivialinterval'))
        ppcut = pp;
        return
    end

    jl=pp.pieces;
    index=find(pp.breaks(2:jl)>xl);

    if (~isempty(index))
        jl=index(1);
    end

    x=xl-pp.breaks(jl);
    di = pp.dim;
    if x ~= 0
        a=pp.coefs(di*jl+(1-di:0),:);
        for ii=pp.order:-1:2
            for i=2:ii
                a(:,i)=x*a(:,i-1)+a(:,i);
            end
        end
        pp.coefs(di*jl+(1-di:0),:)=a;
    end

    jr=pp.pieces;index=find(pp.breaks(2:jr+1)>=xr);
    if (~isempty(index))
        jr=index(1);
    end

    di = pp.dim;
    ppcut = ppmak([xl pp.breaks(jl+1:jr) xr], ...
                            pp.coefs(di*(jl-1)+(1:di*(jr-jl+1)),:),di);
end

function pppce = pppce(pp,j)
    if (0<j)&&(j<=pp.pieces)
    	di = pp.dim;
        pppce = ppmak([pp.breaks(j) pp.breaks(j+1)], ...
            pp.coefs(di*j+(1-di:0),:),di);
    else
        error(message('SPLINES:PPBRK:wrongpieceno', sprintf( '%g', j )));
    end
end

function pp = ppmak(breaks,coefs,d)
    if nargin==0
        breaks=input('Give the (l+1)-vector of breaks  >');
        coefs=input('Give the (d by (k*l)) matrix of local pol. coefficients  >');
    end

    sizec = size(coefs);

    if iscell(breaks)
        if nargin>2
            if prod(sizec)~=prod(d)
                error(message('SPLINES:PPMAK:coefsdontmatchsize'))
            end
            sizec = d;
        end
        [breaks,coefs,sizeval,l,k] = iMultivariateSpline(breaks,coefs,sizec);
    else
        if nargin<3
            [coefs,sizeval,l,k] = iUnivariateWithoutD(breaks,coefs,sizec);
        else
            [coefs,sizeval,l,k] = iUnivariateWithD(breaks,coefs,sizec,d);
        end
        breaks = reshape(breaks,1,l+1);
    end
    pp.form = 'pp';
    pp.breaks = breaks;
    pp.coefs = coefs;
    pp.pieces = l;
    pp.order = k;
    pp.dim = sizeval;
end

function [breaks,coefs,sizeval,l,k] = iMultivariateSpline(breaks,coefs,sizec)
    m = length(breaks);
    if length(sizec)<m
        error(message('SPLINES:PPMAK:coefslengthlessthanbreakslength'));
    end
    if length(sizec)==m
        sizec = [1 sizec];
    end
    
    sizeval = sizec(1:end-m);
    sizec = [prod(sizeval), sizec(end-m+(1:m))];
    coefs = reshape(coefs, sizec);

    for i=m:-1:1
        l(i) = length(breaks{i})-1;
        k(i) = fix(sizec(i+1)/l(i));
        if k(i)<=0||k(i)*l(i)~=sizec(i+1)
            error(message('SPLINES:PPMAK:piecesdontmatchcoefsforvar', sprintf( '%g', l( i ) ), sprintf( '%g', sizec( i + 1 ) ), sprintf( '%g', i )))
        end
        breaks{i} = reshape(breaks{i},1,l(i)+1);
    end
end

function [coefs,sizeval,l,k] = iUnivariateWithoutD(breaks,coefs,sizec)
    if isempty(coefs)
        error(message('SPLINES:PPMAK:emptycoefs'))
    end
    sizeval = sizec(1:end-1);
    d = prod(sizeval);
    kl = sizec(end);
    l=length(breaks)-1;
    k=fix(kl/l);
    if (k<=0)||(k*l~=kl)
    	error(message('SPLINES:PPMAK:piecesdontmatchcoefs', sprintf( '%g', l ), sprintf( '%g', kl )));
    elseif any(diff(breaks)<0)
    	error(message('SPLINES:PPMAK:decreasingbreaks'))
    elseif breaks(1)==breaks(l+1)
        error(message('SPLINES:PPMAK:extremebreakssame'))
    else
        coefs = reshape(permute(reshape(coefs,[d,k,l]),[1,3,2]),d*l,k);
    end
end

function [coefs,sizeval,l,k] = iUnivariateWithD(breaks,coefs,sizec,d)
    if length(d)==1
        k = sizec(end);
        l = prod(sizec(1:end-1))/d;
    else
        if prod(d)~=prod(sizec)
            error(message('SPLINES:PPMAK:coefssizemismatch', num2str( sizec ), num2str( d )));
        end
        k = d(end);
        l = d(end-1);
        d(end-1:end) = [];
        if isempty(d),
            d = 1;
        end
        coefs = reshape(coefs, prod(d)*l,k);
    end
    if l+1~=length(breaks)
        error(message ('SPLINES:PPMAK:coefsdontmatchbreaks', ...
            sprintf('%g',l), sprintf('%g',length(breaks)-1)));
    end
    sizeval = d;
end

function v = ppual(pp,x,left)
    if ~isstruct(pp)
        pp = fn2fm(pp);
    end

    if iscell(pp.breaks)
        [breaks,coefs,l,k,d] = ppbrk(pp);
        m = length(breaks);
        sizec = [d,l.*k];

        if nargin>2
            if ~iscell(left)
                temp = left;
                left = cell(1,m);
                [left{:}] = deal(temp);
            end
        else
            left = cell(1,m);
        end

        if iscell(x)
            if length(x)~=m
                error(message('SPLINES:PPUAL:needgrid', num2str( m )))
            end

            v = coefs;
            sizev = sizec;
            nsizev = zeros(1,m);
            for i=m:-1:1
                nsizev(i) = length(x{i}(:));
                dd = prod(sizev(1:m));
                v = reshape(ppual1(...
                    ppmak(breaks{i},reshape(v,dd*l(i),k(i)),dd), x{i}, left{i} ),...
                    [sizev(1:m),nsizev(i)]);
                sizev(m+1) = nsizev(i);
                if m>1
                    v = permute(v,[1,m+1,2:m]);
                    sizev(2:m+1) = sizev([m+1,2:m]);
                end
            end
            
            if d>1
                v = reshape(v,[d,nsizev]);
            else
                v = reshape(v,nsizev);
            end
        else
            [mx,n] = size(x);
            if mx~=m, error(message('SPLINES:PPUAL:wrongx', num2str( m ))), end

            ix = zeros(m,n);
            for i=1:m
                [ox,iindex] = sort(x(i,:));
                ix(i,iindex) = get_index(breaks{i}(2:end-1),ox,left{i});
            end

            temp = l(1)*(0:k(1)-1)';
            
            for i=2:m
                lt = length(temp(:,1));
                temp = [repmat(temp,k(i),1), ...
                	reshape(repmat(l(i)*(0:k(i)-1),lt,1),k(i)*lt,1)];
            end
            
            lt = length(temp(:,1));
            temp=[reshape(repmat((0:d-1).',1,lt),d*lt,1) temp(repmat(1:lt,d,1),:)];
            temp = num2cell(1+temp,1);
            offset = repmat(reshape(sub2ind(sizec,temp{:}),d*prod(k),1),1,n);

            temp = num2cell([ones(n,1) ix.'],1);
            base = repmat(sub2ind(sizec,temp{:}).',d*prod(k),1)-1;
            v = reshape(coefs(base+offset),[d,k,n]);
            
            for i=m:-1:1
                s = reshape(x(i,:) - breaks{i}(ix(i,:)),[1,1,n]);
                otherk = d*prod(k(1:i-1));
                v = reshape(v,[otherk,k(i),n]);
                for j=2:k(i)
                    v(:,1,:) = v(:,1,:).*repmat(s,[otherk,1,1])+v(:,j,:);
                end
                v(:,2:k(i),:) = [];
            end
            v = reshape(v,d,n);
        end
    else
        if nargin<3, left = []; end
        v = ppual1(pp,x,left);
    end
end

function v = ppual1(pp,x,left)
    [mx,nx] = size(x); lx = mx*nx; xs = reshape(x,1,lx);

    [breaks,c,l,k,d] = ppbrk(pp);
    if lx==0
        v = zeros(d,0);
        return
    end

    [index,NaNx] = get_index(breaks(2:end-1),xs,left);
    index(NaNx) = 1;

    xs = xs-breaks(index);
    if d>1
       xs = reshape(repmat(xs,d,1),1,d*lx);
       index = reshape(repmat(1+d*index,d,1)+repmat((-d:-1).',1,lx), d*lx, 1 );
    end

    v = c(index,1).';

    for i=2:k
       v = xs.*v + c(index,i).';
    end

    if ~isempty(NaNx) && k==1 && l>1
        v = reshape(v,d,lx);
        v(:,NaNx) = NaN;
    end
    v = reshape(v,d*mx,nx);
end

function [index,NaNx] = get_index(mesh,sites,left)
    if isempty(left)||left(1)~='l'
    	[~, index] = histc(sites,[-inf,mesh,inf]);
    	NaNx = find(index==0); index = min(index,numel(mesh)+1);
    else
    	[~, index] = histc(-sites,[-inf,-fliplr(mesh),inf]);
    	NaNx = find(index==0); index = max(numel(mesh)+2-index,1);
    end
end