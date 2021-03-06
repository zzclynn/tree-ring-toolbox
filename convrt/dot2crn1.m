% dot2crn1.m   convert malcolm cleaveland's weird format latewood files to crn files
%
% Cleaveland sent me tsm files with a different chron in each column.  But with dots for
% missing data.  He also sent a site info file, which I used in building the .crns

dir1='c:\projs\ai3\prwcleav\'; % input directory with latewood or earlywood
% files as culled from pmail. Output also goes here

kmen3=menu('Choose one',...
   'Width',...
   'Density');
switch kmen3;
case 1; % width 
   type='Width';
case 2; % density
   type='Density';
otherwise;
end;


kmen1=menu('Choose one',...
   'Total ring width',...
   'Latewood width',...
   'Earlywood width');
switch kmen1;
case 1; % total ringwidth
   width='Total';
case 2; % latewood sidth
   width='Late';
case 3; % early
   width='Early';
otherwise;
end;


kmen2=menu('Choose one',...
   'Standard chronology',...
   'Residual chronology',...
   'ARSTAN chronology');
switch kmen2;
case 1; % standard
   ctype='Standard';
   defnm1='????clea.dat';
case 2; % residual
   ctype='Residual';
   defnm1='res*.txt';
case 3; % ARSTAN
   ctype='ARSTAN';
   defnm1='ars*.txt';
otherwise;
end;


%---ASSEMBLE HEADER INFO

[file4,path4]=uigetfile('????inf.txt','Siteinfo file');
pf4=[path4 file4];
fileinf = textread(pf4,'%s','delimiter','\n','whitespace',''); % cell matrix
Si=fileinf;
s=char(Si);
[mSi,nSi]=size(Si);

% 3 and 6-Letter code
Scode3=s(:,39:41);
s1=[type(1) width(1) ctype(1)];
Scode6 = [Scode3 repmat(s1,mSi,1)];

% Site name
Sname=s(:,1:29);

% State or country
Sstate=upper(s(:,32:37));

%Lat and long
latD=s(:,44:45);
latM=s(:,47:48);
lonD=s(:,51:53);
lonM=s(:,55:56);

% Elev (m)
el = s(:,60:63);

% Collector
guy = upper('Cleaveland, Stahle, Therrell');;

% Species
species = 'PSME';

% Standard chrons
[file1,path1]=uigetfile(defnm1,'Input tsm');
pf1=[path1 file1];
%pf1=[dir1 'stda1.txt'];
file = textread(pf1,'%s','delimiter','\n','whitespace',''); % cell matrix
S=strrep(file,'    .','  NaN');
X=str2num(char(S));

% Compute number of files
yrX=X(:,1); X(:,1)=[];
[mX,nX]=size(X);
nfiles=nX; clear nX;
nsize1=mX; clear mX;

% Compute first and end year or each chron
YRon = repmat(NaN,nfiles,1);
YRoff=repmat(NaN,nfiles,1);
for n = 1:nfiles;
   x=X(:,n);
   Lgood = ~isnan(x);
   igood=find(Lgood);
   yron = yrX(min(igood));
   yroff = yrX(max(igood));
   YRon(n)=yron;
   YRoff(n)=yroff;
end;
Son = num2str(YRon,'%4.0f');
Soff=num2str(YRoff,'%4.0f');




