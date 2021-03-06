function skelcrn
% skelcrn:  skeleton plot from .crn file or .rw file
% skelcrn;
% Last revised 7-7-99
%
% Draws a skeleton plot from chronology indices in a .crn "ITRDB-format"
% file; a measured ring-width series in a .rw file; or a two-column time series
% matrix with the year in column 1.    
% The plot is scaled in the x-direction to 100 yr per 20 cm to match
% with manually drawn plots.  The 10% of largest values (index or ring width)
% indices in each century are marked by small squares on the skeleton plot.  
% For .crn input, a plot of sample size (number of cores, usually) against 
% time is also produced.<P>
%
% The skeleton plot can optionally be made using a "centered" approach (comparing a ring
% with the flanking rings), or a "backwards" approach (comparing the ring with just the 
% preceding ring).
%
% A user-prompted scaling factor allows for stretching or shrinking the x axis
% so that the output of your particular printer exactly matches the scale of manual
% skeleton plots.
%
%*** IN
%
% No input arguments.
% User is prompted for three things:
% 1) type of input (.crn file or .rw file)
% 2) centered or backwards approach to building the plot
% 3) scaling factor (see notes)
%
%*** OUT
%
% No output arguments
%
% Plots are shown in figure windows on the screen.  Do NOT worry about being able
% to see the whole plotted series on the screen.  To get a figure window to print
% out properly, follow these instructons exactly:
% -click on the figure window (to make it the current figure window)
% -Click the following sequence on the figure windows "File" menu:
%  File-PrintPreview-PageSetup-Center-OK-Print-OK
%
%*** REFERENCES 
% 
% Stokes, M.A., and Smiley, T.L., 1996, An Introduction to Tree-ring Dating: 
% The University of Arizona Press, Tucson, p. 73 pp.
%
%*** UW FUNCTIONS CALLED
%
% rwchng.m  -- transforms ring width
% rwread3.m -- reads a .rw file
% crn2vec2 -- reads a .crn file and converts data to column vector
%
%*** TOOLBOXES
%
% statistics
% signal processing
% 
%
%*** NOTES
%
% Plotting scale is 5 years per cm.  Plots are made in landscape orientation
% with 20 cm x axis, giving 100 yr per x axis.  
%
% The lengths of lines in the plot built by skelcrn.m are proportional to the
% tree-ring index or ring width  transformed as follows:
% 1. 9-wt hamming low-pass filter the series using matlab function filtfilt 
% 2. compute departures of indices or ring width from the low-pass-filtered series 
% 3. compute first difference of departures to accentuate year-to-year changes
% 4. compute ratio of first diff of departures to low-pass series, to scale importance
%
% As described above, the algorithm looks only backwards.  For a centered approach, the
% same procedure is followed, but reversing the input time series first. This step gives
% a "forward-looking" comparison, comparing each ring with the following ring. The
% average of the ratios from the backwards and forwards approach is the ratio for the
% centered approach.
%
% Lines are plotted for negative ration only, emphasizing narrow rings. For additional
% diagnostic information, very wide rings are also flagged, by squares plotted at the 
% top of the skeleton-plot lines.  The 10% of widest rings in each century or partial
% century are flagged in this way on each plot.
%
% If your x-axis is a bit too long or too short, compare with a sheet of graph paper
% and work out an appropriate scaling factor & run the program again. For example,
% if your 100 years of computer plot corresponds to only 99.5 years on "manual" graph
% paper, shrink the computer plot in the x direction by setting the scaling factor
% to 99.5/100 and run the program again.
%
% Making a "master" skeleton plot from several cores.  One way to do this is by the
% ascii 2-column time series matrix input option.  First you must average the ringwidths
% from the cores into a single time series, or maybe convert the selected ring widtths 
% into a preliminary "master" chronology using ARSTAN or some other program.  

%-- Prompt for type of source time series
ksrc=menu('Choose input source-type',...
   'Index in ITRDB-formatted .crn file',...
   'Ring width in single .rw file','Two-column time series mtx, year as col 1');
if ksrc==1;
   src = 'crn';
elseif ksrc==2;
   src = 'rw';
elseif ksrc==3; 
   src = 'dat';
else;
   error('ksrc must be 1, 2 or 3');
end
clear ksrc;

%-- Prompt for backward vs centered approach
kmen1=menu('Choose method for assessing narrow ring',...
   'Centered',...
   'Backwards');
if kmen1==2;
   meth='b';
   strmeth='backwards-looking';
else;
   meth='c';
   strmeth='centered';
end;
clear kmen1;

%-- Prompt for lines up or lines down
kdir=menu('Choose direction for vertical lines',...
   'downward pointing',...
   'upward pointing');