% Loop over chronologies
for m=1:nfiles;
   
      
   
   % BUILD 3-LINE HEADER
   h1=blanks(80); h2=blanks(80); h3=blanks(80);
   h1(1:6)=Scode6(m,:);     h2(1:6)=Scode6(m,:);     h3(1:6)=Scode6(m,:);
   h1(7:8)=' 1';        h2(7:8)=' 2';        h3(7:8)=' 3';
   
   % Build output .crn file name
   sixpack=h1(1:6);
   file6=[sixpack '.crn'];
   pf6=[path1 file6];

   
   sname=Sname(m,:);
   len1=length(sname);
   h1(10:(10+len1-1))=sname;
   h1(62:65)=species;
   sstate=Sstate(m,:);
   len1=length(sstate);
   h2(10:(10+len1-1))=sstate;
   elthis=el(m,:);
   h2(41:45)=[elthis 'M'];
   latd=latD(m,:);
   latm=latM(m,:);
   lond=lonD(m,:);
   if strcmp(lond(1),' ');
      lond(1)='0';
   end;
   lonm=lonM(m,:);
   h2(48:49)=latd;
   h2(50:51)=[latm];
   h2(52:55)=['-' lond];
   h2(56:57)=lonm;
   yron=sprintf('%5.0f',YRon(m,:)); 
   yroff=sprintf('%5.0f',YRoff(m,:)); 
   h2(67:71)=yron;
   h2(72:76)=yroff;
   
   len1=length(guy);
   h3(10:(10+len1-1))=guy;
   switch ctype;
   case 'Standard';
      h3(63)='_';
   case 'Residual';
      h3(63)='R';
   case 'ARSTAN';
      h3(63)='A';
   otherwise;
   end;
   
   switch type;
   case 'Width';
       switch width;
       case 'Total';
           h3(62)=' ';
       case 'Late';
           h3(62)='L';
       case 'Early'; 
           h3(62)='E';
       otherwise;
           error('in switch type');
       end;
       
   otherwise;
       error('Only width coded for so far');
   end;
      
   id=sixpack';

   % Get the series and year vector
   x=X(:,m);
   L=~isnan(x);
   yr=yrX(L);
   x=x(L);
   
   % Dummy sample size
   n=repmat(0,length(x),1);
   
   % Open file for writing
   pf2=[dir1 'stda1.crn'];
   fid=fopen(pf6,'w');
   
   
   % Header Lines
   fprintf(fid,'%s\n',h1);
   fprintf(fid,'%s\n',h2);
   fprintf(fid,'%s\n',h3);
   
   % Convert all the NaN's in X into 9990's
   lmx=isnan(x);
   if any(lmx);
      x(lmx)=9.990;
   end;
   
   bcount=1;
   while lmx(bcount)==1,
      bcount=bcount+1;
   end
   bcount=bcount-1;
   rcount=1;
   k=length(lmx);
   while lmx(k)==1,
      k=k-1;
      rcount=rcount+1;
   end
   rcount=rcount-1;
   
   % Append 9990's in the beginning of the data if necessary
   if rem(yr(1),10)~=0,
      fapnd=ones(rem(yr(1),10),1)*9990;
   end
   bfcount=bcount+length(fapnd);
   
   % Append 9990's at the end of the data if necessary
   if rem(yr(length(yr)),10)~=0,
      rapnd=ones(9-rem(yr(length(yr)),10),1)*9990;
   end
   rfcount=rcount+length(rapnd);

   % Append 9990's in the beginning of the data if necessary
   brem=rem(bfcount,10);
   if brem~=0,
      bwhln=fix(bfcount/10);
      if bwhln==0,
         fprintf(fid,'%s',id);
         fprintf(fid,'%4d',yr(1));
         for i=1:length(fapnd),
            fprintf(fid,'%4d%3d',fapnd(i),0);
         end
      else
         fprintf(fid,'%s',id);
         fprintf(fid,'%4d',yr(bwhln*10+brem-length(fapnd)+1));
         for i=1:brem,
            fprintf(fid,'%4d%3d',9990,0);
         end
      end
   end
   
   % Main loop : write the actual data x
   for i=bcount+1:length(x)-rcount,
      if rem(yr(i),10)==0,
         fprintf(fid,'\n%s%4d',id,yr(i));
      end
      fprintf(fid,'%4d%3d',round(x(i)*1),n(i));
   end
   
   % Append 9990's at the end of the data if necessary
   rrem=rem(rfcount,10);
   if rrem~=0,
      for i=1:rrem,
         fprintf(fid,'%4d%3d',9990,0);
      end
   end

   
   
   
   fclose (fid);
   
end;



disp('here');

   
   