if kdir==1;
   linedir='down';
   strdir='lines downward';
else;
   linedir='up';
   strdir='lines upward';
end;
clear kdir;


%-- Prompt for scale to shrink or expand plot horizontally
kscale=questdlg('Scale plot in horizontal direction?');
switch kscale;
case 'Yes';
   prompt={'Enter scaling factor:'};
   def={'1.0'};
   tit='Factor for scaling horizontally';
   lineNo=1;
   answer=inputdlg(prompt,tit,lineNo,def);
   xscale=str2num(answer{1});
otherwise;
   xscale=1.0;
end; % switch kscale
clear kscale;

close all;


%-----  Get the .crn file name
if strcmp(src,'crn');
   [file1,path1]=uigetfile('*.crn','Infile with chronology index');
elseif strcmp(src,'rw');
   [file1,path1]=uigetfile('*.rw','Infile with measured ring width series');
elseif strcmp(src,'dat');
   [file1,path1]=uigetfile('*.dat','Infile of 2-col time series matrix');
end;

pf1=[path1 file1]; % merge path and filename

%--- Read the input time series;  
if strcmp(src,'crn');
   [x,s,yr]=crn2vec2(pf1); %x is index, s is sample size, yr is year
elseif strcmp(src,'rw');
   [X,guy,day,pf1]=rwread3(path1,file1); % X has year in col 1, data in col 2
   yr=X(:,1); x=X(:,2);
   clear guy day X;
elseif strcmp(src,'dat');
   eval(['load ' pf1  ' -ascii;']);
   filepref = strtok(file1,'.');
   eval(['x = ' filepref '(:,2);']);
   eval(['yr = ' filepref '(:,1);']);
   clear filepref;
   
end;

% store indices & year for later use
z=x; yrz=yr; 

%--- Compute the scaled ring-width change, backward looking
y=rwchng(x);  
% make year vector for y
yry = yr;
yr(1)=[];  % lose first year in taking first-difference

%-- optionally compute scaled rw change in reverse direction (forward)
if strcmp(meth,'c');
   f = flipud(x);
   yf = rwchng(f);
   yf=flipud(yf);
   numy = length(y);
   numyf = length(yf);
   ymid = (yf(2:numyf) + y(1:(numy-1)))/2;
   y = [yf(1);  ymid;  y(length(y))];
   yr = [(yr(1)-1); yr];
end;


% Mark top 20% of changes toward wider rings
L1 = y>=0;
ybig = y(L1);
cbig=prctile(ybig,80); % cutoff of ration for a "big" change toward wider rings
Lbig = y>cbig;  % mark ratios for big plus change
ybig=y(Lbig);
yrybig = yry(Lbig);

% Make narrow-ring subseries
w =y; 
yrw=yr;
w(w>=0)=0;

% Compute year info
yrgo=min(yrw);
yrsp=max(yrw);
nyr = yrsp-yrgo+1;
stryr=sprintf('%4.0f-%4.0f',yrgo, yrsp); % string for putting year range of lines in title


% Compute beginning year for plot (will be start of a century)
yr1 = 100*floor(yrgo/100)  ;

% Compute number of years to add at start
addgo = yrgo-yr1;

% Compute end year for plot (will be end of a century)
yr2 = 100*ceil(yrsp/100)  ;

% Compute number of years to add at start
addsp = yr2-yrsp;

% Make synthetic start and end data for plots
if addgo>0;
   w1 = zeros(addgo,1);
   yrw1=(yr1:(yrgo-1))';
   w=[w1; w];
   yrw=[yrw1; yrw];
end;
if addsp>0;
   w2=zeros(addsp,1);
   yrw2=((yrsp+1):yr2)';
   w=[w; w2];
   yrw=[yrw; yrw2];
end
nyr = length(yrw);

%--Compute number of x axes needed
naxes=round((nyr-1)/100);

%-- Compute number of pages needed, allowing 4 axes
npages = ceil(naxes/4);


% Compute start and end year-index for each axes pair
igo=yr1:100:(yr2-100);
isp=igo+100;

% Compute y-axis range
dmin=min(y);
if strcmp(linedir,'down');
   yfield=[dmin-abs(dmin/10) 0];
elseif strcmp(linedir,'up');
   yfield=[0 -(dmin-abs(dmin/10))];
end;

% Compute positions of the 4 plots
leftgo=1; %cm from left
upgo=0; % cm from bottom
yinc=4;
xsize=20; % 20 cm per 100 yr
xsize=xscale*xsize;  % scaling factor to allow to stretch or shrink x axis
POS=[leftgo upgo xsize 3;leftgo upgo+yinc xsize 3; leftgo upgo+2*yinc xsize 3; leftgo upgo+3*yinc xsize 3];
fignew=0;
figno=1;

strwide='Squares mark the widest 10% of rings (largest indices) in century';

%-- DO THE PLOTS
for n = 1:naxes;
   if rem(n-1,4)==0; % will want to make a new figure
      if n==1;
         figure(1);
      else;
         figure(1+(n-1)/4);
      end;
      jplot=1;
      set(gcf,'PaperOrientation','Landscape','PaperUnits','centimeters');
   else;
      jplot=jplot+1;
   end;
   
     
   i1=igo(n); i2=isp(n);
   pos=POS(rem(n-1,4)+1,:);
   %axes('Position',pos);
   %set(gca,'Units','centimeters');
   t=(i1:i2)';
   L=yrw>=i1 & yrw<=i2;
   d = w(L);
   axes;
   
   if strcmp(linedir,'down');
      hstem=stem(t,d); 
   elseif strcmp(linedir,'up');
      hstem=stem(t,-d);
   end;
   
   set(hstem(1),'MarkerSize',1); % no big circle at end of line
   set(hstem(2),'LineWidth',2.0); % line width of vertical lines
   hold on;
   
   % Mark widest 10% of rings in each century, or partial century
   L7=yrz>=i1 & yrz<=i2;
   zz=z(L7);
   yrzz=yrz(L7);
   numz1=length(zz);
   if numz1>10; % require at least 10 years in the century
      zcrit=prctile(zz,90); % critical value for 90th percentile
      L8= zz>=zcrit;
      numz2=sum(L8);
      hwide=plot(yrzz(L8),zeros(numz2,1));
      set(hwide,'Marker','square','MarkerSize',6);
   end;
   clear L7 zz yrzz L8 ;
   hold off;
   
   
   % Add title if 4th or last plot -- commented out
   %if n==naxes | jplot==4;
   %   title([file1 ';  Years ' stryr ';  Method = ' strmeth ';  ' strwide]);
   %end;
   strtit=[file1 '('  stryr ')'];
   
   
   % Add patch to indicate first usable year
   if n==1 & yrgo>yr1;
      xptch=[yr1 yr1 yrgo-.5 yrgo-.5 yr1];
      if strcmp(linedir,'down');
         yptch=[yfield(1) 0 0 yfield(1) yfield(1)];
      elseif strcmp(linedir,'up');
         yptch=[0 yfield(2) yfield(2) 0 0];
      end;
      cpatch=[.9 .9 .9];
      patch(xptch,yptch,cpatch);
   end;
   
   
    % Add patch  to indicate last usable year, if last plot
   if n==naxes & yrsp<yr2;
      xptch=[yrsp+.5 yrsp+.5 yr2 yr2 yrsp+.5];
      if strcmp(linedir,'down');
         yptch=[yfield(1) 0 0 yfield(1) yfield(1)];
      elseif strcmp(linedir,'up');
         yptch=[0 yfield(2) yfield(2) 0 0];
      end
      cpatch=[.9 .9 .9];
      patch(xptch,yptch,cpatch);
   end;
   set(gca,'XLim',[i1-.25 i2]); % the -.25 is so that right-aligned line will show at far left
   set(gca,'XTick',[t(1):5:max(t)],'FontSize',7,'YLim',yfield);
   
   %-- if line direction up, want xtick labels along top
   if strcmp(linedir,'up');
      xt=get(gca,'Xtick');
      xtn = length(xt);
      xt=xt'; % col vector
      xtl=get(gca,'XtickLabel');
      yt= repmat(yfield(2),xtn,1);
      set(gca,'XtickLabel',[]);
      text(xt,yt,xtl,'HorizontalAlignment','center',...
         'VerticalAlignment','bottom','FontSize',7);
   end;
   
   %-- Label the plot
   yrange = get(gca,'YLim');
   if strcmp(linedir,'up');
      ydrop = yrange(2)-abs(diff(yrange))/10;
   elseif strcmp(linedir,'down');
      ydrop = yrange(1)+abs(diff(yrange))/10;
   end;
   xstart=get(gca,'XLim');
   xstart=xstart(1)+3;
   text(xstart,ydrop,strtit);
   
   set(gca,'Units','centimeters');
   set(gca,'Position',pos);
   grid;
end;

% Plot of sample size vs time
if strcmp(src,'crn');
   figure(npages+1);
   stairs(yrz,s);
   grid;
   title(['Sample Size vs time for ' file1]);
   xlabel('Year');
   ylabel('Number of cores in chronology');
end;
